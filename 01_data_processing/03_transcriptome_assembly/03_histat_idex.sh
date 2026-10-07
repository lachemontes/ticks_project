#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p shared
#SBATCH -c 12
#SBATCH --mem=60GB
#SBATCH -t 2-00:00:00
#SBATCH -J hisat2_ticks
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=ps/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/hisat/logs/hisat2_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/hisat/logs/hisat2_%A_%a.err

# Load necessary modules
module load bioinfo-tools
module load hisat2/2.2.1
module load samtools



hisat2-build -p 12 /cfs/klemming/projects/supr/naiss2025-23-132/Ticks/data/genomes/I_ricinus/data/GCA/Iricinus_assembly_genomic.fna  /cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/hisat/genome_Index
