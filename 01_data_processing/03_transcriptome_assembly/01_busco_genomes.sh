#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p shared
#SBATCH -c 8
#SBATCH --mem=120GB
#SBATCH -t 5-00:00:00
#SBATCH -J busco_ticks
#SBATCH --array=0,2-6
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH -o /cfs/klemming/projects/supr/naiss2025-23-132/Ticks/analysis/busco/logs/busco_%A_%a.out

module load bioinfo-tools
module load BUSCO/6.0.0
module load augustus/3.4.0



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


# Run BUSCO using the module's lineage sets
run_BUSCO.py -i "$FASTA" \
      -l $BUSCO_LINEAGE_SETS/arthropoda_odb10 \
      -o "$SPECIES" \
      -m genome \
      -c 8 \
      --out_path "$OUT_SPECIES"

