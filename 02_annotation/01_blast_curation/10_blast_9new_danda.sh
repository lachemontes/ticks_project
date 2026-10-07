#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p main
#SBATCH -c 8
#SBATCH --mem=16GB
#SBATCH -t 02:00:00
#SBATCH -J blastp_9new_iGluR
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blast_proteomes/logs/blastp_9new_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blast_proteomes/logs/blastp_9new_%A.err

set -eu

RESDIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/receptors"
BLAST_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blast_proteomes"
BESTHITS="${BLAST_DIR}/best_hits_by_pident.py"
DB_DIR="${BLAST_DIR}/db"
OUTFMT="6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore slen"

# Query: 9 new iGluR sequences
QUERY="${BLAST_DIR}/9new_iGluR_candidates.fasta"

# Protein DBs (same as used for iGluRs before)
GG_DB="${DB_DIR}/genomeGuide_DB"
DN_DB="${DB_DIR}/deNovo_DB"

mkdir -p "${BLAST_DIR}/logs"

# Reemplaza las líneas de conda por esto en el script
module load bioinfo-tools
module load blast/2.9.0+

echo "================================================"
echo "Job started : $(date)"
echo "Node        : $(hostname)"
echo "================================================"

# ── [1] Extract 9 new sequences ───────────────────────────────────────────────
echo ""
echo "[1/4] Extracting 9 new iGluR sequences..."
seqkit grep \
    -p IricT00002429-PA,IricT00008071-PA,IricT00008072-PA,\
IricT00008073-PA,IricT00008344-PA,IricT00012647-PA,\
IricT00012769-PA,IricT00013208-PA,IricT00013211-PA \
    "${RESDIR}/IR_BMC_introDanda_blastzaide_9new.fasta" \
    > "${QUERY}"

echo "  Sequences: $(grep -c '>' ${QUERY})"

# ── [2] Verify DBs exist ──────────────────────────────────────────────────────
echo ""
echo "[2/4] Checking protein databases..."
[ ! -f "${GG_DB}.phr" ] && echo "[ERROR] genome-guided DB not found: ${GG_DB}" && exit 1
[ ! -f "${DN_DB}.phr" ] && echo "[ERROR] de novo DB not found: ${DN_DB}" && exit 1
echo "  DBs found ✓"

# ── [3] BLASTp vs genome-guided peptides ──────────────────────────────────────
echo ""
echo "[3/4] BLASTp vs genome-guided transcriptome (pep)..."
blastp \
    -query          "${QUERY}" \
    -db             "${GG_DB}" \
    -num_threads    8 \
    -evalue         1e-5 \
    -max_target_seqs 10 \
    -outfmt         "${OUTFMT}" \
    -out            "${BLAST_DIR}/9new_iGluR_vs_genomeGuide_blastp.tsv"

N_GG=$(wc -l < "${BLAST_DIR}/9new_iGluR_vs_genomeGuide_blastp.tsv")
echo "  Raw hits: ${N_GG}"

python "${BESTHITS}" \
    "${BLAST_DIR}/9new_iGluR_vs_genomeGuide_blastp.tsv" \
    "${BLAST_DIR}/9new_iGluR_vs_genomeGuide_blastp_BestByPident.csv"

# ── [4] BLASTp vs de novo peptides ───────────────────────────────────────────
echo ""
echo "[4/4] BLASTp vs de novo transcriptome (pep)..."
blastp \
    -query          "${QUERY}" \
    -db             "${DN_DB}" \
    -num_threads    8 \
    -evalue         1e-5 \
    -max_target_seqs 10 \
    -outfmt         "${OUTFMT}" \
    -out            "${BLAST_DIR}/9new_iGluR_vs_deNovo_blastp.tsv"

N_DN=$(wc -l < "${BLAST_DIR}/9new_iGluR_vs_deNovo_blastp.tsv")
echo "  Raw hits: ${N_DN}"

python "${BESTHITS}" \
    "${BLAST_DIR}/9new_iGluR_vs_deNovo_blastp.tsv" \
    "${BLAST_DIR}/9new_iGluR_vs_deNovo_blastp_BestByPident.csv"

echo ""
echo "================================================"
echo "Done: $(date)"
echo "Results in: ${BLAST_DIR}"
ls -lh "${BLAST_DIR}/9new_iGluR_vs_"*".csv" 2>/dev/null
echo "================================================"
# CHECK DB NAMES:
# ls /cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blast_proteomes/db/
