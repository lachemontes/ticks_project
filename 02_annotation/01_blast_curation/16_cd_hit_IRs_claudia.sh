#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p main
#SBATCH -c 8
#SBATCH --mem=20GB
#SBATCH -J cdhit_IR
#SBATCH -o logs/cdhit_IR_%j.out
#SBATCH -e logs/cdhit_IR_%j.err

# ── Paths ──────────────────────────────────────────────────────────────────────
INPUT=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/phylo/IR_danda.fasta
OUTDIR=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/phylo
PREFIX=${OUTDIR}/IR_iGlur

# ── Setup ──────────────────────────────────────────────────────────────────────
mkdir -p ${OUTDIR}
mkdir -p logs

# ── Step 1: Remove gaps/spaces from sequences ──────────────────────────────────
echo "[$(date)] Step 1: Removing gaps with seqkit..."
seqkit seq -g ${INPUT} > ${PREFIX}_clean.fasta

# ── Step 2: CD-HIT (100% identity + filter <200 aa) ───────────────────────────
echo "[$(date)] Step 2: Running CD-HIT..."
cd-hit \
    -i  ${PREFIX}_clean.fasta \
    -o  ${PREFIX}_cdhit100.fasta \
    -c  1.0 \
    -n  5 \
    -l  199 \
    -M  14000 \
    -T  8

echo "[$(date)] Done!"

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo "--- Sequence counts ---"
echo -n "Input:   "; grep -c '^>' ${INPUT}
echo -n "Cleaned: "; grep -c '^>' ${PREFIX}_clean.fasta
echo -n "Output:  "; grep -c '^>' ${PREFIX}_cdhit100.fasta
