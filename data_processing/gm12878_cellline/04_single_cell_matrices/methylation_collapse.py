import pandas as pd
import numpy as np
import argparse
import os
import sys
import pyranges as pr
import gzip
import psutil
from datetime import datetime, timedelta
from tqdm import tqdm
import time 

def is_gzipped(filepath):
    """Check if a file is gzipped based on its magic numbers"""
    with open(filepath, 'rb') as f:
        return f.read(2) == b'\x1f\x8b'

def read_file(filepath, **kwargs):
    """Generic file reader that handles both gzipped and regular files"""
    open_func = gzip.open if filepath.endswith('.gz') or is_gzipped(filepath) else open
    with open_func(filepath, 'rt') as f:
        return pd.read_csv(f, **kwargs)

def read_chrom_sizes(filepath):
    chromsize = pd.read_csv(filepath, sep='\t', header=None, names=['chr', 'size'])
    chromsize = chromsize[chromsize['chr'].isin([f'chr{i}' for i in range(1, 23)] )]
    return chromsize

def generate_methyldf(chromsize, bin_size):
    """Vectorized version of generate_methyldf"""
    start_time = time.time()
    print("Generating bins...")
    
    # Create all starts and ends at once
    all_data = []
    
    # Calculate number of bins for each chromosome
    n_bins = np.ceil(chromsize['size'] / bin_size).astype(int)
    total_bins = n_bins.sum()
    print(f"Total bins to generate: {total_bins}")
    
    # Generate chromosome-wise data
    for _, row in chromsize.iterrows():
        chr_name = row['chr']
        size = row['size']
        n = int(np.ceil(size / bin_size))
        
        # Generate starts and ends for this chromosome
        starts = np.arange(0, n * bin_size, bin_size)
        ends = np.minimum(starts + bin_size, size)
        
        # Create data for this chromosome
        chr_data = np.column_stack((
            np.full(len(starts), chr_name),
            starts + 1,  # Add 1 to starts
            ends
        ))
        
        all_data.append(chr_data)
    
    # Concatenate all chromosome data
    all_bins = np.vstack(all_data)
    
    # Create DataFrame
    methyldf = pd.DataFrame(all_bins, columns=['chr', 'start', 'end'])
    
    # Convert start and end to integers
    methyldf['start'] = methyldf['start'].astype(int)
    methyldf['end'] = methyldf['end'].astype(int)
    
    print(f"Generated {len(methyldf)} bins in {time.time() - start_time:.2f} seconds")
    return methyldf

def process_gene_bins(gene_bed_path, collapse_method):
    print('Processing gene bins...')
    gr = pr.read_gtf(gene_bed_path)
    df = gr.df
    unique_genes = df[(df['Feature'] == 'gene') & (df['gene_type'] == 'protein_coding')][['Chromosome', 'Start', 'End', 'gene_name', 'Strand']].drop_duplicates(subset='gene_name')
    
    if collapse_method == 'gene_tss':
        unique_genes['Start'] = np.where(unique_genes['Strand'] == '+', unique_genes['Start'] - 2000, unique_genes['End'])
        unique_genes['End'] = np.where(unique_genes['Strand'] == '+', unique_genes['Start'] + 2000, unique_genes['End'] + 2000)
    elif collapse_method == 'gene':
        unique_genes['Start'] = np.where(unique_genes['Strand'] == '+', unique_genes['Start'] - 2000, unique_genes['Start'])
        unique_genes['End'] = np.where(unique_genes['Strand'] == '-', unique_genes['End'] + 2000, unique_genes['End'])
    
    return unique_genes.rename(columns={'Chromosome': 'chr', 'Start': 'start', 'End': 'end'})[['chr', 'start', 'end', 'gene_name']]

