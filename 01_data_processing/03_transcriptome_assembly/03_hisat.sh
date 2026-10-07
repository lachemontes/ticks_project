#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p shared
#SBATCH -c 12
#SBATCH --mem=60GB
#SBATCH -t 3-00:00:00
#SBATCH -J hisat2_ticks
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --array=1-32
#SBATCH --output=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/hisat/logs/hisat2_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/hisat/logs/hisat2_%A_%a.err

# Load necessary modules
module load bioinfo-tools
module load hisat2/2.2.1
module load samtools

# Define directories
input_dir="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/data/trimmed_libs"
output_dir="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/hisat"
list_file="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/data/trimmed_libs/libraries.txt"
genome_index="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/hisat"
log_dir="$output_dir/logs"

# Create directories if they don’t exist
mkdir -p "$output_dir"
mkdir -p "$log_dir"

# Get sample name from list
sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$list_file")

# Define input/output files
r1="${input_dir}/${sample}_R1_paired.fastq.gz"
r2="${input_dir}/${sample}_R2_paired.fastq.gz"
output_sam="${output_dir}/${sample}.sam"
output_bam="${output_dir}/${sample}.bam"

# Check if input files exist
if [[ ! -f "$r1" || ! -f "$r2" ]]; then
    echo "ERROR: Missing input files for $sample" >&2
    exit 1
fi

# Run HISAT2
echo "Running HISAT2 for sample: $sample"
hisat2 -p 12 -x "$genome_index" -1 "$r1" -2 "$r2" -S "$output_sam"

echo "HISAT2 completed for sample: $sample"

# Combinar archivos de error HISAT2 en un solo archivo
cat "$log_dir"/*.err > "$log_dir/concatenated_hisat2_mapping_rate.txt"

