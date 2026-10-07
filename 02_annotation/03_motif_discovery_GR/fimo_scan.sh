#!/bin/bash
#SBATCH -A naiss2023-23-109
#SBATCH -J fimo
#SBATCH -p shared
#SBATCH -n 4
#SBATCH -t 01:00:00
#SBATCH -o logs/fimo_%j.out

# ─────────────────────────────────────────────────────────
# FIMO: scan Iric motif against D. melanogaster GRs
# ─────────────────────────────────────────────────────────
# Scans the Iric-derived motif TYTVILVQ against the D. melanogaster
# GR repertoire to assess cross-species conservation.
#
# Software: MEME Suite v5.5.5
# ─────────────────────────────────────────────────────────

module load meme/5.5.5

PROJECT="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks"
MEME_FILE="${PROJECT}/analysis/meme/Iric/meme_run/meme.txt"
TARGET_FASTA="${PROJECT}/data/phylo/GR_sequences/Dmel_GR.fasta"
OUT_DIR="${PROJECT}/analysis/fimo"
mkdir -p "$OUT_DIR" logs

fimo \
    --oc "${OUT_DIR}/Iric_motif_vs_Dmel_GRs" \
    --thresh 0.05 \
    --qv-thresh \
    "$MEME_FILE" \
    "$TARGET_FASTA"

echo "FIMO scan complete. Results in: $OUT_DIR"
