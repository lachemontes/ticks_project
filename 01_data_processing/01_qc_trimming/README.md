# 01.01 — Read QC and trimming

## ⚠️ Note on provenance

**The original SLURM submission scripts for this step were lost.** The two
scripts in this folder were **reconstructed** from the lab notebook, the MultiQC
reports and the Trim Galore log files that survived in the project directory.
They reproduce the pipeline and the parameters that were actually used, but they
are not byte-for-byte the files that produced the published output.

Everything downstream of this step (`02_taxonomic_classification/` onwards) uses
the original, unmodified scripts.

The only parameter that matters for reproducibility is that **Trim Galore was run
with default thresholds** (Phred 20, minimum length 20 bp, auto-detected Illumina
adapters) — no custom cutoffs were applied.

## Purpose

Assess raw read quality and remove sequencing adapters and low-quality bases
before assembly.

## Scripts

| Script | Tool | Description |
|--------|------|-------------|
| `fastqc.sh` | FastQC + MultiQC | Per-library QC on raw FASTQ, aggregated into one HTML report |
| `trimgalore.sh` | Trim Galore (Cutadapt) | Paired-end adapter and quality trimming |

## Input

- `data/raw/*.fastq.gz` — 16 paired-end libraries
  (`<sample>_R1_001.fastq.gz` / `<sample>_R2_001.fastq.gz`)

## Output

| File | Produced by |
|------|-------------|
| `data/qc_raw/*_fastqc.html`, `*_fastqc.zip` | `fastqc.sh` |
| `data/qc_raw/multiqc_report_raw.html` | `fastqc.sh` |
| `data/trimmed_libs/<sample>_R1_001_val_1.fq.gz` | `trimgalore.sh` |
| `data/trimmed_libs/<sample>_R2_001_val_2.fq.gz` | `trimgalore.sh` |
| `data/trimmed_libs/*_trimming_report.txt` | `trimgalore.sh` |

The `_val_1` / `_val_2` suffixes are Trim Galore's defaults and are assumed by
every downstream script (HISAT2, Kraken2, kallisto) — do not rename them.

## Software versions

| Tool | Version |
|------|---------|
| FastQC | 0.11.9 |
| MultiQC | 1.12 |
| Trim Galore | 0.6.1 |
| Cutadapt | 2.1 |

## How to run

```bash
# Edit RAW_DIR / TRIMMED_DIR at the top of each script first.
sbatch fastqc.sh       # ~1 h,  8 cores
sbatch trimgalore.sh   # ~8 h,  8 cores (4 Cutadapt cores)

# Optional: re-run FastQC on the trimmed reads to confirm adapter removal
```

Both scripts write SLURM logs to `logs/` relative to the submission directory,
so create it first: `mkdir -p logs`.
