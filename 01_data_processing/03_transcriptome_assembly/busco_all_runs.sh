#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 12
#SBATCH --mem=90GB
#SBATCH -t 72:00:00
#SBATCH -J busco_m
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/busco/logs/busco_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/busco/logs/busco_%A.err

# ============================================================
# BUSCO completeness analysis — Ticks (Ixodes ricinus)
# Runs both protein and transcriptome assessments in a loop
# NOTE: assumes BUSCO conda env is already active when submitting
# ============================================================

# --- Parameters ---
THREADS=12
LINEAGE="arthropoda_odb10"
OUT_BASE="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/busco"

# Make sure logs directory exists
mkdir -p "${OUT_BASE}/logs"

# ============================================================
# Define all BUSCO runs
# Format:  "MODE|INPUT_FILE|RUN_NAME"
#   MODE = protein | transcriptome | genome
# ============================================================
RUNS=(
    # --- Protein analyses ---
    "protein|/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/transcriptomes/Transcriptomes_2023_2024.fasta.transdecoder.pep|busco_de_novo_pep"

    "protein|/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/cd-hit/transcripts_final_busco_inter_pep.fasta|busco_genome_guide_pep"

    # --- Transcriptome (CDS) analyses ---
    "transcriptome|/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/transdecoder/transcripts.fasta.transdecoder.cds|busco_transdecoder_cds"

    "transcriptome|/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/transcriptomes/CD_HIT-EST_Transcriptomes_2023_2024.fasta.transdecoder.cds.No_redundancy_fix.fasta|busco_cdhit_cds"
)

# ============================================================
# Header
# ============================================================
echo "================================================"
echo "Job started : $(date)"
echo "Node        : $(hostname)"
echo "Lineage     : ${LINEAGE}"
echo "Output base : ${OUT_BASE}"
echo "================================================"

TOTAL=${#RUNS[@]}
COUNT=0

# ============================================================
# Loop over all runs
# ============================================================
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

    # Skip if input file not found
    if [ ! -f "${INPUT}" ]; then
        echo "  [WARN] Input not found, skipping."
        continue
    fi

    # Skip if output already exists
    if [ -d "${OUT_PATH}" ]; then
        echo "  [SKIP] Output already exists."
        continue
    fi

    busco \
        -i "${INPUT}"   \
        -l "${LINEAGE}" \
        -o "${OUT_PATH}" \
        -m "${MODE}"    \
        -c "${THREADS}"

    if [ $? -eq 0 ]; then
        echo "  Done : $(date)"
        SUMMARY=$(ls "${OUT_PATH}/short_summary"*".txt" 2>/dev/null | head -1)
        if [ -n "${SUMMARY}" ]; then
            echo "  --- Short summary ---"
            grep "C:" "${SUMMARY}" | head -1
        fi
    else
        echo "  [ERROR] BUSCO failed for ${NAME}"
    fi

done

# ============================================================
# Final summary
# ============================================================
echo ""
echo "================================================"
echo "All BUSCO runs finished: $(date)"
echo "================================================"
echo ""
echo "Completeness summary:"
echo ""
for RUN in "${RUNS[@]}"; do
    IFS='|' read -r MODE INPUT NAME <<< "${RUN}"
    SUMMARY=$(ls "${OUT_BASE}/${NAME}/short_summary"*".txt" 2>/dev/null | head -1)
    if [ -n "${SUMMARY}" ]; then
        echo "  ${NAME}"
        grep "C:" "${SUMMARY}" | head -1 | sed 's/^/    /'
        echo ""
    fi
done
echo "================================================"
