#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 12
#SBATCH --mem=32GB
#SBATCH -t 06:00:00
#SBATCH -J kallisto_rfstranded
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --array=1-16
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto/rfstranded/logs/kallisto_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto/rfstranded/logs/kallisto_%A_%a.err

set -eu

READS_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/trimmed_libs"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto/rfstranded"
INDEX="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto/hybrid_CDS_receptors.idx"
SAMPLES="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto/kallisto_samples.txt"

mkdir -p "${OUT_DIR}/logs"
module load bioinfo-tools kallisto/0.48.0

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
echo "Strandedness: --rf-stranded"
echo "Start       : $(date)"
echo "================================================"

[ ! -f "${R1}" ]    && echo "[ERROR] R1 not found: ${R1}"       && exit 1
[ ! -f "${R2}" ]    && echo "[ERROR] R2 not found: ${R2}"       && exit 1
[ ! -f "${INDEX}" ] && echo "[ERROR] Index not found: ${INDEX}" && exit 1

mkdir -p "${SAMPLE_OUT}"

kallisto quant \
    -i "${INDEX}" \
    -o "${SAMPLE_OUT}" \
    --threads 12 \
    --rf-stranded \
    "${R1}" "${R2}"

MAPPED=$(python3 -c "
import json
with open('${SAMPLE_OUT}/run_info.json') as f:
    d = json.load(f)
print(f\"{d['p_pseudoaligned']:.1f}% pseudoaligned ({d['n_pseudoaligned']:,} / {d['n_processed']:,} reads)\")
" 2>/dev/null || echo "see run_info.json")

echo "Pseudoalignment rate: ${MAPPED}"
echo "Done: $(date)"
echo "================================================"
