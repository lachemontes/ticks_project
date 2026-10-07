#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p main
#SBATCH -c 18
#SBATCH --mem=256GB
#SBATCH -t 24-00:00:00
#SBATCH -J samTobam_mouth
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --array=1-16
#SBATCH --output=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam/logs/bam_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam/logs/bam_%A_%a.err

# Cargar el módulo de Samtools
module load samtools/1.20

# Definir rutas de directorios
input_dir="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/hisat"
output_dir="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam"
list_file="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/bam/libraries.txt"
log_dir="$output_dir/logs"

# Crear el directorio de logs si no existe
mkdir -p "$log_dir"

# Definir el genoma de referencia
ref_genome="/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/data/genomes/I_ricinus/data/GCA/Iricinus_assembly_genomic.fna"

# Obtener el nombre de la muestra para esta tarea
sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$list_file")

# Definir archivo SAM de entrada
sam_file="${input_dir}/${sample}.sam"

# Verificar si el archivo SAM existe
if [[ ! -f "$sam_file" ]]; then
    echo "ERROR: Archivo SAM no encontrado: $sam_file" >&2
    exit 1
fi

# Definir nombre de salida para los archivos BAM
bam_file="${output_dir}/${sample}.bam"
sorted_bam="${output_dir}/${sample}_sorted.bam"

# Convertir SAM a BAM con referencia
echo "Convirtiendo $sam_file a BAM..."
samtools view -@ 12 -Sb -T "$ref_genome" "$sam_file" -o "$bam_file"

# Ordenar BAM
echo "Ordenando $bam_file..."
samtools sort -@ 12 -o "$sorted_bam" "$bam_file"

# Indexar BAM ordenado
echo "Indexando $sorted_bam..."
samtools index "$sorted_bam"

# Eliminar archivos intermedios si es necesario
rm -f "$bam_file"

# Combinar todos los BAM ordenados en un solo archivo (solo en la primera tarea del array)
if [[ ${SLURM_ARRAY_TASK_ID} -eq 1 ]]; then
    echo "Fusionando archivos BAM..."
    merged_bam="${output_dir}/merged.bam"
    sorted_bam_files=(${output_dir}/*_sorted.bam)
    samtools merge -@ 12 "$merged_bam" "${sorted_bam_files[@]}"

    # Indexar BAM fusionado
    echo "Indexando archivo BAM fusionado..."
    samtools index "$merged_bam"
fi

echo "Conversión y procesamiento de BAM finalizado para: $sample"
