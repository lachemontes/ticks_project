#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p shared
#SBATCH -c 8
#SBATCH --mem=120GB
#SBATCH -t 1-00:00:00
#SBATCH -J busco_ticks
#SBATCH --array=9
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH -o /cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/busco/logs/busco_%A_%a.out

# Load conda
#source $HOME/miniconda3/etc/profile.d/conda.sh
#conda activate BUSCO

# Paths
BASE_DIR=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks
GENOME_DIR=$BASE_DIR/data/genomes
OUTPUT_DIR=$BASE_DIR/analysis/busco
SPECIES_LIST=$BASE_DIR/scripts/tick_species_list.txt

# Get species for current task
SPECIES=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" $SPECIES_LIST)

# Find .fna file inside data/ and any subdirectories (like GCA_*/ or GCF_*/)
# Usamos -mindepth 1 para asegurarnos de buscar *dentro* de 'data'
# Y ajustamos -maxdepth si es necesario, pero sin él, buscará recursivamente.
# Para este caso, solo buscar recursivamente es lo más seguro.
FASTA=$(find "$GENOME_DIR/$SPECIES/data" -type f -name "*_genomic.fna" | head -n 1)

# Check if the file was found
if [[ ! -f "$FASTA" ]]; then
    echo "ERROR: No .fna file found for $SPECIES in $GENOME_DIR/$SPECIES/data/" >&2
    exit 1
fi

# Output folder for this species
OUT_SPECIES="$OUTPUT_DIR/$SPECIES"
mkdir -p "$OUT_SPECIES"

# Run BUSCO
# Importante: el -o debe ser el prefijo del nombre del archivo de salida dentro del --out_path
# En tu caso, $SPECIES ya es el nombre de la carpeta de salida, así que el -o debería ser solo un prefijo,
# o si quieres que el resultado final sea A_maculatum/run_A_maculatum, entonces está bien.
# El error no está aquí, pero es una buena práctica aclararlo.
busco -i "$FASTA" \
      -l arthropoda_odb10 \
      -o "$SPECIES" \
      -m genome \
      -c 8 \
      --out_path "$OUT_SPECIES"
