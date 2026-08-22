from pathlib import Path
QC = Path('/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake/QC')

# all 7 control / titration wells (blank, 10c, 100c, 1000c) — never real single cells
CONTROLS = [
    "MY_2_S185.ATCACG",   # 100c
    "MY_8_S191.CGATGT",   # blank
    "MY_11_S194.TGACCA",  # blank
    "MY_14_S197.ATCACG",  # 10c
    "MY_21_S204.GCCAAT",  # 1000c
    "MY_28_S210.ACTTGA",  # blank
    "MY_30_S212.CTTGTA",  # blank
]
(QC / 'control_wells.txt').write_text('\n'.join(CONTROLS) + '\n')
print(f"wrote QC/control_wells.txt ({len(CONTROLS)} controls)")

ctrl = set(CONTROLS)
p = QC / 'meningioma_passed.txt'
cells = [l.strip() for l in p.read_text().splitlines() if l.strip()]
removed = [c for c in cells if c in ctrl]
kept = [c for c in cells if c not in ctrl]
# backup original (with controls) once
bk = QC / 'meningioma_passed_with_controls.txt'
if not bk.exists():
    bk.write_text('\n'.join(cells) + '\n')
p.write_text('\n'.join(kept) + '\n')
print(f"meningioma_passed.txt: {len(cells)} -> {len(kept)}  (removed {len(removed)}: {removed})")
