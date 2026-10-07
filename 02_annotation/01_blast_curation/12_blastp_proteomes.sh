#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p main
#SBATCH -c 8
#SBATCH --mem=20GB
#SBATCH -t 12:00:00
#SBATCH -J blastp_receptors
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --array=0-3
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blast_proteomes/logs/blastp_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blast_proteomes/logs/blastp_%A_%a.err

# ============================================================
# blastp ARRAY: 4 receptor families x 2 transcriptome proteomes
# Array index: 0=iGluRs/IRs  1=GR  2=PPK  3=TRP
# outfmt 6 + slen for transcript length comparison.
# ============================================================

set -eu

# ── Paths ─────────────────────────────────────────────────────────────────────
QUERY_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/phylo"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/blast/blast_proteomes"
DB_DIR="${OUT_DIR}/db"
BESTHITS_SCRIPT="${OUT_DIR}/best_hits_by_pident.py"

# ── Query gene sets (one per array task) ──────────────────────────────────────
QUERIES=(
    "IR_iGluR_final_80.fasta"
)

# ── Transcriptome proteomes ───────────────────────────────────────────────────
DB_GENOME_GUIDE="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/cd-hit/transcripts_final_busco_inter_pep.fasta"
DB_DENOVO="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/transcriptomes/Transcriptomes_2023_2024.fasta.transdecoder.pep"

DATABASES=(
    "genomeGuide|${DB_GENOME_GUIDE}"
    "deNovo|${DB_DENOVO}"
)

# ── BLAST parameters ──────────────────────────────────────────────────────────
THREADS=8
EVALUE="1e-5"
MAX_SEQS=10
OUTFMT="6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore slen"

# ── Setup ─────────────────────────────────────────────────────────────────────
mkdir -p "${OUT_DIR}/logs" "${DB_DIR}"

module load bioinfo-tools 2>/dev/null || true
module load blast/2.9.0+  2>/dev/null || true

source $(conda info --base)/etc/profile.d/conda.sh 2>/dev/null || true
conda activate Gassembly 2>/dev/null || true

# Stagger DB builds to avoid race condition when all tasks start simultaneously
sleep $((SLURM_ARRAY_TASK_ID * 30))

# ── Select this task's query ──────────────────────────────────────────────────
QUERY_FILE="${QUERIES[$SLURM_ARRAY_TASK_ID]}"
QUERY_PATH="${QUERY_DIR}/${QUERY_FILE}"
RECEPTOR="${QUERY_FILE%%_*}"

echo "================================================"
echo "Array task  : ${SLURM_ARRAY_TASK_ID}  ->  ${RECEPTOR}"
echo "Job started : $(date)"
echo "Node        : $(hostname)"
echo "Query       : ${QUERY_PATH}"
echo "================================================"

[ ! -f "${QUERY_PATH}" ] && echo "[ERROR] Query not found: ${QUERY_PATH}" && exit 1

# ── STEP 1: Build DBs ─────────────────────────────────────────────────────────
echo ""
echo "[1] Building databases (if not already built)..."
for DB_ENTRY in "${DATABASES[@]}"; do
    IFS='|' read -r DB_LABEL DB_FASTA <<< "${DB_ENTRY}"
    DB_PATH="${DB_DIR}/${DB_LABEL}_DB"

    [ ! -f "${DB_FASTA}" ] && echo "  [ERROR] Proteome not found: ${DB_FASTA}" && exit 1

    if [ ! -f "${DB_PATH}.phr" ]; then
        echo "  Building DB: ${DB_LABEL}"
        makeblastdb -in "${DB_FASTA}" -dbtype prot \
                    -title "${DB_LABEL}" -out "${DB_PATH}" -parse_seqids
    else
        echo "  DB exists: ${DB_LABEL} (skipping)"
    fi
done

# ── STEP 2: blastp vs each transcriptome ──────────────────────────────────────
echo ""
echo "[2] Running blastp for ${RECEPTOR}..."

for DB_ENTRY in "${DATABASES[@]}"; do
    IFS='|' read -r DB_LABEL DB_FASTA <<< "${DB_ENTRY}"
    DB_PATH="${DB_DIR}/${DB_LABEL}_DB"

    TAG="${RECEPTOR}_vs_${DB_LABEL}"
    RAW_OUT="${OUT_DIR}/${TAG}_blastp.tsv"
    BEST_OUT="${OUT_DIR}/${TAG}_blastp_BestByPident.csv"

    echo ""
    echo "  --> ${TAG}"
    echo "      Start: $(date)"

    blastp \
        -query           "${QUERY_PATH}" \
        -db              "${DB_PATH}" \
        -num_threads     "${THREADS}" \
        -evalue          "${EVALUE}" \
        -max_target_seqs "${MAX_SEQS}" \
        -outfmt          "${OUTFMT}" \
        -out             "${RAW_OUT}"

    N_HITS=$(wc -l < "${RAW_OUT}")
    echo "      Raw hits: ${N_HITS}"

    if [ -s "${RAW_OUT}" ] && [ -f "${BESTHITS_SCRIPT}" ]; then
        python "${BESTHITS_SCRIPT}" "${RAW_OUT}" "${BEST_OUT}"
    elif [ ! -f "${BESTHITS_SCRIPT}" ]; then
        echo "      [WARN] best-hits script not found — skipping."
    else
        echo "      [INFO] No hits."
    fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "================================================"
echo "Task ${SLURM_ARRAY_TASK_ID} (${RECEPTOR}) done: $(date)"
ls -lh "${OUT_DIR}/${RECEPTOR}"*BestByPident.csv 2>/dev/null || echo "  No best-hit files"
echo "================================================"
