#!/bin/bash
#SBATCH -A naiss2023-23-109
#SBATCH -J fastqc_multiqc
#SBATCH -p shared
#SBATCH -n 8
#SBATCH -t 04:00:00
#SBATCH -o logs/fastqc_%j.out
#SBATCH -e logs/fastqc_%j.err

# ─────────────────────────────────────────────────────────
# FastQC + MultiQC quality control
# ─────────────────────────────────────────────────────────
# Runs FastQC on all raw FASTQ files and aggregates reports with MultiQC
#
# Software versions:
#   FastQC v0.11.9
#   MultiQC v1.12
# ─────────────────────────────────────────────────────────

module load fastqc/0.11.9
module load multiqc/1.12

# Directories
RAW_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/raw"
QC_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/qc_raw"

mkdir -p "$QC_DIR" logs

# Run FastQC on all FASTQ files in parallel
cd "$RAW_DIR"
fastqc *.fastq.gz -o "$QC_DIR" --threads 8

# Aggregate reports with MultiQC
cd "$QC_DIR"
multiqc . -o "$QC_DIR" --filename multiqc_report_raw.html

echo "QC analysis complete. See $QC_DIR/multiqc_report_raw.html"
