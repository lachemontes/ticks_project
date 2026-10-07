#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -J tomtom
#SBATCH -p shared
#SBATCH -n 4
#SBATCH -t 01:00:00
#SBATCH -o logs/tomtom_%j.out
#SBATCH -e logs/tomtom_%j.err

# ─────────────────────────────────────────────────────────────────────────────
# TOMTOM — cross-species motif-to-motif similarity (all three pairs)
# ─────────────────────────────────────────────────────────────────────────────
# Asks whether the motif MEME found independently in each species is the SAME
# motif. Complements fimo_scan.sh, which asks which individual sequences carry it.
#
# ⚠️  REPORT p-VALUES, NOT q-VALUES. The target databases hold only 10-15 motifs
#     each, so TOMTOM cannot estimate pi_0 and its FDR correction is unreliable.
#     The p-values depend only on the alignment statistics and are usable.
#     -evalue switches the output away from the q-value default.
#
# Software: MEME Suite 5.5.5
# ─────────────────────────────────────────────────────────────────────────────

set -eu

module load bioinfo-tools 2>/dev/null || true
module load meme/5.5.5    2>/dev/null || true

MEME_DIR="meme_output"
OUT_DIR="tomtom_output"
mkdir -p logs "${OUT_DIR}"

# QUERY|TARGET|LABEL
PAIRS=(
    "Iric|Abru|Iric_vs_Abru"
    "Iric|Dmel|Iric_vs_Dmel"
    "Abru|Dmel|Abru_vs_Dmel"
)

for PAIR in "${PAIRS[@]}"; do
    IFS='|' read -r Q T LABEL <<< "${PAIR}"
    QF="${MEME_DIR}/${Q}_maxw12/meme.txt"
    TF="${MEME_DIR}/${T}_maxw12/meme.txt"

    echo ""
    echo "--- ${LABEL} ---"
    [ ! -f "${QF}" ] && echo "  [ERROR] missing ${QF}" && continue
    [ ! -f "${TF}" ] && echo "  [ERROR] missing ${TF}" && continue

    tomtom \
        -evalue \
        -thresh      10 \
        -min-overlap 5 \
        -dist        pearson \
        -oc          "${OUT_DIR}/${LABEL}" \
        "${QF}" \
        "${TF}"

    echo "  -> ${OUT_DIR}/${LABEL}/tomtom.tsv"
done

echo ""
echo "================================================"
echo "Expected p-values:"
echo "  Iric vs Abru : 9.4e-08   (offset 0, overlap 8/8)"
echo "  Iric vs Dmel : 2.0e-05"
echo "  Abru vs Dmel : 5.6e-04"
echo ""
echo "Read the p-value column. Ignore q-values — see the note at the top."
echo "================================================"
