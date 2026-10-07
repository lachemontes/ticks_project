#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p main           
#SBATCH -c 18             
#SBATCH --mem=256GB       
#SBATCH -t 24:00:00        
#SBATCH -J final_stringtie 
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/stringtie/logs/st_final_%j.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/stringtie/logs/st_final_%j.err

### Configuración de Módulos y Rutas
#module load stringtie/2.2.1

# Directorios y Archivos
OUTPUT_DIR="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/stringtie"
BAM_DIR="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam"
mkdir -p "$OUTPUT_DIR"

# Archivos de Referencia (AJUSTAR RUTAS)
REF_GTF="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/scripts/Iricinus_final_gene_set_v1.gff" # Anotación de referencia
MERGED_BAM="${BAM_DIR}/merged_all_samples.bam" # Archivo BAM de entrada
FINAL_GTF="${OUTPUT_DIR}/final_transcriptome_assembly.gtf" # Archivo de salida final


stringtie 
