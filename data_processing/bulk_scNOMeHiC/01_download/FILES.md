# 01_download

Downloads the bulk GM12878 NOMe-HiC (bT WGBS readout) FASTQs from SRA.

| File | What it is |
|---|---|
| `accessions.tsv` | Manifest: `<SRR_accession>` `<output_prefix>`, one line per replicate. |
| `download_sra.sh` | SLURM array (`--array=0-2`), one accession per task. `prefetch --max-size u` → `fasterq-dump --split-files` → `pigz`, renames to `<prefix>_{1,2}.fq.gz` and cleans up the `.sra`/temp files. Resume-aware. 8 CPU / 24 G / 24 h. |

## Replicates

| Prefix | SRA run |
|---|---|
| `GM12878_bT_WGBS_rep1` | `SRR16978252` |
| `GM12878_bT_WGBS_rep2` | `SRR16978253` |
| `GM12878_bT_WGBS_rep3` | `SRR16978254` |

FASTQs land in `/scratch/jmj7858/scnomehic/bulk_gm/` (`$DL` in `../00_paths.sh`),
never in this repository.

## Not included

An earlier direct-S3 route (`download_array.sh` + `files.tsv`, `aws s3 cp
--no-sign-request`) failed with HTTP 403 — the source buckets are
requester-pays. The SRA-toolkit route above is what actually ran.
