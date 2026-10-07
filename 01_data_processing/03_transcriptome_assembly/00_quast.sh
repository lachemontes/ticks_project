#!/bin/bash
#SBATCH -A naiss2024-5-647
#SBATCH -p shared
#SBATCH -c 4
#SBATCH --mem=40GB
#SBATCH -t 5-00:00:00
#SBATCH -J quast_array
#SBATCH --array=0-13
#SBATCH -o logs/quast_%A_%a.out
#SBATCH -e logs/quast_%A_%a.err


# Load conda and activate QUAST environment

# Define paths
BASE_DIR=/cfs/klemming/projects/supr/naiss2025-23-132/Ticks/data/genomes
RESULTS_DIR=$BASE_DIR/quast_results
SPECIES_LIST=$BASE_DIR/tick_species_list.txt
LEVELS_FILE=$BASE_DIR/assembly_levels.tsv

# Get current species
SPECIES=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" $SPECIES_LIST)

# Get assembly level for this species (Chromosome, Scaffold, etc.)
LEVEL=$(grep -P "^$SPECIES\t" $LEVELS_FILE | cut -f2)

# Find genome FASTA (.fna)
FASTA_FILE=$(find "$BASE_DIR/$SPECIES/data" -type f -name "*_genomic.fna" | head -n 1)

# Decide QUAST flags
QUAST_FLAGS="--eukaryote"
if [[ "$LEVEL" != "Chromosome" ]]; then
    QUAST_FLAGS="$QUAST_FLAGS --fragmented"
fi

# Run QUAST
mkdir -p "$RESULTS_DIR/$SPECIES"
quast.py -t 4 -o "$RESULTS_DIR/$SPECIES" $QUAST_FLAGS "$FASTA_FILE"
