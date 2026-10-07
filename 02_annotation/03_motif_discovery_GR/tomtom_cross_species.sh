#!/bin/bash
#SBATCH -A naiss2023-23-109
#SBATCH -J tomtom
#SBATCH -p shared
#SBATCH -n 4
#SBATCH -t 01:00:00
#SBATCH -o logs/tomtom_%j.out

# ─────────────────────────────────────────────────────────
# TOMTOM: cross-species motif similarity
# ─────────────────────────────────────────────────────────
# Compares MEME motifs between species to assess conservation.
#
# Software: MEME Suite v5.5.5
# ─────────────────────────────────────────────────────────

module load meme/5.5.5

PROJECT="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks"
MEME_DIR="${PROJECT}/analysis/meme"
OUT_DIR="${PROJECT}/analysis/tomtom"
mkdir -p "$OUT_DIR" logs

# Iric vs Abru
tomtom -oc "${OUT_DIR}/Iric_vs_Abru" \
    "${MEME_DIR}/Iric/meme_run/meme.txt" \
    "${MEME_DIR}/Abru/meme_run/meme.txt"

# Iric vs Dmel
tomtom -oc "${OUT_DIR}/Iric_vs_Dmel" \
    "${MEME_DIR}/Iric/meme_run/meme.txt" \
    "${MEME_DIR}/Dmel/meme_run/meme.txt"

echo "TOMTOM analysis complete. Reports in: $OUT_DIR"
