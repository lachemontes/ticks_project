#!/bin/bash
#SBATCH -A naiss2023-23-109
#SBATCH -J kraken2
#SBATCH -p shared
#SBATCH -n 16
#SBATCH --mem=64G
#SBATCH -t 08:00:00
#SBATCH -o logs/kraken2_%j.out
#SBATCH -e logs/kraken2_%j.err

# ─────────────────────────────────────────────────────────
# Taxonomic classification of trimmed reads with Kraken2
# ─────────────────────────────────────────────────────────
# Screens trimmed reads against the standard Kraken2 database
# to assess potential contamination (bacteria, viruses, etc.)
#
# Software:
#   Kraken2 v2.1.3  (verify with: kraken2 --version)
# ─────────────────────────────────────────────────────────

module load kraken2/2.1.3

TRIMMED_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/trimmed_libs"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/kraken2_output"
DB="/cfs/klemming/projects/supr/common/kraken2_db/standard"

mkdir -p "$OUT_DIR" logs

cd "$TRIMMED_DIR"

for R1 in *_val_1.fq.gz; do
    R2="${R1/_val_1/_val_2}"
    SAMPLE="${R1%_val_1.fq.gz}"
    
    echo "Classifying: $SAMPLE"
    
    kraken2 \
        --db "$DB" \
        --paired \
        --gzip-compressed \
        --threads 16 \
        --use-names \
        --report "$OUT_DIR/${SAMPLE}.kraken2.report" \
        --output "$OUT_DIR/${SAMPLE}.kraken2.out" \
        "$R1" "$R2"
done

echo "Taxonomic classification complete. Reports in: $OUT_DIR"
