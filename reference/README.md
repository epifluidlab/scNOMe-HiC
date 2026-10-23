# reference/

Genome references and annotation you download yourself. **Empty in the
repository** — only this folder structure and this README are tracked.

Set `reference_root` in `../paths.yaml` if you keep these elsewhere (a shared
institutional reference directory, say). The default is this folder.

## hg38/ — human

| File | Where from |
|---|---|
| `GCA_000001405.15_GRCh38_no_alt_analysis_set.fa` (+ `.fai`, `.chrom.sizes`) | NCBI / the UCSC analysis set |
| `GCA_000001405.15_GRCh38_no_alt_analysis_set.fa_DpnII.txt` | generated once from the FASTA — DpnII (`GATC`) cut sites, one per line, used by the aligner |
| `Homo_sapiens_assembly38.dbsnp138.vcf` (+ index) | GATK resource bundle — Bis-SNP masks called SNPs with it |
| `autosomes.chrom.sizes` | the `.chrom.sizes` above, autosomes only |
| `genome_bins_5kb.bed`, `genome_bins_250kb.bed` | fixed-width bins over the autosomes, for GCH normalisation |

## mm10/ — mouse

The same set for mm10: FASTA + index + chrom sizes, DpnII sites, a dbSNP VCF,
and the two genome-bin BEDs. Needed for the mouse cortex dataset and for the
mouse benchmark arms (snm3C-seq, snmC-seq2, scWGBS).

## hg38_bismark/ and mm10_bismark/ — converted indexes

The C->T and G->A converted genomes that `bhmem` aligns against. Build each with
Bismark's `genome_preparation` over the corresponding FASTA, then index with BWA:

```bash
bismark_genome_preparation --bowtie2 reference/hg38_bismark/
# then BWA-index the two converted FASTAs Bismark writes
```

## Barnyard (Figure S4 only)

The species-mixing dataset aligns to a combined `hg38_mm10` reference. Build it by
concatenating the two FASTAs with the mouse contigs prefixed `mm10_`, then
generating its own DpnII site list.
