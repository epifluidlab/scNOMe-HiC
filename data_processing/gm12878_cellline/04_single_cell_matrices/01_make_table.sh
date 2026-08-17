BASE="/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/07.bistools_snakemake/methylation"
OUT="sample_table_hcg.tsv"

find "$BASE" -type f -name "*.HCG.6plus2.bed" | while read -r file; do
    cell=$(basename "$(dirname "$file")")
    echo -e "${cell}\t${file}"
done | sort > "$OUT"

echo "Wrote: $OUT"
