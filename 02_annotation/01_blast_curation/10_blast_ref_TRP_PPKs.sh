#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p main
#SBATCH -c 8
#SBATCH --mem=16GB
#SBATCH -t 02:00:00
#SBATCH -J blastp_PPK_TRP_ref_BMC
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/logs/blastp_PPK_TRP_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/logs/blastp_PPK_TRP_%A.err

set -eu

RESDIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/blast_resorces"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast"
BESTHITS="${OUT_DIR}/best_hits_by_pident.py"
OUTFMT="6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore slen"

mkdir -p "${OUT_DIR}/logs"

source $(conda info --base)/etc/profile.d/conda.sh 2>/dev/null || true
conda activate Gassembly 2>/dev/null || true

echo "================================================"
echo "Job started : $(date)"
echo "Node        : $(hostname)"
echo "================================================"

# ── Runs: QUERY|DB_FASTA|DB_NAME|TAG ─────────────────────────────────────────
RUNS=(
    "PPK_ref.fasta|PPK_BMC_proteins.fasta|PPK_BMC_DB|PPK_ref_vs_BMC"
    "TRP_ref.fasta|TRP_BMC_proteins.fasta|TRP_BMC_DB|TRP_ref_vs_BMC"
)

for RUN in "${RUNS[@]}"; do
    IFS='|' read -r QUERY_FILE DB_FILE DB_NAME TAG <<< "${RUN}"

    QUERY="${RESDIR}/${QUERY_FILE}"
    DB_FASTA="${RESDIR}/${DB_FILE}"
    DB_DIR="${OUT_DIR}/db_${DB_NAME}"
    DB_PATH="${DB_DIR}/${DB_NAME}"
    RAW_OUT="${OUT_DIR}/${TAG}_blastp.tsv"
    BEST_OUT="${OUT_DIR}/${TAG}_blastp_BestByPident.csv"

    echo ""
    echo "------------------------------------------------"
    echo "  Query : ${QUERY_FILE}"
    echo "  DB    : ${DB_FILE}"
    echo "  Start : $(date)"
    echo "------------------------------------------------"

    [ ! -f "${QUERY}"    ] && echo "  [ERROR] Query not found: ${QUERY}"    && continue
    [ ! -f "${DB_FASTA}" ] && echo "  [ERROR] DB not found: ${DB_FASTA}"    && continue

    mkdir -p "${DB_DIR}"

    # Build DB
    if [ ! -f "${DB_PATH}.phr" ]; then
        echo "  Building DB..."
        makeblastdb -in "${DB_FASTA}" -dbtype prot \
                    -title "${DB_NAME}" -out "${DB_PATH}" -parse_seqids
    else
        echo "  DB exists — skipping."
    fi

    # BLASTp
    blastp \
        -query           "${QUERY}" \
        -db              "${DB_PATH}" \
        -num_threads     8 \
        -evalue          1e-5 \
        -max_target_seqs 10 \
        -outfmt          "${OUTFMT}" \
        -out             "${RAW_OUT}"

    N=$(wc -l < "${RAW_OUT}")
    echo "  Raw hits: ${N} → ${TAG}_blastp.tsv"

    # Best hits
    if [ -s "${RAW_OUT}" ] && [ -f "${BESTHITS}" ]; then
        python "${BESTHITS}" "${RAW_OUT}" "${BEST_OUT}"
    else
        echo "  [WARN] No hits or best_hits script not found."
    fi
done

echo ""
echo "================================================"
echo "All done: $(date)"
echo "Results:"
ls -lh "${OUT_DIR}/PPK_ref_vs_BMC_blastp_BestByPident.csv" 2>/dev/null || echo "  PPK best hits not found"
ls -lh "${OUT_DIR}/TRP_ref_vs_BMC_blastp_BestByPident.csv" 2>/dev/null || echo "  TRP best hits not found"
echo "================================================"
