# scNOMe-HiC

Code accompanying:

> **Joint single-cell profiling of DNA methylation, chromatin accessibility and 3D
> genome architecture reveals pervasive epigenetic concordance at long-range
> chromatin contacts**
>
> Hailu Fu<sup>1,2,\*</sup>, Jiayan Yoshii Ma<sup>1,\*</sup>,
> Mark Youngblood<sup>3,\*</sup>, Zhengyue Li<sup>1</sup>, Eric Tong<sup>1</sup>,
> Alice Yan<sup>4</sup>, Feng Yue<sup>1,2,#</sup>, Li Wang<sup>1,2,#</sup>,
> Yaping Liu<sup>1,2,5,#</sup>
>
> <sup>1</sup> Department of Biochemistry and Molecular Genetics, Feinberg School of Medicine, Northwestern University, Chicago, IL, USA
> <sup>2</sup> Robert H. Lurie Comprehensive Cancer Center of Northwestern University, Chicago, IL, USA
> <sup>3</sup> Department of Neurological Surgery, Feinberg School of Medicine, Northwestern University, Chicago, IL, USA
> <sup>4</sup> Hinsdale Central High School, Hinsdale, IL, USA
> <sup>5</sup> The Ken & Ruth Davee Department of Neurology, Feinberg School of Medicine, Northwestern University, Chicago, IL, USA
>
> <sup>\*</sup> These authors contributed equally.
> <sup>#</sup> Corresponding authors: yue@northwestern.edu (F.Y.),
> li.wang1@northwestern.edu (L.W.), lyping1986@gmail.com (Y.L.)

<!-- FILL: journal and DOI once accepted -->

scNOMe-HiC measures endogenous CpG methylation, exogenous GpC methyltransferase
accessibility and 3D chromatin contacts in the same single nucleus, so both
epigenetic marks can be read at the two ends of an individual chromatin contact.

## Layout

```
paths.yaml                Where data, references, tools and outputs live -- edit this first
data/                     Sequencing reads you download from GEO        (you fill)
reference/                Genomes, dbSNP, restriction sites, bins       (you fill)
software/                 Bis-tools, bisulfiteHic, Picard, juicer_tools (you install)
work/                     Everything the pipeline generates             (created as you run)
env/                      Conda / R environment definitions
data_processing/          Per-dataset processing: raw reads -> analysis-ready matrices
  mouse_cortex/             mouse cortex scNOMe-HiC (Fig. 3, S6)
  gm12878_cellline/         GM12878 cell line (Fig. 1, S3, S5)
  mixture_cellline/         GM12878 / IMR90 mixture (Fig. 2)
  meningioma/               primary meningioma (Fig. 4, S8)
  barnyard_mixing/          human/mouse species mixing (S4)
  bulk_scNOMeHiC/           bulk NOMe-HiC GM12878 (Fig. 1)
  bulk_others/              published bulk datasets used as ground truth (Fig. 2)
  benchmark/                six published single-cell methods (Fig. 1, S1)
  published_singlecell/     published single-cell assays for the S2 comparison
main_figures/             fig1/ … fig4/
supplementary_figures/    figS1/ … figS8/
```

Each folder carries a `README.md` (what the analysis does, the run order) and a
`FILES.md` (what every file in that folder is).

This is a **code-only** repository — no sequencing data, alignments or intermediate
matrices are tracked. `data/`, `reference/`, `software/` and `work/` ship as empty
folders with READMEs explaining what belongs in each.

## Setup

Three things you supply, one the code creates.

1. **Edit `paths.yaml`.** It is the only file you must change. The defaults point at
   the placeholder folders in this repository, so if you fill those in there is
   nothing to edit at all. To keep your own layout out of git, copy it to
   `paths.local.yaml` and edit that instead — it takes precedence and is ignored.

   ```yaml
   data_root:      data          # reads downloaded from GEO
   reference_root: reference     # genomes, dbSNP, restriction sites, genome bins
   software_root:  software      # Bis-tools, bisulfiteHic, Picard, juicer_tools
   work_root:      work          # everything generated
   tmp_root:       work/tmp      # large short-lived intermediates; use fast scratch if you have it
   conda_sh:       ""            # your conda's etc/profile.d/conda.sh
   ```

