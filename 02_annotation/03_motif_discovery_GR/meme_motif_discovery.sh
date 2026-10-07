#!/bin/bash
#SBATCH -A naiss2023-23-109
#SBATCH -J meme_gr
#SBATCH -p shared
#SBATCH -n 8
#SBATCH -t 02:00:00
#SBATCH -o logs/meme_%j.out
#SBATCH -e logs/meme_%j.err

# ─────────────────────────────────────────────────────────
# MEME motif discovery on GR sequences
# ─────────────────────────────────────────────────────────
# Discovers conserved C-terminal motifs in gustatory receptors
# from I. ricinus, A. bruennichi, and D. melanogaster.
#
# Software: MEME Suite v5.5.5 (Bailey et al., 2015)
# ─────────────────────────────────────────────────────────

module load meme/5.5.5
module load cd-hit/4.8.1

PROJECT="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks"
INPUT_DIR="${PROJECT}/data/phylo/GR_sequences"
OUT_DIR="${PROJECT}/analysis/meme"
mkdir -p "$OUT_DIR" logs

# ─── For each species ───
for SPECIES in Iric Abru Dmel; do
    FASTA="${INPUT_DIR}/${SPECIES}_GR.fasta"
    OUT="${OUT_DIR}/${SPECIES}"
    mkdir -p "$OUT"
    
    # Step 1: CD-HIT reduction (90% identity for Iric only; others as-is)
    if [ "$SPECIES" = "Iric" ]; then
        cd-hit -i "$FASTA" -o "${OUT}/${SPECIES}_nr.fasta" -c 0.90 -n 5
        INPUT_FASTA="${OUT}/${SPECIES}_nr.fasta"
    else
        INPUT_FASTA="$FASTA"
    fi
    
    # Step 2: Generate shuffled control
    fasta-shuffle-letters -kmer 1 -seed 42 "$INPUT_FASTA" > "${OUT}/${SPECIES}_shuffled.fasta"
    
    # Step 3: MEME motif discovery
    meme "$INPUT_FASTA" \
        -neg "${OUT}/${SPECIES}_shuffled.fasta" \
        -objfun de \
        -protein \
        -nmotifs 1 \
        -maxw 12 \
        -oc "${OUT}/meme_run"
done

echo "MEME motif discovery complete. Results in: $OUT_DIR"
