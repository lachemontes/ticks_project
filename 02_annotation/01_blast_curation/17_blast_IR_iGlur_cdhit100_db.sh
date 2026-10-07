#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p main
#SBATCH -c 8
#SBATCH --mem=20GB
#SBATCH -t 06:00:00
#SBATCH -J blastp_IR_iGluR
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/logs/blastp_IR_iGluR_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/logs/blastp_IR_iGluR_%A.err

# ============================================================
# blastp: I. ricinus IR/iGluR candidates (CD-HIT output)
#         vs. curated IR/iGluR database (Dmel + A. bruennichi)
# ============================================================

set -eu

# ── Paths ─────────────────────────────────────────────────────────────────────
QUERY="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/cd-hit/IR_iGlur_cdhit100.fasta"
DB_FASTA="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/blast_resorces/IR_iGluRs_Dmel_abru.fasta"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast"
DB_DIR="${OUT_DIR}/db_IR_iGluR_DmelAbru"
BESTHITS_SCRIPT="${OUT_DIR}/best_hits_by_pident.py"

# ── Parameters ────────────────────────────────────────────────────────────────
THREADS=8
EVALUE="1e-5"
MAX_SEQS=10

# ── Output files ──────────────────────────────────────────────────────────────
DB_PATH="${DB_DIR}/IR_iGluRs_Dmel_abru_DB"
RAW_OUT="${OUT_DIR}/IR_iGluR_vs_DmelAbru_blastp.tsv"
BEST_OUT="${OUT_DIR}/IR_iGluR_vs_DmelAbru_blastp_BestByPident.csv"

# ── Setup ─────────────────────────────────────────────────────────────────────
mkdir -p "${OUT_DIR}/logs" "${DB_DIR}"

module load bioinfo-tools 2>/dev/null || true
module load blast/2.9.0+  2>/dev/null || true

source $(conda info --base)/etc/profile.d/conda.sh 2>/dev/null || true
conda activate Gassembly 2>/dev/null || true

echo "================================================"
echo "Job started : $(date)"
echo "Node        : $(hostname)"
echo "Query       : ${QUERY}"
echo "Database    : ${DB_FASTA}"
echo "================================================"

# ── STEP 1: Build database ────────────────────────────────────────────────────
echo ""
echo "[1/3] Building BLAST database..."

[ ! -f "${DB_FASTA}" ] && echo "[ERROR] DB FASTA not found: ${DB_FASTA}" && exit 1

if [ ! -f "${DB_PATH}.phr" ]; then
    makeblastdb -in "${DB_FASTA}" -dbtype prot \
                -title "IR_iGluRs_Dmel_Abru" -out "${DB_PATH}" -parse_seqids
    echo "      Database built: ${DB_PATH}"
else
    echo "      Database already exists — skipping."
fi

# ── STEP 2: Run blastp ────────────────────────────────────────────────────────
echo ""
echo "[2/3] Running blastp..."
echo "      Start: $(date)"

[ ! -f "${QUERY}" ] && echo "[ERROR] Query not found: ${QUERY}" && exit 1

blastp \
    -query           "${QUERY}" \
    -db              "${DB_PATH}" \
    -num_threads     "${THREADS}" \
    -evalue          "${EVALUE}" \
    -max_target_seqs "${MAX_SEQS}" \
    -outfmt          6 \
    -out             "${RAW_OUT}"

N_HITS=$(wc -l < "${RAW_OUT}")
echo "      Done: $(date)  |  Raw hits: ${N_HITS}"

# ── STEP 3: Best hit per query ────────────────────────────────────────────────
echo ""
echo "[3/3] Selecting best hit per query by pident..."

if [ -s "${RAW_OUT}" ] && [ -f "${BESTHITS_SCRIPT}" ]; then
    python "${BESTHITS_SCRIPT}" "${RAW_OUT}" "${BEST_OUT}"
elif [ ! -f "${BESTHITS_SCRIPT}" ]; then
    echo "      [WARN] Script not found: ${BESTHITS_SCRIPT}"
    echo "             Copy best_hits_by_pident.py to ${OUT_DIR} and run manually."
else
    echo "      [INFO] No hits found."
fi

echo ""
echo "================================================"
echo "All done: $(date)"
echo "Raw hits  : ${RAW_OUT}"
echo "Best hits : ${BEST_OUT}"
echo "================================================"
