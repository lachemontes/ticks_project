#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 12
#SBATCH --mem=20GB
#SBATCH -t 72:00:00
#SBATCH -J busco_transcriptomes
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/busco/logs/busco_transcriptomes_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/busco/logs/busco_transcriptomes_%A.err

# ============================================================
# BUSCO — de-novo transcriptome (No_redundancy_fix)
# Runs: protein mode + transcriptome mode
# ============================================================

THREADS=12
LINEAGE="arthropoda_odb10"
OUT_BASE="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/busco"

mkdir -p "${OUT_BASE}/logs"

# ── Activate BUSCO env ────────────────────────────────────────────────────────
source $(conda info --base)/etc/profile.d/conda.sh 2>/dev/null || true
conda activate BUSCO 2>/dev/null || true

RUNS=(
    "protein|/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/transcriptomes/Transcriptomes_2023_2024.fasta.transdecoder.pep|busco_deNovo_pep"
    "transcriptome|/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/transcriptomes/Transcriptomes_2023_2024.fasta.transdecoder.cds.No_redundancy_fix.fasta|busco_deNovo_cds"
)

echo "================================================"
echo "Job started : $(date)"
echo "Node        : $(hostname)"
echo "Lineage     : ${LINEAGE}"
echo "================================================"

TOTAL=${#RUNS[@]}
COUNT=0

for RUN in "${RUNS[@]}"; do
    COUNT=$((COUNT + 1))
    IFS='|' read -r MODE INPUT NAME <<< "${RUN}"
    OUT_PATH="${OUT_BASE}/${NAME}"

    echo ""
    echo "------------------------------------------------"
    echo "  [$COUNT/$TOTAL] ${NAME}"
    echo "  Mode   : ${MODE}"
    echo "  Input  : ${INPUT}"
    echo "  Output : ${OUT_PATH}"
    echo "  Start  : $(date)"
    echo "------------------------------------------------"

    [ ! -f "${INPUT}" ] && echo "  [WARN] Input not found, skipping." && continue
    [ -d "${OUT_PATH}" ] && echo "  [SKIP] Output already exists." && continue

    busco \
        -i "${INPUT}" \
        -l "${LINEAGE}" \
        -o "${OUT_PATH}" \
        -m "${MODE}" \
        -c "${THREADS}"

    if [ $? -eq 0 ]; then
        echo "  Done: $(date)"
        SUMMARY=$(ls "${OUT_PATH}/short_summary"*".txt" 2>/dev/null | head -1)
        [ -n "${SUMMARY}" ] && grep "C:" "${SUMMARY}" | head -1
    else
        echo "  [ERROR] BUSCO failed for ${NAME}"
    fi
done

echo ""
echo "================================================"
echo "All done: $(date)"
echo ""
echo "Completeness summary:"
for RUN in "${RUNS[@]}"; do
    IFS='|' read -r MODE INPUT NAME <<< "${RUN}"
    SUMMARY=$(ls "${OUT_BASE}/${NAME}/short_summary"*".txt" 2>/dev/null | head -1)
    if [ -n "${SUMMARY}" ]; then
        echo "  ${NAME}:"
        grep "C:" "${SUMMARY}" | head -1 | sed 's/^/    /'
    fi
done
echo "================================================"
