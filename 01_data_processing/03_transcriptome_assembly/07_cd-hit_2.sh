#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p main
#SBATCH -c 4
#SBATCH --mem=15GB
#SBATCH -t 12:00:00
#SBATCH -J cd-hit
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/cd-hit/de_novo/logs/cd-hit_%A_%a.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/cd-hit/de_novo/logs/cd-hit_%A_%a.err

# Definir directorios
input_file="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/transcriptomes/Transcriptomes_2023_2024.fasta.transdecoder_fixname.pep"
output_dir="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/cd-hit/de_novo"
log_dir="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/cd-hit/de_novo/logs"

output_file_cd_hit="$output_dir/transcripts_cd-hit_98_denovo.pep"
final_fasta="$output_dir/transcripts_final_busco_inter_pep_98_denovo.fasta"

# Crear directorios de salida y logs si no existen
mkdir -p "$output_dir"
mkdir -p "$log_dir"

# Mensaje de inicio
echo "Ejecutando CD-HIT para eliminar redundancias en el archivo FASTA..."

# Ejecutar CD-HIT
cd-hit -i "$input_file" -o "$output_file_cd_hit" -c 0.98 -n 5 -M 0 -T 0

# Verificar si CD-HIT se ejecutó correctamente
if [[ $? -ne 0 ]]; then
    echo "Error en la ejecución de CD-HIT" >&2
    exit 1
fi

# Mensaje de éxito
echo "CD-HIT completado. Procesando archivo FASTA para limpieza adicional..."

# Remover redundancias y concatenar líneas de secuencias en una sola línea
awk '/^>/ {printf("\n%s\n",$0);next;} {printf("%s",$0);} END {printf("\n");}' "$output_file_cd_hit" | sed "1d" > "${output_file_cd_hit}_step1"

# Remover los asteriscos (*) en la secuencia
awk '/^>/ {print $1; next} 1' "${output_file_cd_hit}_step1" | sed 's/\*//g' > "${output_file_cd_hit}_step2"

# Remover todo lo que esté después del primer espacio en el header
awk '{print $1;next}1' "${output_file_cd_hit}_step2" > "$final_fasta"

# Mensaje final
echo "Procesamiento completado. Archivo final guardado en: $final_fasta"
