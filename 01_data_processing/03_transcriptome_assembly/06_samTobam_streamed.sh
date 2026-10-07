#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p main            # Partition: main (Puede dar Thin o Large nodes)
#SBATCH -c 18              # Cores: 18 (Para Samtools -@)
#SBATCH --mem=256GB        # Memoria: Esto forzará la asignación a un Large Node (456GB disponibles)
#SBATCH -t 24:00:00        # Tiempo: Máximo 24 horas en 'main'
#SBATCH -J samTobam_ticks  # Nombre del Job
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --array=1-16       # Array: 16 tareas (una por muestra)
#SBATCH --output=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam/logs/bam_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam/logs/bam_%A_%a.err

### Configuración
module load samtools/1.20

INPUT_DIR="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/hisat"
OUTPUT_DIR="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam"
LIST_FILE="$OUTPUT_DIR/libraries.txt"
REF_GENOME="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/data/genomes/I_ricinus/data/GCA/Iricinus_assembly_genomic.fna"

# --- Tarea de Array ---
SAMPLE_BASE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$LIST_FILE")

SAM_FILE="${INPUT_DIR}/${SAMPLE_BASE}.sam"
SORTED_BAM="${OUTPUT_DIR}/${SAMPLE_BASE}_sorted.bam"

if [[ ! -f "$SAM_FILE" ]]; then
    echo "ERROR: Archivo SAM no encontrado: $SAM_FILE. Revisar $LIST_FILE." >&2
    exit 1
fi

echo "--- Iniciando procesamiento para: $SAMPLE_BASE ---"

# 1. Convertir SAM a BAM y Ordenar en UN SOLO PASO (Usa -@ 17 para 17 threads de trabajo)
# NOTA: Usamos 17 threads porque el -c 18 de SLURM reserva 18 cores, 
# pero es común usar 17 para dejar 1 thread para la gestión general del proceso.
echo "Convirtiendo y ordenando $SAM_FILE a $SORTED_BAM..."
samtools view -@ 17 -b "$SAM_FILE" | samtools sort -@ 17 -o "$SORTED_BAM" -

# 2. Indexar BAM ordenado
echo "Indexando $SORTED_BAM..."
samtools index "$SORTED_BAM"

echo "Procesamiento de BAM finalizado para: $SAMPLE_BASE"
