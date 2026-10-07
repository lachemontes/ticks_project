#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 16
#SBATCH --mem=60GB
#SBATCH -t 2-00:00:00
#SBATCH -J IQtree_arr
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --array=3
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/phylo/phylo_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/phylo/phylo_%A_%a.err

# ============================================================
# Phylogenetics pipeline (ARRAY version):
#   1) MAFFT   -> alignment
#   2) IQ-TREE -> ModelFinder (best model by BIC) + ML tree + UFBoot
#
# Each array task handles ONE receptor set, running in parallel.
# --array=0-2  -> three tasks (indices 0, 1, 2).
# ============================================================

set -eu

# ============================================================
# Paths
# ============================================================
IN_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/phylo"
OUT_BASE="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/phylo"

# ============================================================
# Jobs array: "INPUT_FASTA|OUTPUT_SUBDIR|PREFIX"
# The SLURM_ARRAY_TASK_ID picks one entry.
# If you add/remove receptors, update --array range above to match.
# ============================================================


JOBS=(
    "GR_sequences_aa_phylo.fasta|GRs|GR_phylo"
    "PPK_sequences_aa.fasta|PPKs|PPK_phylo"
    "TRP_sequences_aa.fasta|TRPs|TRP_phylo"
    "IR_sequences_aa.fasta|IR_phylo|IR_phylo"
)


# Select this task's job
JOB="${JOBS[$SLURM_ARRAY_TASK_ID]}"
IFS='|' read -r FASTA SUBDIR PREFIX <<< "${JOB}"

# ============================================================
# Parameters
# ============================================================
THREADS=16
BOOTSTRAP=1000
MODEL="MFP"             # ModelFinder Plus; best model chosen by BIC below

# ============================================================
# Setup — activate conda (MAFFT + IQ-TREE env)
# ============================================================
source $(conda info --base)/etc/profile.d/conda.sh 2>/dev/null || true
conda activate IQtree 2>/dev/null || true

IN_FASTA="${IN_DIR}/${FASTA}"
OUT_DIR="${OUT_BASE}/${SUBDIR}"
ALN="${OUT_DIR}/${PREFIX}_mafft.fasta"

echo "================================================"
echo "Array task  : ${SLURM_ARRAY_TASK_ID}  ->  ${PREFIX}"
echo "Job started : $(date)"
echo "Node        : $(hostname)"
echo "Input       : ${IN_FASTA}"
echo "Outdir      : ${OUT_DIR}"
echo "MAFFT       : $(mafft --version 2>&1 | head -1 || echo 'NOT FOUND')"
echo "IQ-TREE     : $(iqtree --version 2>&1 | head -1 || echo 'NOT FOUND')"
echo "================================================"

if [ ! -f "${IN_FASTA}" ]; then
    echo "[ERROR] Input not found: ${IN_FASTA}"
    exit 1
fi

mkdir -p "${OUT_DIR}"

# ============================================================
# STEP 1 — MAFFT alignment
# ============================================================
echo ""
echo "[1/2] MAFFT alignment..."
echo "      Start: $(date)"

if [ -f "${ALN}" ]; then
    echo "      Alignment already exists — skipping MAFFT."
else
    mafft --auto --thread "${THREADS}" "${IN_FASTA}" > "${ALN}"
    echo "      Done:  $(date)"
fi

N_SEQ=$(grep -c '>' "${ALN}")
echo "      Sequences aligned: ${N_SEQ}"

# ============================================================
# STEP 2 — IQ-TREE (ModelFinder by BIC + ML tree + UFBoot)
# ============================================================
echo ""
echo "[2/2] IQ-TREE (ModelFinder + tree + ${BOOTSTRAP} UFBoot)..."
echo "      Start: $(date)"

iqtree \
    -s "${ALN}" \
    -m "${MODEL}" \
    -merit BIC \
    -B "${BOOTSTRAP}" \
    -T "${THREADS}" \
    --prefix "${OUT_DIR}/${PREFIX}" \
    -redo

echo "      Done:  $(date)"
echo ""
echo "================================================"
echo "Finished ${PREFIX}: $(date)"
echo "Tree: ${OUT_DIR}/${PREFIX}.treefile"
BEST=$(grep "Best-fit model" "${OUT_DIR}/${PREFIX}.iqtree" 2>/dev/null || echo "see .iqtree")
echo "Best model: ${BEST}"
echo "================================================"
