#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -J meme_gr
#SBATCH -p shared
#SBATCH -n 8
#SBATCH -t 02:00:00
#SBATCH -o logs/meme_%j.out
#SBATCH -e logs/meme_%j.err

# ─────────────────────────────────────────────────────────────────────────────
# MEME motif discovery in gustatory receptors — I. ricinus, A. bruennichi, D. mel
# ─────────────────────────────────────────────────────────────────────────────
# Three steps:
#   1. CD-HIT at 90% identity — I. RICINUS ONLY (see note below)
#   2. 1-mer shuffled negative control, fixed seed
#   3. MEME with -objfun de, at two widths: maxw 12 (primary) and maxw 50
#
# Full rationale for every parameter: ANALYSIS.md in this directory.
#
# Software: CD-HIT 4.8.1, MEME Suite 5.5.5
# ─────────────────────────────────────────────────────────────────────────────

set -eu

module load bioinfo-tools 2>/dev/null || true
module load meme/5.5.5    2>/dev/null || true
module load cd-hit/4.8.1  2>/dev/null || true

# ── Input FASTAs (protein) ───────────────────────────────────────────────────
IN_DIR="${IN_DIR:-.}"
THREADS=8
SEED=42

mkdir -p logs meme_output

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — CD-HIT, I. ricinus only
# ─────────────────────────────────────────────────────────────────────────────
# I. ricinus GRs include recent tandem duplicates; without this reduction MEME
# recovers a motif driven by a single expanded clade. The A. bruennichi and
# D. melanogaster sets are already non-redundant and pass through UNCHANGED —
# reducing them further would delete biologically real paralogues.
# ─────────────────────────────────────────────────────────────────────────────
echo "[1/3] CD-HIT on I. ricinus (71 -> expected 65 sequences)..."

cd-hit \
    -i "${IN_DIR}/Iric_GR.fasta" \
    -o Iric_GR_nr90.fasta \
    -c 0.90 \
    -n 5 \
    -M 0 \
    -T "${THREADS}" \
    -d 0

echo "      in : $(grep -c '>' ${IN_DIR}/Iric_GR.fasta)"
echo "      out: $(grep -c '>' Iric_GR_nr90.fasta)"

# Abru and Dmel used as-is
cp "${IN_DIR}/Abru_GR.fasta" Abru_GR.fasta
cp "${IN_DIR}/Dmel_GR.fasta" Dmel_GR.fasta

# Each entry is the FASTA basename actually fed to MEME
INPUTS=(Iric_GR_nr90 Abru_GR Dmel_GR)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — Shuffled negative control
# ─────────────────────────────────────────────────────────────────────────────
# -kmer 1 preserves amino-acid composition and length distribution exactly, so a
# hit cannot be a composition artefact. The fixed seed makes the control
# reproducible — an unseeded shuffle makes the E-values unrepeatable.
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "[2/3] Generating shuffled controls (-kmer 1, -seed ${SEED})..."

for fa in "${INPUTS[@]}"; do
    fasta-shuffle-letters \
        -kmer 1 \
        -seed "${SEED}" \
        -dna false \
        "${fa}.fasta" \
        "${fa}_shuffled.fasta"
    echo "      ${fa}_shuffled.fasta"
done

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — MEME at two widths
# ─────────────────────────────────────────────────────────────────────────────
# maxw 12 is the PRIMARY result: it forces MEME to isolate the conserved core
#   and returns it standalone (TYTVILVQ in Iric, TYGVIIYQ in Abru).
# maxw 50 is kept for comparison with the original A. bruennichi analysis, where
#   the motif appears embedded at the end of a 24-residue block.
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "[3/3] MEME motif discovery..."

for MAXW in 12 50; do
    for fa in "${INPUTS[@]}"; do
        SP="${fa%%_*}"                       # Iric_GR_nr90 -> Iric
        OUT="meme_output/${SP}_maxw${MAXW}"

        echo ""
        echo "   --> ${SP}, maxw ${MAXW}  ->  ${OUT}"

        meme "${fa}.fasta" \
            -neg     "${fa}_shuffled.fasta" \
            -objfun  de \
            -protein \
            -mod     zoops \
            -nmotifs 1 \
            -minw    6 \
            -maxw    "${MAXW}" \
            -evt     0.05 \
            -seed    "${SEED}" \
            -p       "${THREADS}" \
            -oc      "${OUT}"
    done
done

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "================================================"
echo "Discovered motifs (maxw 12 — the primary result):"
for SP in Iric Abru Dmel; do
    F="meme_output/${SP}_maxw12/meme.txt"
    [ -f "$F" ] && printf '  %-6s %s\n' "${SP}" "$(grep -m1 '^MOTIF' "$F" || echo 'none reported')"
done
echo ""
echo "Expected: Iric TYTVILVQ (E = 4.2e-20, 46/65 sites)"
echo "          Abru TYGVIIYQ (E = 1.4e-08)"
echo "          Dmel no single significant motif — expected, see ANALYSIS.md"
echo "================================================"
