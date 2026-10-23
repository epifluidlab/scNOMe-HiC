"""Repository path settings, read from paths.yaml.

    import sys; sys.path.insert(0, "<repo root>")
    from paths import REPO, DATA, REFERENCE, SOFTWARE, WORK, TMP

Resolution order for the settings file: $SCNOMEHIC_PATHS, then paths.local.yaml,
then paths.yaml. Relative values resolve against the repository root; a leading
``~`` expands to the home directory.

No dependency on PyYAML -- the file is flat ``key: value`` and is parsed here.
"""
import os

REPO = os.path.dirname(os.path.abspath(__file__))


def _settings_file():
    env = os.environ.get("SCNOMEHIC_PATHS")
    if env:
        return env
    for name in ("paths.local.yaml", "paths.yaml"):
        p = os.path.join(REPO, name)
        if os.path.exists(p):
            return p
    raise FileNotFoundError(f"no paths.yaml in {REPO}")


def _load():
    out = {}
    with open(_settings_file()) as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if not line or ":" not in line:
                continue
            k, v = line.split(":", 1)
            out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def _abs(v):
    if not v:
        return ""
    if os.path.isabs(v):
        return v
    if v.startswith("~"):
        return os.path.expanduser(v)
    return os.path.join(REPO, v)


_s = _load()

DATA      = _abs(_s.get("data_root", "data"))
REFERENCE = _abs(_s.get("reference_root", "reference"))
SOFTWARE  = _abs(_s.get("software_root", "software"))
WORK      = _abs(_s.get("work_root", "work"))
TMP       = _abs(_s.get("tmp_root", "work/tmp"))
CONDA_SH  = _abs(_s.get("conda_sh", ""))
# <conda>/etc/profile.d/conda.sh -> <conda>/envs
CONDA_ENVS = _abs(_s.get("conda_envs", ""))
if not CONDA_ENVS and CONDA_SH:
    CONDA_ENVS = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(CONDA_SH))), "envs")

__all__ = ["REPO", "DATA", "REFERENCE", "SOFTWARE", "WORK", "TMP", "CONDA_SH", "CONDA_ENVS"]
