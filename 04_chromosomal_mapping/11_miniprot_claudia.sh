#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p main
#SBATCH -c 16
#SBATCH --mem=80GB
#SBATCH -t 12:00:00
#SBATCH -J miniprot
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/miniprot/logs/miniprot_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/miniprot/logs/miniprot_%A.err

# ============================================================
# miniprot: align receptor proteins to the I. ricinus chromosome-
# level genome (GCA_964199275.3). Reusable — just change the
# variables in the CONFIG block for each receptor set.
# ============================================================

set -eu

# ============================================================
# CONFIG — EDIT THESE FOR EACH RECEPTOR SET
# ============================================================

# Protein query (the receptor set to align)
QUERY="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/phylo/IR_iGluR_final_80.fasta"

# Chromosome-level genome
GENOME="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/genomes/Iric_chromosome_ncbi_dataset/data/GCA_964199275.3/GCA_964199275.3_IXRI_v3_genomic.fna"

# Output directory
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/miniprot"

# Short label for this run (used in output filenames), e.g. GR, IR, PPK, TRP
LABEL="IR_80"

# Path to the miniprot binary (edit if it's elsewhere or on PATH)
MINIPROT="miniprot"

# Threads (match -c above)
THREADS=16

# ============================================================
# Setup
# ============================================================
mkdir -p "${OUT_DIR}/logs"

module load bioinfo-tools 2>/dev/null || true
module load samtools 2>/dev/null || true

echo "================================================"
echo "Job started : $(date)"
echo "Node        : $(hostname)"
echo "Query       : ${QUERY}"
echo "Genome      : ${GENOME}"
echo "Label       : ${LABEL}"
echo "================================================"

# ============================================================
# STEP 1 — Chromosome lengths (index genome once)
# Produces a .fai and a two-column lengths table.
# ============================================================
LENGTHS="${OUT_DIR}/chromosome_lengths_Iric.txt"

if [ ! -f "${GENOME}.fai" ]; then
    echo ""
    echo "[1/2] Indexing genome (one-time)..."
    samtools faidx "${GENOME}"
else
    echo ""
    echo "[1/2] Genome index already exists — skipping."
fi

# Write chromosome name + length table (only if not present)
if [ ! -f "${LENGTHS}" ]; then
    cut -f1,2 "${GENOME}.fai" > "${LENGTHS}"
    echo "      Chromosome lengths written: ${LENGTHS}"
else
    echo "      Chromosome lengths already exist: ${LENGTHS}"
fi

# ============================================================
# STEP 2 — Run miniprot (protein -> genome alignment, GFF output)
# ============================================================
OUT_GFF="${OUT_DIR}/${LABEL}_miniprot.gff"

echo ""
echo "[2/2] Running miniprot..."
echo "      Output: ${OUT_GFF}"
echo "      Start:  $(date)"

if [ ! -f "${QUERY}" ]; then
    echo "  [ERROR] Query file not found: ${QUERY}"
    exit 1
fi

"${MINIPROT}" \
    -t "${THREADS}" \
    "${GENOME}" \
    "${QUERY}" \
    --gff-only > "${OUT_GFF}"

echo "      Done:   $(date)"

# ============================================================
# Summary
# ============================================================
echo ""
echo "================================================"
echo "miniprot finished: $(date)"
N_ALN=$(grep -c $'\tmRNA\t' "${OUT_GFF}" 2>/dev/null || echo 0)
echo "Alignments (mRNA lines) in output: ${N_ALN}"
echo "Output GFF: ${OUT_GFF}"
echo "================================================"