def read_binned_regions(filepath):
    """
    Read a pre-made binned regions file (supports both regular and gzipped files).
    Expected format: TSV with no header, 3 or 4 columns (chr, start, end, [gene_name])
    """
    try:
        # Always read without header
        df = read_file(filepath, sep='\t', header=None)
        
        # Validate number of columns
        if df.shape[1] < 3:
            raise ValueError(f"Input bed file must have at least 3 columns, found {df.shape[1]}")
        elif df.shape[1] > 4:
            print(f"Warning: Input bed file has {df.shape[1]} columns, only using first 4 columns")
            df = df.iloc[:, :4]
        
        # Name columns based on number of columns present
        if df.shape[1] == 3:
            df.columns = ['chr', 'start', 'end']
        else:  # 4 columns
            df.columns = ['chr', 'start', 'end', 'gene_name']
        
        # Convert start/end to integers
        df['start'] = df['start'].astype(int)
        df['end'] = df['end'].astype(int)
        
        # Ensure chromosome format consistency
        df['chr'] = df['chr'].astype(str)
        df['chr'] = df['chr'].apply(lambda x: f'chr{x}' if not x.startswith('chr') else x)
        
        # Filter chromosomes
        filtered_df = df[df['chr'].isin([f'chr{i}' for i in range(1, 23)])]
        
        if len(filtered_df) == 0:
            raise ValueError("No valid chromosome regions found after filtering")
            
        return filtered_df
    except Exception as e:
        print(f"Error reading binned regions file: {e}")
        sys.exit(1)

def get_memory_usage():
    """Get current memory usage in MB"""
    process = psutil.Process(os.getpid())
    return process.memory_info().rss / 1024 / 1024

