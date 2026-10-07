#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 8
#SBATCH --mem=30GB
#SBATCH -t 05:00:00
#SBATCH -J kallisto_index
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto/logs/kallisto_index_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto/logs/kallisto_index_%A.err

# ============================================================
# Kallisto index — run ONCE before quantification
# ============================================================

set -eu

CDS="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/transdecoder/hybrid_CDS_full.fasta"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/kallisto"
INDEX="${OUT_DIR}/hybrid_CDS_full.idx"

mkdir -p "${OUT_DIR}/logs"

module load bioinfo-tools kallisto/0.48.0

echo "Building kallisto index..."
echo "Input : ${CDS}"
echo "Index : ${INDEX}"
echo "Start : $(date)"

kallisto index -i "${INDEX}" "${CDS}"

echo "Done  : $(date)"
echo "Index size: $(ls -lh ${INDEX} | awk '{print $5}')"
