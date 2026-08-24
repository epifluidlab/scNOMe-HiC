# sci-MET processing — followed strictly from Mulqueen et al. 2018 (nbt.4112)

Source: paper Online Methods + `supp_code/` (their `sciMET_demultiplex.pl`,
`sciMET_barcode_based_rmdup.pl`, barcode lists). Run = SRR6398696 (NextSeq 500,
"sci-MET LAND GM12878").

## THIS sample = GM12878-only, LAND, PAIRED-END (paper's exact spec)
Chemistry: Read1 50 cyc; Index Read1 10+27dark+11 cyc; Index Read2 10 cyc;
Read2 50 cyc. Barcode = 3 indexes: two 10-nt PCR + one 11-nt tagmentation.
Paired-end processing (verbatim from paper):
- bcl2fastq v2.19.0 `--create-fastq-for-index-reads --with-failed-reads`.
- Demux: each index within Hamming ≤2 of reference; reads with all 3 assigned →
  concatenated reference indexes appended to read name as the barcode.
- Trim: TrimGalore! v0.4.0 `-a AGATCGGAAGAGC`, **`--paired --clip_R1 6 --clip_R2 9`**
  (biases at read starts from random priming).
- Align: Bismark `--bowtie2 --unmapped -p` (paired-end), GRCh37 → **we use hg38**.
- Dedup: barcode + chromosome + start position (`sciMET_barcode_based_rmdup.pl`).
- Methylation: Bismark v0.18.2 `coverage2cytosine --merge_CpG` (haploid CpG).
- (Bisulfite conversion >99% via lambda spike-in; cell filter map-eff ≥5%, nonCG ≤5%.)

## ENA deposit issue -> re-extract from .sra  [CONFIRMED structure]
`vdb-dump` spot structure: READ_LEN = **31, 51, 51** (SPOT_LEN 133):
  read1 = 31 bp = INDEX (concatenated 3 barcodes); read2, read3 = 51 bp = the two
  GENOMIC mates. ENA published only read1 (31 bp, `_1`) and read3 (51 bp, `_2`),
  dropping read2 (the other genomic mate) — hence paired alignment was impossible
  and mapping was ~1-12%.
`code/scmet/reextract.sh` = prefetch (.sra, 44 GB) + fasterq-dump `--split-files
--include-technical` → `data/scMET/raw/SRR6398696_{1,2,3}.fastq.gz`:
  _1 = index (31 bp), _2 = genomic mate 1 (51 bp), _3 = genomic mate 2 (51 bp).
Demux: parse the 3 indexes from _1 (Hamming ≤2), append barcode to read name of
_2 and _3 (paired). Then the paired pipeline below.

## Procedure (in order)

1. **Demultiplex** — `sciMET_demultiplex.pl R1:I1 barcodes_nextseq.txt PREFIX`
   - Genomic read = R1; index read = I1 (3 concatenated indexes: PCR-i7 `ix1`,
     methylNext-i5 `ix2`, PCR-i5 `ix3`), split by lengths from the barcode file.
   - Corrects each index to whitelist at **Hamming distance ≤ 2**.
   - Writes the corrected concatenated barcode into the read name: `@<barcode>:<n>#0/1`.
   - NextSeq run → `barcodes_nextseq.txt` (128 indexes).
   - Output: single-end barcoded genomic FASTQ (`PREFIX.1.fq.gz`).
   - (Which of the deposited _1/_2 is genomic vs index is confirmed by read
     inspection before running.)

2. **Trim** — TrimGalore! `-a AGATCGGAAGAGC`
   - Single-end (main sci-MET methylome = Read1 genomic + index reads).
   - (Paired-end species-mix libraries used `--paired --clip_R1 6 --clip_R2 9`;
     not this sample unless inspection shows PE genomic.)

3. **Align** — Bismark `--bowtie2 --unmapped` (single-end; add `-p` if PE)
   - Default **directional** mode (paper specifies no --pbat / --non_directional).
   - Paper genome = **GRCh37 (hg19)**. For comparability with the NOMe-HiC and
     Drop-BS tracks (both hg38) we align to **hg38** instead — the only deliberate
     deviation; everything else follows the paper. (Alternative: hg19 + liftOver.)
   - Using local Bismark 0.24.2 (paper used 0.14.3); same options.

4. **Duplicate removal** — `sciMET_barcode_based_rmdup.pl`
   - **MAPQ ≥ 10**, dedup by **barcode + chromosome + start position**
     (barcode-aware — different cells at the same position are NOT duplicates).
   - Excludes chrM, chrY, and scaffold ('L'/GL) chromosomes.

5. **Methylation** — bismark_methylation_extractor → `coverage2cytosine --merge_CpG`
   - `--merge_CpG` collapses CpG to one strand → matches the NOMe-HiC 6plus2
     (one entry per CpG) convention directly.

## Then (our comparison, same as the other tracks)
6. Build allc → remove GCG (HCG) → bin 250 kb + per-CpG-site →
   add sci-MET as a third track vs NOMe-HiC (and Drop-BS).
