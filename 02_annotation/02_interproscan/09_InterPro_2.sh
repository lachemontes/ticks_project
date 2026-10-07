#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 8
#SBATCH --mem=30GB
#SBATCH -t 72:00:00
#SBATCH -J mInterPro
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/interpro/de_novo/interpro_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/interpro/de_novo/interpro_%A.err

module load bioinfo-tools
module load InterProScan/5.52-86.0

interproscan.sh \
    -i    /cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/cd-hit/de_novo/transcripts_final_busco_inter_pep_98_denovo.fasta \
    -b    /cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/interpro/de_novo/Iric_de_novo_interPro \
    -t    p \
    -goterms \
    -f    TSV,XML \
    -appl PANTHER,CDD,Pfam,SUPERFAMILY,TMHMM \
    --cpu 8
