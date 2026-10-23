#!/bin/bash
# Render a dataset's config template into the work tree, substituting the roots
# from ../paths.yaml, and print the path of the rendered file.
#
#   CONFIG=$(bash data_processing/render_config.sh gm12878_cellline config.main_run)
#
# Snakemake reads a plain YAML file and does not expand variables, so the configs
# in each 00_config/ are templates carrying ${DATA_ROOT}, ${REFERENCE_ROOT},
# ${SOFTWARE_ROOT} and ${WORK_ROOT}. This renders one into
# ${WORK_ROOT}/<dataset>/config/<name>.yaml.
#
# Only those four names are substituted -- anything else that looks like a shell
# variable in the template (a $PATH inside a comment, say) is left alone.

set -euo pipefail

# Two forms:
#   render_config.sh <dataset> [config-name]   a dataset's 00_config/<name>.template.yaml
#   render_config.sh <template-path> <out-dir> any template, rendered into <out-dir>
arg1="${1:?usage: render_config.sh <dataset> [config-name]  |  <template-path> <out-dir>}"

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
source "${here}/../paths.sh"

if [ -f "$arg1" ]; then
    template="$arg1"
    outdir="${2:?usage: render_config.sh <template-path> <out-dir>}"
    out="${outdir}/$(basename "${template%.template.yaml}").yaml"
else
    dataset="$arg1"
    name="${2:-config}"
    template="${here}/${dataset}/00_config/${name}.template.yaml"
    outdir="${WORK_ROOT}/${dataset}/config"
    out="${outdir}/${name}.yaml"
fi

[ -f "$template" ] || { echo "render_config.sh: no template at $template" >&2; exit 1; }
mkdir -p "$outdir"

envsubst '${DATA_ROOT} ${REFERENCE_ROOT} ${SOFTWARE_ROOT} ${WORK_ROOT} ${TMP_ROOT}' \
    < "$template" > "$out"

if grep -q '\${' "$out"; then
    echo "render_config.sh: unsubstituted variable left in $out:" >&2
    grep -n '\${' "$out" >&2
    exit 1
fi

echo "$out"
