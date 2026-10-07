#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p shared
#SBATCH -c 4
#SBATCH --mem=20GB
#SBATCH -t 1-00:00:00
#SBATCH -J Trans_m_trinity
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/transdecoder/trans_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/transdecoder/trans_%A_%a.err


# Load the modules



TransDecoder.LongOrfs -t /cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/stringtie/transcripts.fasta

TransDecoder.Predict -t /cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/stringtie/transcripts.fasta