2. **Download the reads** into `data/` — see [`data/README.md`](data/README.md) for the
   per-dataset folders and the filename pattern the workflow expects.

3. **Download the references** into `reference/` and **install the tools** into
   `software/` — see [`reference/README.md`](reference/README.md) and
   [`software/README.md`](software/README.md) for the exact file list and where each
   one comes from.

Then run the steps in each dataset's `README.md` order. Every step writes into its
own subtree of `work/` and the next step reads it back from there, so nothing has to
be moved by hand. See [`work/README.md`](work/README.md) for which step fills which
folder and which figure consumes it.

Scripts and notebooks read these settings through `paths.sh`, `paths.py` or `paths.R`
at the repository root, whichever matches their language.

> **A note on the notebooks' saved output.** Each notebook ships with the output of
> the run that produced the published figure, and that output still prints the
> absolute paths of the machine it ran on. Only the *code* was rewritten to use
> `paths.yaml`; the saved output was deliberately left alone, because it is the
> record of that run and editing it would misrepresent what happened. Re-run a
> notebook and its output will show your paths instead.

## The processing pipeline

The per-cell Snakemake workflow (demux → trim → align → BAM processing → QC →
Bis-SNP methylation calling → per-bin tables → contact matrices) is a separate
tool and is **not duplicated here**:

<https://github.com/epifluidlab/sc_NOMeHiC_pipeline> — commit `a0456b9`

Each dataset folder carries the config that parameterises it plus the scripts that
invoke it. One exception: `data_processing/bulk_scNOMeHiC/` carries its own
alignment and methylation-calling scripts, because that library's protocol required
aligning **without** `-pbat`, which the shared pipeline hardcodes.

## The cross-method benchmark

The Figure 1 and Figure S1 violins compare per-cell yield against six published
single-cell methods. That processing is in `data_processing/benchmark/`, copied
from its own repository:

<https://github.com/yoshihiko1218/snomehic_benchmark> — commit `236719d`

The scNOMe-HiC side of the comparison is in
`data_processing/gm12878_cellline/06_benchmark_qc/`, and the notebook that draws
the violins is `main_figures/fig1/fig1_benchmark_violins.ipynb`.

## Running it

See **[RUNNING.md](RUNNING.md)** for prerequisites, the config keys you must change,
and the two entry points: raw multiplexed FASTQ (default) or GEO-downloaded reads
(already demultiplexed).

## Data availability

The scNOMe-HiC datasets generated in this study — human GM12878 and IMR-90 cell
lines, frozen mouse cortex, and primary human meningiomas — are deposited in the
Gene Expression Omnibus under accession **GSE346089**.

| What | Where |
|---|---|
| Processed data, all four datasets | GEO **GSE346089** |
| Raw sequencing reads | SRA <!-- FILL: SRA accession --> |
| Raw reads, primary human meningiomas | <!-- FILL: controlled-access repository and accession --> |

GEO carries **per-cell** FASTQs, so they are already demultiplexed — use
`start_from: "demultiplexed"` and see [Entry point B](RUNNING.md#4-entry-point-b--reads-from-geo-already-demultiplexed)
for the filename pattern the workflow expects.

Published datasets used for benchmarking and comparison are listed with their own
accessions in `data_processing/benchmark/` and
`data_processing/published_singlecell/`, and in Supplementary Table 2.

## Environment

See `env/` for the conda environment files and recorded R session info.

## Citing this work

See [`CITATION.cff`](CITATION.cff). Please cite the paper above; once it is
accepted the journal reference and DOI will be added here and to that file.

## Licence

<!-- FILL: licence. Nothing is granted until this is chosen -- see CONTRIBUTING
     note in the repository history, or ask the corresponding authors. -->

## Contact

Questions about the code: open an issue on this repository. Questions about the
study: the corresponding authors listed above.
