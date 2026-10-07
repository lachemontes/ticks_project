#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 8
#SBATCH --mem=16GB
#SBATCH -t 02:00:00
#SBATCH -J blastp_GR_ref_BMC
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/logs/blastp_GR_ref_BMC_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/logs/blastp_GR_ref_BMC_%A.err

set -eu

QUERY="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/blast_resorces/GR_ref.fasta"
DB_FASTA="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/blast_resorces/GR_BMC_proteins.fasta"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast"
DB_DIR="${OUT_DIR}/db_GR_BMC"
BESTHITS="${OUT_DIR}/best_hits_by_pident.py"

DB_PATH="${DB_DIR}/GR_BMC_DB"
RAW_OUT="${OUT_DIR}/GR_ref_vs_BMC_blastp.tsv"
BEST_OUT="${OUT_DIR}/GR_ref_vs_BMC_blastp_BestByPident.csv"

mkdir -p "${DB_DIR}" "${OUT_DIR}/logs"


# Edita el script y cambia la sección de setup así:
module load bioinfo-tools 2>/dev/null || true
module load blast/2.9.0+ 2>/dev/null || true

echo "================================================"
echo "Job started : $(date)"
echo "Query       : ${QUERY}"
echo "Database    : ${DB_FASTA}"
echo "================================================"

# Build DB
if [ ! -f "${DB_PATH}.phr" ]; then
    echo "[1/3] Building BLAST database..."
    makeblastdb -in "${DB_FASTA}" -dbtype prot \
                -title "GR_BMC" -out "${DB_PATH}" -parse_seqids
else
    echo "[1/3] DB already exists — skipping."
fi

# BLASTp
echo ""
echo "[2/3] Running blastp..."
blastp \
    -query           "${QUERY}" \
    -db              "${DB_PATH}" \
    -num_threads     8 \
    -evalue          1e-5 \
    -max_target_seqs 10 \
    -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore slen" \
    -out             "${RAW_OUT}"

N=$(wc -l < "${RAW_OUT}")
echo "      Raw hits: ${N}"

# Best hits
echo ""
echo "[3/3] Selecting best hit per query..."
if [ -s "${RAW_OUT}" ] && [ -f "${BESTHITS}" ]; then
    python "${BESTHITS}" "${RAW_OUT}" "${BEST_OUT}"
else
    echo "      [WARN] No hits or best_hits_by_pident.py not found."
fi

echo ""
echo "================================================"
echo "Done: $(date)"
echo "Raw hits : ${RAW_OUT}"
echo "Best hits: ${BEST_OUT}"
echo "================================================"
