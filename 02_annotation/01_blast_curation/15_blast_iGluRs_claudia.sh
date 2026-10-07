#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p main
#SBATCH -c 8
#SBATCH --mem=20GB
#SBATCH -t 12:00:00
#SBATCH -J blastp_iGluR
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/logs/blastp_iGluR_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/logs/blastp_iGluR_%A.err

# ============================================================
# blastp: iGluR receptors (Drosophila, A. bruennichi, insects)
# vs. I. ricinus predicted proteins (OGS1.0).
# Then select best hit per query.
# ============================================================

set -eu

# ============================================================
# Paths
# ============================================================
QUERY="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/blast_resorces/IR_iGluRs_Dmel_abru.fasta"
DB_FASTA="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/cd-hit/IR_iGlur_cdhit100.fasta"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast"
DB_DIR="${OUT_DIR}/db_iGluR2"
BESTHITS_SCRIPT="${OUT_DIR}/best_hits_by_pident.py"   # place the .py here

# ============================================================
# Parameters
# ============================================================
THREADS=8
EVALUE="1e-5"
MAX_SEQS=10           # keep several hits; best-hit script picks 1 per query

# Output names
DB_PATH="${DB_DIR}/Iricinus_OGS1.0_proteins_DB"
RAW_OUT="${OUT_DIR}/iGluR_vs_Iricinus_blastp22.tsv"
BEST_OUT="${OUT_DIR}/iGluR_vs_Iricinus_blastp_BestByPident22.csv"

# ============================================================
# Setup
# ============================================================
mkdir -p "${OUT_DIR}/logs" "${DB_DIR}"

module load bioinfo-tools 2>/dev/null || true
module load blast/2.9.0+ 2>/dev/null || true

# Conda env with pandas (for the best-hits step)
source $(conda info --base)/etc/profile.d/conda.sh 2>/dev/null || true
conda activate Gassembly 2>/dev/null || true

echo "================================================"
echo "Job started : $(date)"
echo "Node        : $(hostname)"
echo "Program     : blastp (protein vs protein)"
echo "Query       : ${QUERY}"
echo "Database    : ${DB_FASTA}"
echo "================================================"

# ============================================================
# STEP 1 — Build protein database (once)
# ============================================================
echo ""
echo "[1/3] Building protein database..."
if [ ! -f "${DB_FASTA}" ]; then
    echo "  [ERROR] Database FASTA not found: ${DB_FASTA}"
    exit 1
fi

if [ ! -f "${DB_PATH}.phr" ]; then
    makeblastdb -in "${DB_FASTA}" -dbtype prot \
                -title "Iricinus_OGS1.0_proteins" -out "${DB_PATH}" -parse_seqids
    echo "      Database built: ${DB_PATH}"
else
    echo "      Database already exists — skipping."
fi

# ============================================================
# STEP 2 — Run blastp
# ============================================================
echo ""
echo "[2/3] Running blastp..."
echo "      Start: $(date)"

if [ ! -f "${QUERY}" ]; then
    echo "  [ERROR] Query not found: ${QUERY}"
    exit 1
fi

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

# ============================================================
# STEP 3 — Select best hit per query
# ============================================================
echo ""
echo "[3/3] Selecting best hits..."

if [ -s "${RAW_OUT}" ] && [ -f "${BESTHITS_SCRIPT}" ]; then
    python "${BESTHITS_SCRIPT}" "${RAW_OUT}" "${BEST_OUT}"
    echo "      Best hits written: ${BEST_OUT}"
elif [ ! -f "${BESTHITS_SCRIPT}" ]; then
    echo "      [WARN] best-hits script not found at ${BESTHITS_SCRIPT}"
    echo "             You can run it manually later:"
    echo "             python best_hits_by_pident.py ${RAW_OUT} ${BEST_OUT}"
else
    echo "      [INFO] No hits — nothing to select."
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "================================================"
echo "All done: $(date)"
echo "Raw hits:   ${RAW_OUT}"
echo "Best hits:  ${BEST_OUT}"
echo "================================================"
