#!/bin/bash
#SBATCH -A naiss2023-23-109
#SBATCH -J trimgalore
#SBATCH -p shared
#SBATCH -n 8
#SBATCH -t 12:00:00
#SBATCH -o logs/trimgalore_%j.out
#SBATCH -e logs/trimgalore_%j.err

# ─────────────────────────────────────────────────────────
# Adapter and quality trimming with Trim Galore
# ─────────────────────────────────────────────────────────
# Removes Illumina adapters and low-quality bases from paired-end reads.
#
# Software:
#   Trim Galore v0.6.1 (wraps Cutadapt v2.1)
# ─────────────────────────────────────────────────────────

module load trim_galore/0.6.1
module load cutadapt/2.1

RAW_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/raw"
TRIMMED_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/trimmed_libs"

mkdir -p "$TRIMMED_DIR" logs

cd "$RAW_DIR"

# Run Trim Galore on each pair
for R1 in *_R1_001.fastq.gz; do
    R2="${R1/_R1_/_R2_}"
    SAMPLE="${R1%_R1_001.fastq.gz}"
    
    echo "Processing: $SAMPLE"
    
    trim_galore \
        --paired \
        --cores 4 \
        --output_dir "$TRIMMED_DIR" \
        "$R1" "$R2"
done

echo "Trimming complete. Trimmed reads in: $TRIMMED_DIR"
