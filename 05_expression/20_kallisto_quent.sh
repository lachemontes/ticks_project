#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 12
#SBATCH --mem=60GB
#SBATCH -t 06:00:00
#SBATCH -J kallisto_quant
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --array=1-16
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto/logs/kallisto_quant_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto/logs/kallisto_quant_%A_%a.err

# ============================================================
# Kallisto quantification — array job (1 task per library)
#
# STRANDEDNESS NOTE:
#   Currently running WITHOUT strandedness flag (safe default).
#   After first run, check pseudoalignment rates in run_info.json.
#   If rates are low (<60%), try:
#     --fr-stranded  (forward stranded, e.g. TruSeq Stranded mRNA)
#     --rf-stranded  (reverse stranded, e.g. dUTP method)
# ============================================================

set -eu

# ── Paths ─────────────────────────────────────────────────────────────────────
READS_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/trimmed_libs"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto"
INDEX="${OUT_DIR}/hybrid_CDS_full.idx"
SAMPLES="${OUT_DIR}/kallisto_samples.txt"

# ── Setup ─────────────────────────────────────────────────────────────────────
mkdir -p "${OUT_DIR}/logs"
module load bioinfo-tools kallisto/0.48.0

# ── Select sample for this array task ─────────────────────────────────────────
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${SAMPLES}")
FILE_PREFIX=$(echo "${LINE}" | cut -f1)
SAMPLE_NAME=$(echo "${LINE}" | cut -f2)
TISSUE=$(echo "${LINE}"      | cut -f3)
SEX=$(echo "${LINE}"         | cut -f4)

R1="${READS_DIR}/${FILE_PREFIX}_R1_001_val_1.fq.gz"
R2="${READS_DIR}/${FILE_PREFIX}_R2_001_val_2.fq.gz"
SAMPLE_OUT="${OUT_DIR}/${SAMPLE_NAME}_${TISSUE}"

echo "================================================"
echo "Array task  : ${SLURM_ARRAY_TASK_ID}"
echo "Sample      : ${SAMPLE_NAME} | ${TISSUE} | Sex: ${SEX}"
echo "R1          : ${R1}"
echo "R2          : ${R2}"
echo "Output      : ${SAMPLE_OUT}"
echo "Start       : $(date)"
echo "================================================"

[ ! -f "${R1}" ]    && echo "[ERROR] R1 not found: ${R1}"    && exit 1
[ ! -f "${R2}" ]    && echo "[ERROR] R2 not found: ${R2}"    && exit 1
[ ! -f "${INDEX}" ] && echo "[ERROR] Index not found: ${INDEX}" && exit 1

mkdir -p "${SAMPLE_OUT}"

# Running without --fr-stranded / --rf-stranded (unstranded)
# Add --fr-stranded or --rf-stranded if pseudoalignment rates are low
kallisto quant \
    -i "${INDEX}" \
    -o "${SAMPLE_OUT}" \
    --threads 12 \
    "${R1}" "${R2}"

# ── Print mapping rate ─────────────────────────────────────────────────────────
MAPPED=$(python3 -c "
import json
with open('${SAMPLE_OUT}/run_info.json') as f:
    d = json.load(f)
print(f\"{d['p_pseudoaligned']:.1f}% pseudoaligned ({d['n_pseudoaligned']:,} / {d['n_processed']:,} reads)\")
" 2>/dev/null || echo "see run_info.json")

echo ""
echo "Pseudoalignment rate: ${MAPPED}"
echo "Done: $(date)"
echo "================================================"
