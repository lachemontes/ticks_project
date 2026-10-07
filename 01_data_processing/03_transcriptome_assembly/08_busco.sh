#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 12
#SBATCH --mem=90GB
#SBATCH -t 72:00:00
#SBATCH -J busco_m
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/busco/logs/busco_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/busco/logs/busco_%A_%a.err


log_dir="/cfs/klemming/projects/supr/naiss2023-23-109/Analysis/busco/mouthparts/transcriptome//logs"

# Crear directorio de salida si no existe

#mkdir -p "$log_dir"

# Mensaje de inicio

busco -i /cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/cd-hit/transcripts_final_busco_inter_pep.fasta -l arthropoda_odb10 -o /cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/busco/genome_guide -m protein -c 12


#busco -i /cfs/klemming/projects/supr/naiss2023-23-109/Analysis/stringTie2/mouthparts/star/transcripts.fasta -l arthropoda_odb10 -o out_file_transcriptome_busco -m transcriptome -c 8
