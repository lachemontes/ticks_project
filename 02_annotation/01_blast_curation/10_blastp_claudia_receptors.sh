#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p main
#SBATCH -c 8
#SBATCH -t 24:00:00
#SBATCH -J blastp_Iricinus
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blastp_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blastp_%A.err

# ============================================================
# BLASTP: PPK & TRP receptors vs. I. ricinus annotated proteins
# ============================================================

# --- Paths ---
RECEPTOR_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/receptors"
PROTEINS="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/blast_resorces/iricinus_ass1.0_annotOGS1.3_proteins.fa"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast"
DB_DIR="${OUT_DIR}/db_blastp"

# --- Queries to run ---
QUERIES=(
    "PPK_forBlast.fasta"
    "TRP_forBlast.fasta"
)

# --- Parameters ---
THREADS=8
EVALUE="1e-5"
OUTFMT=6
MAX_SEQS=5

# ============================================================
# Setup
# ============================================================
mkdir -p "${DB_DIR}"

module load bioinfo-tools
module load blast/2.9.0+

echo "================================================"
echo "Job started:  $(date)"
echo "Node:         $(hostname)"
echo "Program:      blastp (protein vs protein)"
echo "================================================"

# ============================================================
# Step 1 — Build protein database (only once)
# ============================================================
DB_PATH="${DB_DIR}/Iricinus_proteins_DB"

if [ ! -f "${DB_PATH}.phr" ]; then
    echo ""
    echo "[1/2] Building protein BLAST database..."
    makeblastdb \
        -in      "${PROTEINS}" \
        -title   "Iricinus_annot_proteins" \
        -dbtype  prot \
        -out     "${DB_PATH}" \
        -parse_seqids
    echo "      Database built: ${DB_PATH}"
else
    echo "[1/2] Protein database already exists — skipping makeblastdb."
fi

# ============================================================
# Step 2 — Run blastp for each receptor file
# ============================================================
echo ""
echo "[2/2] Running blastp queries..."

for QUERY_FILE in "${QUERIES[@]}"; do

    QUERY_PATH="${RECEPTOR_DIR}/${QUERY_FILE}"
    BASENAME="${QUERY_FILE%.fasta}"
    OUT_FILE="${OUT_DIR}/${BASENAME}_blastp_vs_Iricinus_proteins.txt"
    LOG_FILE="${OUT_DIR}/${BASENAME}_blastp_vs_Iricinus_proteins.log"

    if [ ! -f "${QUERY_PATH}" ]; then
        echo "  [WARN] Query not found, skipping: ${QUERY_PATH}"
        continue
    fi

    echo ""
    echo "  --> Query:   ${QUERY_FILE}"
    echo "      Program: blastp"
    echo "      Output:  ${OUT_FILE}"
    echo "      Start:   $(date)"

    blastp \
        -query           "${QUERY_PATH}" \
        -db              "${DB_PATH}" \
        -num_threads     "${THREADS}" \
        -evalue          "${EVALUE}" \
        -outfmt          "${OUTFMT}" \
        -max_target_seqs "${MAX_SEQS}" \
        -out             "${OUT_FILE}" \
        2> "${LOG_FILE}"

    HITS=$(wc -l < "${OUT_FILE}")
    echo "      Done:    $(date)  |  Hits: ${HITS}"

done

# ============================================================
# Summary
# ============================================================
echo ""
echo "================================================"
echo "All blastp queries finished: $(date)"
echo "Results in: ${OUT_DIR}"
ls -lh "${OUT_DIR}"/*blastp*.txt 2>/dev/null
echo "================================================"
