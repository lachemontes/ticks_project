#!/bin/bash
#SBATCH -A naiss2025-5-763
#SBATCH -p shared
#SBATCH -c 4
#SBATCH --mem=16GB
#SBATCH -t 01:00:00
#SBATCH -J hybrid_cds
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zaide.montes_ortiz@biol.lu.se
#SBATCH --output=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/transdecoder/hybrid_cds_%A.out
#SBATCH --error=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/transdecoder/hybrid_cds_%A.err

# ============================================================
# Build hybrid CDS FASTA for Kallisto index
# 98 Dandan-final transcripts (81 STRG + 17 TRINITY)
# ============================================================

set -eu

# ── Paths ─────────────────────────────────────────────────────────────────────
TD_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/transdecoder"

# Source CDS files from TransDecoder outputs
GG_CDS="${TD_DIR}/genomeGuide_transdecoder/genomeGuide.transdecoder.cds"
DN_CDS="${TD_DIR}/deNovo_transdecoder/deNovo.transdecoder.cds"
# ⚠️  Adjust these paths to your actual TransDecoder .cds output files

# ID lists (must be uploaded to the cluster)
STRG_IDS="${TD_DIR}/hybrid_CDS_STRG_ids.txt"
TRINITY_IDS="${TD_DIR}/hybrid_CDS_TRINITY_ids.txt"

# Outputs
OUT_STRG="${TD_DIR}/hybrid_CDS_STRG.fasta"
OUT_TRINITY="${TD_DIR}/hybrid_CDS_TRINITY.fasta"
OUT_FINAL="${TD_DIR}/hybrid_CDS_receptors.fasta"

module load bioinfo-tools seqkit

echo "================================================"
echo "Building hybrid CDS FASTA"
echo "Start: $(date)"
echo "================================================"

# Extract from genome-guided
echo ""
echo "[1/3] Extracting STRG transcripts from genome-guided CDS..."
seqkit grep -f "${STRG_IDS}" "${GG_CDS}" > "${OUT_STRG}"
N_STRG=$(grep -c ">" "${OUT_STRG}")
echo "     Extracted: ${N_STRG} STRG sequences (expected: 81)"

# Extract from de novo
echo ""
echo "[2/3] Extracting TRINITY transcripts from de novo CDS..."
seqkit grep -f "${TRINITY_IDS}" "${DN_CDS}" > "${OUT_TRINITY}"
N_TRINITY=$(grep -c ">" "${OUT_TRINITY}")
echo "     Extracted: ${N_TRINITY} TRINITY sequences (expected: 17)"

# Combine
echo ""
echo "[3/3] Combining into final hybrid CDS..."
cat "${OUT_STRG}" "${OUT_TRINITY}" > "${OUT_FINAL}"
N_FINAL=$(grep -c ">" "${OUT_FINAL}")
echo "     Final: ${N_FINAL} sequences (expected: 98)"

# Verification
echo ""
echo "================================================"
echo "VERIFICATION"
echo "================================================"

if [ "${N_FINAL}" -ne 98 ]; then
    echo "⚠️  WARNING: Expected 98 sequences, got ${N_FINAL}"
    echo "   Checking for missing IDs..."
    grep ">" "${OUT_FINAL}" | sed 's/>//' | awk '{print $1}' | sort > /tmp/found_ids.txt
    cat "${STRG_IDS}" "${TRINITY_IDS}" | sort > /tmp/expected_ids.txt
    echo "   Missing:"
    comm -23 /tmp/expected_ids.txt /tmp/found_ids.txt | sed 's/^/     /'
    rm -f /tmp/found_ids.txt /tmp/expected_ids.txt
else
    echo "✅ All 98 sequences successfully extracted."
fi

echo ""
echo "Output file: ${OUT_FINAL}"
echo "Size: $(ls -lh ${OUT_FINAL} | awk '{print $5}')"
echo "Done: $(date)"
echo "================================================"
