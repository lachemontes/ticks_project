#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p main
#SBATCH -c 18
#SBATCH --mem=256GB
#SBATCH -t 5:00:00        # Una hora debería ser suficiente para el merge
#SBATCH -J merge_bams_ticks
#SBATCH --output=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam/logs/merge_%j.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam/logs/merge_%j.err

module load samtools/1.20

OUTPUT_DIR="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam"
MERGED_BAM="${OUTPUT_DIR}/merged_all_samples.bam"

echo "Iniciando fusión de archivos BAM..."

# Listar todos los archivos BAM ordenados
SORTED_BAM_FILES=(${OUTPUT_DIR}/*_sorted.bam)

if [ ${#SORTED_BAM_FILES[@]} -lt 2 ]; then
    echo "ERROR: No se encontraron archivos *_sorted.bam para fusionar. ¿Ha terminado el array?"
    exit 1
fi

# Fusionar
samtools merge -@ 17 "$MERGED_BAM" "${SORTED_BAM_FILES[@]}"

# Indexar
echo "Indexando archivo BAM fusionado..."
samtools index "$MERGED_BAM"

echo "Fusión y procesamiento de BAM finalizado."
