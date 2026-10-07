#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p main
#SBATCH -c 8
#SBATCH --mem=256GB
#SBATCH -t 24:00:00
#SBATCH -J samTobam_mouth
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --array=1-16
#SBATCH --output=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam/logs/bam_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam/logs/bam_%A_%a.err

module load bioinfo-tools
module load samtools/1.20

input_dir="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/hisat"
output_dir="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam"
list_file="${output_dir}/libraries.txt"
log_dir="${output_dir}/logs"
mkdir -p "$log_dir"

ref_genome="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/data/genomes/I_ricinus/data/GCA/Iricinus_assembly_genomic.fna"

sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$list_file")
sam_file="${input_dir}/${sample}.sam"
bam_file="${output_dir}/${sample}.bam"
sorted_bam="${output_dir}/${sample}_sorted.bam"

if [[ ! -f "$sam_file" ]]; then
    echo "ERROR: SAM file not found: $sam_file" >&2
    exit 1
fi

# Crear directorio temporal local
scratch_dir="/scratch/$USER/$SLURM_JOB_ID"
mkdir -p "$scratch_dir"

echo "[$(date)] Converting $sam_file to BAM..."
samtools view -@ $SLURM_CPUS_PER_TASK -Sb -T "$ref_genome" "$sam_file" -o "$bam_file"

echo "[$(date)] Sorting BAM..."
samtools sort -@ $SLURM_CPUS_PER_TASK -T "$scratch_dir/${sample}" -o "$sorted_bam" "$bam_file"

echo "[$(date)] Indexing sorted BAM..."
samtools index "$sorted_bam"

rm -f "$bam_file"
rm -rf "$scratch_dir"

echo "[$(date)] Finished processing sample: $sample"
