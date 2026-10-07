#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p main
#SBATCH -c 8
#SBATCH -t 24:00:00
#SBATCH -J blast_Iricinus
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blast_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blast_%A_%a.err

# ============================================================
# BLAST: PPK & TRP receptors vs. Ixodes ricinus genome
# ============================================================

# --- Paths ---
RECEPTOR_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/receptors"
GENOME="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/genomes/I_ricinus/data/GCA/Iricinus_assembly_genomic.fna"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast"
DB_DIR="${OUT_DIR}/db"

# --- Queries to run (add more .fasta files here as needed) ---
QUERIES=(
    "PPK_forBlast.fasta"
    "TRP_forBlast.fasta"
)

# --- Parameters ---
THREADS=8          # match -c above
EVALUE="1e-5"
OUTFMT=6           # tabular; change to "6 std stitle" for titles too
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
echo "================================================"

# ============================================================
# Step 1 — Build nucleotide database (only once)
# ============================================================
DB_PATH="${DB_DIR}/Iricinus_genomic_DB"

if [ ! -f "${DB_PATH}.nhr" ]; then
    echo ""
    echo "[1/2] Building BLAST database from genome..."
    makeblastdb \
        -in      "${GENOME}" \
        -title   "Iricinus_genomic" \
        -dbtype  nucl \
        -out     "${DB_PATH}" \
        -parse_seqids
    echo "      Database built: ${DB_PATH}"
else
    echo "[1/2] Database already exists — skipping makeblastdb."
fi

# ============================================================
# Step 2 — Run tBLASTn for each receptor file (loop)
#           tBLASTn: protein query vs. nucleotide db (translated)
#           Use blastn instead if your receptors are nucleotide seqs
# ============================================================
echo ""
echo "[2/2] Running BLAST queries..."

for QUERY_FILE in "${QUERIES[@]}"; do

    QUERY_PATH="${RECEPTOR_DIR}/${QUERY_FILE}"
    BASENAME="${QUERY_FILE%.fasta}"          # e.g. PPK_forBlast
    OUT_FILE="${OUT_DIR}/${BASENAME}_vs_Iricinus.txt"
    LOG_FILE="${OUT_DIR}/${BASENAME}_vs_Iricinus.log"

    # Skip if query file is missing
    if [ ! -f "${QUERY_PATH}" ]; then
        echo "  [WARN] Query not found, skipping: ${QUERY_PATH}"
        continue
    fi

    echo ""
    echo "  --> Query:  ${QUERY_FILE}"
    echo "      Output: ${OUT_FILE}"
    echo "      Start:  $(date)"

    tblastn \
        -query          "${QUERY_PATH}" \
        -db             "${DB_PATH}" \
        -num_threads    "${THREADS}" \
        -evalue         "${EVALUE}" \
        -outfmt         "${OUTFMT}" \
        -max_target_seqs "${MAX_SEQS}" \
        -out            "${OUT_FILE}" \
        2> "${LOG_FILE}"

    # Quick hit count
    HITS=$(wc -l < "${OUT_FILE}")
    echo "      Done:   $(date)  |  Hits: ${HITS}"

done

# ============================================================
# Summary
# ============================================================
echo ""
echo "================================================"
echo "All queries finished: $(date)"
echo "Results in: ${OUT_DIR}"
ls -lh "${OUT_DIR}"/*.txt 2>/dev/null
echo "================================================"
