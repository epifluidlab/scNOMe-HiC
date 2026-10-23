# reference/

Genome references and annotation you download yourself. **Empty in the
repository** — only this folder structure and this README are tracked.

Set `reference_root` in `../paths.yaml` if you keep these elsewhere (a shared
institutional reference directory, say). The default is this folder.

## What the configs ask for, exactly

These are the filenames the rendered configs look up. Keep the names; only the
`reference_root` prefix is yours to choose.

### hg38/ — human (GM12878, mixture, meningioma)

| File | Where from |
|---|---|
| `GCA_000001405.15_GRCh38_no_alt_analysis_set` (`.fa`, `.fa.fai`, `.chrom.sizes`) | the NCBI/UCSC no-alt analysis set |
| `GCA_000001405.15_GRCh38_no_alt_analysis_set.fa_DpnII.txt` | generated once from the FASTA — DpnII (`GATC`) cut sites |
| `GCA_000001405.15_GRCh38_no_alt_analysis_set.DpnII.span_region.bedgraph` | the same cut sites as spans, for `bhmem -enzymeList` |
| `Homo_sapiens_assembly38.dbsnp138.vcf` (+ index) | GATK resource bundle — Bis-SNP masks called SNPs with it |
| `hg38.autosomes.5kb_interval.no_dark_regions.bed` | 5 kb autosomal bins with dark regions removed, for GCH normalisation |
| `genome_bins_5kb.bed`, `genome_bins_250kb.bed` | fixed-width autosomal bins |
| `autosomes.chrom.sizes` | the `.chrom.sizes` above, autosomes only |

### mm10/ — mouse (cortex)

| File | Where from |
|---|---|
| `mm10` (`.fa`, `.fa.fai`, `.chrom.sizes`) | the mm10 assembly |
| `4DNFI3HVC1SE.txt` | DpnII restriction sites, from 4DN |
| `dpnII.span_region.bedgraph` | the same cut sites as spans |
| `mm10.dbsnp.vcf` | mouse dbSNP, for Bis-SNP |
| `mm10.autosome.5kb.bed.gz` | 5 kb autosomal bins |

### hg38_mm10/ — combined (species mixing, Figure S4 only)

| File | How |
|---|---|
| `hg38_mm10` (`.fa`, `.fa.fai`) | the two FASTAs concatenated, mouse contigs prefixed `mm10_` |
| `hg38_mm10.fa_DpnII.txt` | DpnII sites over the combined FASTA |
| `hg38_mm10.DpnII.span_region.bedgraph` | **built for you** by `data_processing/barnyard_mixing/01_pipeline/00_setup_workdir.sh` from the hg38 and mm10 bedgraphs above |

### hg38_bismark/ and mm10_bismark/ — converted indexes

The C->T and G->A converted genomes that `bhmem` aligns against. Build each with
Bismark's `genome_preparation` over the corresponding FASTA, then index with BWA:

```bash
bismark_genome_preparation --bowtie2 reference/hg38_bismark/
# then BWA-index the two converted FASTAs Bismark writes
```

### hg38_bowtie1/ — barcode whitelist (Droplet Hi-C benchmark arm only)

`737K-cratac-v1_rc` — the 10x scATAC barcode whitelist, reverse-complemented and
built as a **bowtie v1** index. Only `data_processing/benchmark/droplethic/` uses
it, and only to assign reads to barcodes.
