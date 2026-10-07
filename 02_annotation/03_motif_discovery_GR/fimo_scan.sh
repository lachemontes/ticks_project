#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -J fimo
#SBATCH -p shared
#SBATCH -n 4
#SBATCH -t 01:00:00
#SBATCH -o logs/fimo_%j.out
#SBATCH -e logs/fimo_%j.err

# ─────────────────────────────────────────────────────────────────────────────
# FIMO — scan the I. ricinus motif against the D. melanogaster GR repertoire
# ─────────────────────────────────────────────────────────────────────────────
# TOMTOM establishes that the motifs correspond; FIMO localises the tick motif to
# individual Dmel sequences, with per-sequence significance.
#
# Unlike TOMTOM here, FIMO's q-values ARE reliable: pi_0 is estimated from 10,000+
# scanned p-values (one per position x sequence), so the FDR correction is well
# calibrated. --qv-thresh is what makes --thresh apply to the q-value.
#
# Closes with a literal grep as an independent sanity check on the FIMO result.
#
# Software: MEME Suite 5.5.5, GNU grep 3.7
# ─────────────────────────────────────────────────────────────────────────────

set -eu

module load bioinfo-tools 2>/dev/null || true
module load meme/5.5.5    2>/dev/null || true

MEME_FILE="meme_output/Iric_maxw12/meme.txt"
TARGET_FASTA="Dmel_GR.fasta"
OUT_DIR="fimo_output"
mkdir -p logs "${OUT_DIR}"

[ ! -f "${MEME_FILE}"    ] && echo "[ERROR] missing ${MEME_FILE} — run meme_motif_discovery.sh first" && exit 1
[ ! -f "${TARGET_FASTA}" ] && echo "[ERROR] missing ${TARGET_FASTA}" && exit 1

# ─────────────────────────────────────────────────────────────────────────────
# FIMO scan at q < 0.05
# ─────────────────────────────────────────────────────────────────────────────
echo "[1/2] FIMO: Iric motif vs D. melanogaster GRs (q < 0.05)..."

fimo \
    --oc                "${OUT_DIR}/Iric_motif_vs_Dmel_GRs" \
    --thresh            0.05 \
    --qv-thresh \
    --max-stored-scores 100000 \
    "${MEME_FILE}" \
    "${TARGET_FASTA}"

HITS=$(awk -F'\t' 'NR>1 && $1 !~ /^#/ && NF>5 {print $3}' \
       "${OUT_DIR}/Iric_motif_vs_Dmel_GRs/fimo.tsv" 2>/dev/null | sort -u | wc -l)
TOTAL=$(grep -c '>' "${TARGET_FASTA}")
echo "      sequences with a significant match: ${HITS} / ${TOTAL}  (expected 40 / 68)"

# ─────────────────────────────────────────────────────────────────────────────
# Literal pattern check — independent of the PWM model
# ─────────────────────────────────────────────────────────────────────────────
# TY + exactly five hydrophobic residues + terminal Q.
# A model-free confirmation that the motif is really present in the Dmel sequences
# rather than an artefact of a tick-trained PWM.
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "[2/2] Literal grep sanity check..."

N_PATTERN=$(grep -c -P 'TY[ILVFAM]{5}Q' "${TARGET_FASTA}" || true)
echo "      TY[ILVFAM]{5}Q          : ${N_PATTERN} sequences  (expected 13)"

N_EXACT=$(grep -c 'TYMVILVQ' "${TARGET_FASTA}" || true)
echo "      TYMVILVQ (closest exact): ${N_EXACT} sequences  (expected 2)"
grep -B1 'TYMVILVQ' "${TARGET_FASTA}" | grep '>' | sed 's/^/        /' || true

echo ""
echo "================================================"
echo "Results in: ${OUT_DIR}/Iric_motif_vs_Dmel_GRs/"
echo "TYMVILVQ differs from the tick consensus TYTVILVQ at one"
echo "conservative position (T -> M)."
echo "================================================"
