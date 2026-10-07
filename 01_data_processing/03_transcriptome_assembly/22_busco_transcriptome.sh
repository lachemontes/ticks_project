#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 12
#SBATCH --mem=90GB
#SBATCH -t 72:00:00
#SBATCH -J busco_transcriptomes
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/busco/logs/busco_transcriptomes_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/busco/logs/busco_transcriptomes_%A.err

# ============================================================
# BUSCO — transcriptome mode
# Runs genome-guided and de novo CDS assessments
# Each output in its own subdirectory under busco/
# ============================================================

THREADS=12
LINEAGE="arthropoda_odb10"
BUSCO_BASE="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/busco"

mkdir -p "${BUSCO_BASE}/logs"

# ── Activate BUSCO env ────────────────────────────────────────────────────────
source $(conda info --base)/etc/profile.d/conda.sh 2>/dev/null || true
conda activate BUSCO 2>/dev/null || true

# ── Runs: "INPUT|OUTPUT_DIR_NAME" ────────────────────────────────────────────
RUNS=(
    "/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/transdecoder/transcripts.fasta.transdecoder.cds|busco_genomeGuide_cds"
    "/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/transcriptomes/Transcriptomes_2023_2024.fasta.transdecoder.cds|busco_deNovo_cds"
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
    IFS='|' read -r INPUT OUTNAME <<< "${RUN}"
    OUT_PATH="${BUSCO_BASE}/${OUTNAME}"

    echo ""
    echo "------------------------------------------------"
    echo "  [$COUNT/$TOTAL] ${OUTNAME}"
    echo "  Mode   : transcriptome"
    echo "  Input  : ${INPUT}"
    echo "  Output : ${OUT_PATH}"
    echo "  Start  : $(date)"
    echo "------------------------------------------------"

    if [ ! -f "${INPUT}" ]; then
        echo "  [WARN] Input not found, skipping: ${INPUT}"
        continue
    fi

    if [ -d "${OUT_PATH}" ]; then
        echo "  [SKIP] Output already exists: ${OUT_PATH}"
        continue
    fi

    mkdir -p "${OUT_PATH}"

    busco \
        -i "${INPUT}" \
        -l "${LINEAGE}" \
        -o "${OUTNAME}" \
        --out_path "${BUSCO_BASE}" \
        -m transcriptome \
        -c "${THREADS}" -f

    if [ $? -eq 0 ]; then
        echo "  Done: $(date)"
        SUMMARY=$(ls "${OUT_PATH}/short_summary"*".txt" 2>/dev/null | head -1)
        if [ -n "${SUMMARY}" ]; then
            echo "  --- Result ---"
            grep "C:" "${SUMMARY}" | head -1
        fi
    else
        echo "  [ERROR] BUSCO failed for ${OUTNAME}"
    fi

done

echo ""
echo "================================================"
echo "All done: $(date)"
echo ""
echo "=== Completeness summary ==="
for RUN in "${RUNS[@]}"; do
    IFS='|' read -r INPUT OUTNAME <<< "${RUN}"
    SUMMARY=$(ls "${BUSCO_BASE}/${OUTNAME}/short_summary"*".txt" 2>/dev/null | head -1)
    if [ -n "${SUMMARY}" ]; then
        echo "  ${OUTNAME}:"
        grep "C:" "${SUMMARY}" | head -1 | sed 's/^/    /'
    fi
done
echo "================================================"
