#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 8
#SBATCH --mem=40GB
#SBATCH -t 24:00:00
#SBATCH -J interpro_receptors
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/interpro/interpro_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/interpro/interpro_%A.err

# ============================================================
# InterProScan: IR_BMC & GR_BMC receptors
# ============================================================

# --- Paths ---
INPUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/phylo"
OUTPUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/interpro"

# --- Files to process (add more here if needed) ---
QUERIES=(
    "iqtree_final_80iric_phylo2026_zm.fasta"
)

# --- InterProScan parameters ---
THREADS=8
APPLICATIONS="PANTHER,CDD,Pfam,SUPERFAMILY,TMHMM"
FORMATS="TSV,XML,GFF3"

# ============================================================
# Setup
# ============================================================
mkdir -p "${OUTPUT_DIR}"

module load bioinfo-tools
module load InterProScan/5.52-86.0

echo "================================================"
echo "Job started : $(date)"
echo "Node        : $(hostname)"
echo "================================================"

# ============================================================
# Loop over each receptor file
# ============================================================
TOTAL=${#QUERIES[@]}
COUNT=0

for QUERY_FILE in "${QUERIES[@]}"; do

    COUNT=$((COUNT + 1))
    INPUT="${INPUT_DIR}/${QUERY_FILE}"
    BASENAME="${QUERY_FILE%.fasta}"          # e.g. IR_BMC
    OUT_PREFIX="${OUTPUT_DIR}/${BASENAME}_interpro_iGluR_IRs_2208"

    echo ""
    echo "------------------------------------------------"
    echo "  [$COUNT/$TOTAL] Processing: ${QUERY_FILE}"
    echo "  Input  : ${INPUT}"
    echo "  Output : ${OUT_PREFIX}.*"
    echo "  Start  : $(date)"
    echo "------------------------------------------------"

    # Skip if input file not found
    if [ ! -f "${INPUT}" ]; then
        echo "  [WARN] File not found, skipping: ${INPUT}"
        continue
    fi

    # Skip if output already exists
    if [ -f "${OUT_PREFIX}.tsv" ]; then
        echo "  [SKIP] Output already exists: ${OUT_PREFIX}.tsv"
        continue
    fi

    interproscan.sh \
        -i    "${INPUT}"       \
        -b    "${OUT_PREFIX}"  \
        -t    p                \
        -goterms               \
        -f    "${FORMATS}"     \
        -appl "${APPLICATIONS}"\
        --cpu "${THREADS}"

    # Check exit status
    if [ $? -eq 0 ]; then
        echo "  Done : $(date)"
        echo "  Lines in TSV: $(wc -l < ${OUT_PREFIX}.tsv)"
    else
        echo "  [ERROR] InterProScan failed for ${QUERY_FILE}"
    fi

done

# ============================================================
# Summary
# ============================================================
echo ""
echo "================================================"
echo "All files processed: $(date)"
echo "Results in: ${OUTPUT_DIR}"
ls -lh "${OUTPUT_DIR}"/*.tsv 2>/dev/null
echo "================================================"