def compute_methylation_levels(methyldf, sample_table):
    sample_df = read_file(sample_table, sep='\t', header=None, names=['cell_name', 'methy_path', 'cov_path'])
    total_cells = len(sample_df)
    
    total_start_time = time.time()
    print(f"\nStarting processing at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Total cells to process: {total_cells}")
    print(f"Initial memory usage: {get_memory_usage():.1f} MB")
    
    # Pre-process methyldf to create a dictionary for faster lookups
    print("Preparing reference data...")
    methyldf_groups = methyldf.groupby('chr')
    
    processed_cells = []  # Store timing info for better estimates
    
    for idx, row in enumerate(sample_df.iterrows(), 1):
        cell_start_time = time.time()
        _, row = row  # Unpack the row
        prefix = row['cell_name']
        
        # Calculate estimated time remaining
        if processed_cells:
            avg_time_per_cell = sum(processed_cells) / len(processed_cells)
            est_remaining_time = avg_time_per_cell * (total_cells - idx)
            est_completion_time = datetime.now() + timedelta(seconds=est_remaining_time)
            
            print(f"\nProcessing {prefix} ({idx}/{total_cells})")
            print(f"Estimated completion time: {est_completion_time.strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"Average time per cell: {avg_time_per_cell:.2f} seconds")
            print(f"Estimated time remaining: {timedelta(seconds=int(est_remaining_time))}")
        else:
            print(f"\nProcessing {prefix} ({idx}/{total_cells})")
        
        try:
            # Read methylation file
            read_start = time.time()
            methy_bed = read_file(row['methy_path'], sep='\t', header=None, skiprows=[0],
                                names=['chr', 'start', 'end', 'methy_count'])
            print(f"  Reading methylation file: {time.time() - read_start:.2f} seconds")
            
            # Read coverage file
            read_start = time.time()
            cov_bed = read_file(row['cov_path'], sep='\t', header=None, skiprows=[0],
                              names=['chr', 'start', 'end', 'cov_count'])
            print(f"  Reading coverage file: {time.time() - read_start:.2f} seconds")
            
            # Merge and filter
            merge_start = time.time()
            bed = pd.merge(methy_bed, cov_bed, on=['chr', 'start', 'end'], how='inner')
            bed = bed[bed['chr'].isin([f'chr{i}' for i in range(1, 23)])]
            bed_groups = bed.groupby('chr')
            print(f"  Merging and filtering: {time.time() - merge_start:.2f} seconds")
            
            # Calculate methylation levels
            calc_start = time.time()
            methyllevel = np.full(len(methyldf), np.nan)
            
            # Process each chromosome
            for chr_name, methyl_group in tqdm(methyldf_groups, 
                                             desc="  Processing chromosomes",
                                             bar_format='{l_bar}{bar}| {n_fmt}/{total_fmt} Chr [{elapsed}<{remaining}]'):
                if chr_name in bed_groups.groups:
                    chr_data = bed_groups.get_group(chr_name)
                    
                    # Create arrays for vectorized operations
                    starts = chr_data['start'].values
                    ends = chr_data['end'].values
                    methy_counts = chr_data['methy_count'].values
                    cov_counts = chr_data['cov_count'].values
                    
                    # Get indices for current chromosome in methyldf
                    chr_indices = methyl_group.index
                    
                    # Process each bin in the chromosome
                    for i, (bin_start, bin_end) in enumerate(zip(methyl_group['start'], methyl_group['end'])):
                        # Vectorized filtering
                        mask = (starts >= bin_start) & (ends <= bin_end)
                        if mask.any():
                            total_methy = np.sum(methy_counts[mask])
                            total_cov = np.sum(cov_counts[mask])
                            if total_cov > 0:
                                methyllevel[chr_indices[i]] = total_methy / total_cov
            
            methyldf[prefix] = methyllevel
            calc_time = time.time() - calc_start
            print(f"  Methylation calculations completed in {calc_time:.2f} seconds")
            
            cell_time = time.time() - cell_start_time
            processed_cells.append(cell_time)
            
            print(f"✓ {prefix} completed in {cell_time:.2f} seconds")
            print(f"  Memory usage: {get_memory_usage():.1f} MB")
            
            # Clean up to manage memory
            del methy_bed, cov_bed, bed, bed_groups
            
        except Exception as e:
            print(f"✗ Error processing {prefix}: {e}")
            methyldf[prefix] = [np.nan] * len(methyldf)
            continue
    
    total_time = time.time() - total_start_time
    print(f"\nAll processing completed in {total_time:.2f} seconds ({total_time/60:.2f} minutes)")
    print(f"Average time per cell: {total_time/len(sample_df):.2f} seconds")
    print(f"Final memory usage: {get_memory_usage():.1f} MB")
    
    return methyldf

import pandas as pd
import numpy as np
import argparse
import os
import sys
import pyranges as pr
import gzip
import psutil
from datetime import datetime, timedelta
from tqdm import tqdm
import time
from multiprocessing import Pool, Manager, cpu_count
from functools import partial

def process_single_cell_bed(args):
    """Process a single cell's methylation data using the new file format"""
    row, methyldf_groups, total_bins, progress_lock, progress_value = args
    cell_start_time = time.time()
    prefix = row['cell_name']
    print('working on '+prefix+' now')
    
    # try:
    # Construct the new file path
    filename = row['file_path']
    
    # Check if file exists
    if not os.path.exists(filename):
        raise FileNotFoundError(f"File not found: {filename}")

    # Read new format BED file
    bed = pd.read_csv(
        filename, sep='\t', header=None, skiprows=[0],
        names=['chr', 'start', 'end', 'name', 'ha', 'direction', 'rate', 'num']
    )
    
    # Filter valid chromosomes
    valid_chroms = [f'chr{i}' for i in range(1, 23)]# + ['chrX', 'chrY']
    bed = bed[bed['chr'].isin(valid_chroms)]
    bed = bed[bed['num'] <= 2]
    bed_groups = bed.groupby('chr')

    # Initialize methylation levels array
    methyllevel = np.full(total_bins, np.nan)
    
    # Process each chromosome
    for chr_name, methyl_group in methyldf_groups:
        if chr_name in bed_groups.groups:
            chr_data = bed_groups.get_group(chr_name)

            # Extract arrays for vectorized processing
            starts = chr_data['start'].values
            ends = chr_data['end'].values
            rates = chr_data['rate'].values / 100  # Convert percentage to fraction
            nums = chr_data['num'].values

            # Get indices for current chromosome in methyldf
            chr_indices = methyl_group.index
            bin_starts = methyl_group['start'].values
            bin_ends = methyl_group['end'].values

            # Process bins using NumPy
            for i, (bin_start, bin_end) in enumerate(zip(bin_starts, bin_ends)):
                mask = (starts >= bin_start) & (ends <= bin_end)
                if mask.any():
                    total_methy = np.sum(np.round(rates[mask] * nums[mask]))
                    total_cov = np.sum(nums[mask])
                    if total_cov > 0:
                        methyllevel[chr_indices[i]] = total_methy / total_cov

    # Update progress
    with progress_lock:
        progress_value.value += 1

    cell_time = time.time() - cell_start_time
    return prefix, methyllevel, cell_time, None

    # except Exception as e:
    #     return prefix, np.full(total_bins, np.nan), 0, str(e)

def process_single_cell(args):
    """Process a single cell's methylation data"""
    row, methyldf_groups, total_bins, progress_lock, progress_value = args
    cell_start_time = time.time()
    prefix = row['cell_name']
    
    try:
        # Read methylation file
        methy_bed = read_file(row['methy_path'], sep='\t', header=None, skiprows=[0],
                            names=['chr', 'start', 'end', 'methy_count'])
        
        # Read coverage file
        cov_bed = read_file(row['cov_path'], sep='\t', header=None, skiprows=[0],
                          names=['chr', 'start', 'end', 'cov_count'])
        
        # Merge and filter
        bed = pd.merge(methy_bed, cov_bed, on=['chr', 'start', 'end'], how='inner')
        bed = bed[bed['chr'].isin([f'chr{i}' for i in range(1, 23)])]
        bed_groups = bed.groupby('chr')
        
        # Initialize methylation levels array
        methyllevel = np.full(total_bins, np.nan)
        
        # Process each chromosome
        for chr_name, methyl_group in methyldf_groups:
            if chr_name in bed_groups.groups:
                chr_data = bed_groups.get_group(chr_name)
                
                # Create arrays for vectorized operations
                starts = chr_data['start'].values
                ends = chr_data['end'].values
                methy_counts = chr_data['methy_count'].values
                cov_counts = chr_data['cov_count'].values
                
                # Get indices for current chromosome in methyldf
                chr_indices = methyl_group.index
                
                # Process each bin in the chromosome
                for i, (bin_start, bin_end) in enumerate(zip(methyl_group['start'], methyl_group['end'])):
                    mask = (starts >= bin_start) & (ends <= bin_end)
                    if mask.any():
                        total_methy = np.sum(methy_counts[mask])
                        total_cov = np.sum(cov_counts[mask])
                        if total_cov > 0:
                            methyllevel[chr_indices[i]] = total_methy / total_cov
        
        # Update progress
        with progress_lock:
            progress_value.value += 1
        
        cell_time = time.time() - cell_start_time
        return prefix, methyllevel, cell_time, None
        
    except Exception as e:
        return prefix, np.full(total_bins, np.nan), 0, str(e)

def compute_methylation_levels_parallel(methyldf, sample_table, n_processes=None, input_format='bed'):
    """Parallel version of compute_methylation_levels"""
    if n_processes is None:
        n_processes = max(1, cpu_count() - 1)  # Leave one CPU free
    
    if input_format == 'bed':
        sample_df = read_file(sample_table, sep='\t', header=None, names=['cell_name', 'file_path'])
    elif input_format == 'bigwig':
        sample_df = read_file(sample_table, sep='\t', header=None, names=['cell_name', 'methy_path', 'cov_path'])
    total_cells = len(sample_df)
    
    total_start_time = time.time()
    print(f"\nStarting processing at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Total cells to process: {total_cells}")
    print(f"Using {n_processes} processes")
    print(f"Initial memory usage: {get_memory_usage():.1f} MB")
    
    # Pre-process methyldf
    print("Preparing reference data...")
    methyldf = methyldf.reset_index(drop=True, inplace=False)
    methyldf_groups = list(methyldf.groupby('chr'))
    total_bins = len(methyldf)
    
    # Create shared progress counter and lock
    manager = Manager()
    progress_value = manager.Value('i', 0)
    progress_lock = manager.Lock()
    
    # Prepare arguments for parallel processing
    process_args = [(row, methyldf_groups, total_bins, progress_lock, progress_value) 
                   for _, row in sample_df.iterrows()]
    
    # Create progress bar
    pbar = tqdm(total=total_cells, desc="Processing cells")
    last_progress = 0
    
    # Determine which function to use based on input format
    if input_format == "bigwig":
        process_function = process_single_cell
    elif input_format == "bed":
        process_function = process_single_cell_bed
    else:
        raise ValueError("Unsupported input format. Use 'bigwig' or 'bed'.")


    # Process cells in parallel
    results = []
    with Pool(processes=n_processes) as pool:
        for result in pool.imap_unordered(process_function, process_args):
            prefix, methyllevel, cell_time, error = result
            
            if error:
                print(f"✗ Error processing {prefix}: {error}")
            else:
                print('\n')
                #print(f"✓ {prefix} completed in {cell_time:.2f} seconds")
            
            results.append((prefix, methyllevel))
            
            # Update progress bar
            current_progress = progress_value.value
            pbar.update(current_progress - last_progress)
            last_progress = current_progress
    
    pbar.close()
    
    # Add results to methyldf
    for prefix, methyllevel in results:
        methyldf[prefix] = methyllevel
    
    total_time = time.time() - total_start_time
    print(f"\nAll processing completed in {total_time:.2f} seconds ({total_time/60:.2f} minutes)")
    print(f"Average time per cell: {total_time/total_cells:.2f} seconds")
    print(f"Final memory usage: {get_memory_usage():.1f} MB")
    
    return methyldf

def main():
    parser = argparse.ArgumentParser(description='Compute Methylation Levels')
    parser.add_argument('--sample_table', required=True, help='Path to table of cell names and file paths')
    parser.add_argument('--output_file', required=True, help='Output file path for the resulting CSV file')
    parser.add_argument('--collapse_method', choices=['bin', 'gene', 'gene_body', 'gene_tss', 'custom'], default='bin',
                        help='Method for collapsing methylation regions')
    parser.add_argument('--bin_size', type=int, default=1000000, help='Bin size for methylation calculation (used with --collapse_method bin)')
    parser.add_argument('--chrom_size_filepath', help='File path to chromosome size file (required for bin method)')
    parser.add_argument('--gene_bed', help='Path to gene BED file (required for gene-based binning)')
    parser.add_argument('--custom_bins', help='Path to custom binned regions file (required for custom method)')
    parser.add_argument('--n_processes', type=int, default=None, help='Number of parallel processes to use')
    parser.add_argument('--input_format', choices=['bed','bigwig'], default='bed', help='Input file format')
    
    args = parser.parse_args()
    #os.makedirs(os.path.dirname(args.output_file), exist_ok=True)
    
    # if os.path.exists(args.output_file):
    #     sys.exit()
    
    if args.collapse_method == 'bin':
        if not args.chrom_size_filepath:
            raise ValueError("Bin method requires --chrom_size_filepath argument.")
        chromsize = read_chrom_sizes(args.chrom_size_filepath)
        methyldf = generate_methyldf(chromsize, args.bin_size)
    elif args.collapse_method in ['gene', 'gene_body', 'gene_tss']:
        if not args.gene_bed:
            raise ValueError("Gene-based binning requires --gene_bed argument.")
        methyldf = process_gene_bins(args.gene_bed, args.collapse_method)
    elif args.collapse_method == 'custom':
        if not args.custom_bins:
            raise ValueError("Custom method requires --custom_bins argument.")
        methyldf = read_binned_regions(args.custom_bins)
    
    methyldf = compute_methylation_levels_parallel(methyldf, args.sample_table, args.n_processes, args.input_format)
    
    # Save with compression if filename ends with .gz
    if args.output_file.endswith('.gz'):
        methyldf.to_csv(args.output_file, sep='\t', compression='gzip', index = False)
    else:
        methyldf.to_csv(args.output_file, sep='\t', index = False)
if __name__ == '__main__':
    main()