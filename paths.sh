#!/bin/bash
# Source this to get the repository's path settings as environment variables:
#
#   source "$(dirname "${BASH_SOURCE[0]}")/paths.sh"      # from a script at the repo root
#   source "$SCNOMEHIC_REPO/paths.sh"
#
# Exports: SCNOMEHIC_REPO DATA_ROOT REFERENCE_ROOT SOFTWARE_ROOT WORK_ROOT
#          TMP_ROOT CONDA_SH
#
# Resolution order for the settings file: $SCNOMEHIC_PATHS, then paths.local.yaml,
# then paths.yaml.

_sp_self="${BASH_SOURCE[0]:-$0}"
SCNOMEHIC_REPO="$(cd "$(dirname "$_sp_self")" && pwd)"
export SCNOMEHIC_REPO

_sp_file=""
if [ -n "${SCNOMEHIC_PATHS:-}" ]; then
    _sp_file="$SCNOMEHIC_PATHS"
elif [ -f "$SCNOMEHIC_REPO/paths.local.yaml" ]; then
    _sp_file="$SCNOMEHIC_REPO/paths.local.yaml"
elif [ -f "$SCNOMEHIC_REPO/paths.yaml" ]; then
    _sp_file="$SCNOMEHIC_REPO/paths.yaml"
else
    echo "paths.sh: no paths.yaml found in $SCNOMEHIC_REPO" >&2
    return 1 2>/dev/null || exit 1
fi

# key: value  (strips inline comments and surrounding quotes)
_sp_get () {
    sed -n "s/^[[:space:]]*$1:[[:space:]]*//p" "$_sp_file" \
      | head -n 1 \
      | sed -e 's/[[:space:]]*#.*$//' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/" \
            -e 's/[[:space:]]*$//'
}

# absolute -> as-is; ~ -> $HOME; otherwise relative to the repo root
_sp_abs () {
    case "$1" in
        "")   echo "" ;;
        /*)   echo "$1" ;;
        "~"*) echo "${HOME}${1#\~}" ;;
        *)    echo "$SCNOMEHIC_REPO/$1" ;;
    esac
}

DATA_ROOT="$(_sp_abs "$(_sp_get data_root)")"
REFERENCE_ROOT="$(_sp_abs "$(_sp_get reference_root)")"
SOFTWARE_ROOT="$(_sp_abs "$(_sp_get software_root)")"
WORK_ROOT="$(_sp_abs "$(_sp_get work_root)")"
TMP_ROOT="$(_sp_abs "$(_sp_get tmp_root)")"
CONDA_SH="$(_sp_abs "$(_sp_get conda_sh)")"
export DATA_ROOT REFERENCE_ROOT SOFTWARE_ROOT WORK_ROOT TMP_ROOT CONDA_SH

unset _sp_self _sp_file
