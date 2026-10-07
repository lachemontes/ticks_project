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
FINAL_GTF="${OUTPUT_DIR}/final_transcriptome_assembly_2.gtf" # Archivo de salida final

# Verificar si el BAM fusionado existe
if [[ ! -f "$MERGED_BAM" ]]; then
    echo "ERROR: Archivo BAM fusionado no encontrado: $MERGED_BAM" >&2
    echo "Asegúrate de ejecutar y finalizar el 'samtools merge' primero." >&2
    exit 1
fi

echo "--- Iniciando StringTie Genome-Guided Assembly sobre BAM fusionado ---"
echo "BAM de entrada: $MERGED_BAM"
echo "GTF de salida: $FINAL_GTF"

# 1. Ejecutar StringTie en el BAM fusionado
# Esto genera el ensamblaje de transcritos para todos los datos combinados.
# Opciones clave:
# -p 17 : número de threads (uno menos que el -c 18)
# -G $REF_GTF : Usar la anotación de referencia para guiar el ensamblaje.
# -o $FINAL_GTF : Archivo de salida GTF
stringtie "$MERGED_BAM" -p12 -o "$FINAL_GTF" -A gene_abundances.txt
    
# NOTA: Quité la opción -B (Ballgown) ya que no es útil sin las muestras individuales.

echo "Ensamblaje final de StringTie completado. El transcriptoma está en: $FINAL_GTF"
