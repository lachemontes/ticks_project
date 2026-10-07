#!/bin/bash
# ============================================================
# Extract receptor sequences (CDS + protein) from Trinity and
# StringTie transcriptomes using seqkit, based on ID lists.
#
# seqkit must be available (activate your conda env first).
# ============================================================

set -eu

# ============================================================
# Paths
# ============================================================
LIST_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/transcriptomes"
OUT_DIR="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/receptores_seq"

# --- Trinity transcriptome ---
TRINITY_CDS="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/transcriptomes/Transcriptomes_2023_2024.fasta.transdecoder.cds"
TRINITY_PEP="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/data/transcriptomes/Transcriptomes_2023_2024.fasta.transdecoder.pep"

# --- StringTie transcriptome ---
STRG_CDS="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/transdecoder/transcripts.fasta.transdecoder.cds"
STRG_PEP="/cfs/klemming/projects/supr/naiss2023-23-109/Ticks/analysis/cd-hit/transcripts_final_busco_inter_pep.fasta"

# ============================================================
# Jobs: "LIST_FILE|SOURCE|RECEPTOR"
#   SOURCE = trinity | strg
# ============================================================
JOBS=(
    "GR_trinity.txt|trinity|GR"
    "PPKs_trinity.txt|trinity|PPK"
    "TRPs_trinity.txt|trinity|TRP"
    "GR_stg.txt|strg|GR"
    "PPKs_strg.txt|strg|PPK"
    "TRPs_str.txt|strg|TRP"
)

# ============================================================
# Setup
# ============================================================
mkdir -p "${OUT_DIR}"

echo "================================================"
echo "Extracting receptor sequences with seqkit"
echo "seqkit: $(seqkit version 2>/dev/null || echo 'NOT FOUND')"
echo "================================================"

# Helper: extract from one fasta given a list, print counts
extract() {
    local list="$1" fasta="$2" out="$3" label="$4"

    if [ ! -f "${fasta}" ]; then
        echo "    [ERROR] FASTA not found: ${fasta}"
        return 1
    fi

    # -f: pattern file (one ID per line). Exact ID match on the sequence name.
    seqkit grep -f "${list}" "${fasta}" > "${out}"

    local want got
    want=$(grep -c . "${list}")            # non-empty lines in the list
    got=$(grep -c '>' "${out}" || echo 0)  # sequences extracted
    echo "    ${label}: extracted ${got}/${want}  ->  $(basename ${out})"

    if [ "${got}" -lt "${want}" ]; then
        echo "      [NOTE] fewer sequences than IDs — some IDs did not match exactly."
        echo "             (see the *_missing.txt file to review)"
        # Report which IDs were not found
        comm -23 <(sort -u "${list}") \
                 <(grep '>' "${out}" | sed 's/^>//; s/ .*//' | sort -u) \
                 > "${out%.fasta}_missing.txt" 2>/dev/null || true
    fi
}

# ============================================================
# Main loop
# ============================================================
for JOB in "${JOBS[@]}"; do
    IFS='|' read -r LIST SOURCE RECEPTOR <<< "${JOB}"
    LIST_PATH="${LIST_DIR}/${LIST}"

    echo ""
    echo "--- ${RECEPTOR} (${SOURCE}) ---"

    if [ ! -f "${LIST_PATH}" ]; then
        echo "    [WARN] List not found, skipping: ${LIST_PATH}"
        continue
    fi

    echo "    IDs in list: $(grep -c . ${LIST_PATH})"

    # Pick the right transcriptome for this source
    if [ "${SOURCE}" = "trinity" ]; then
        CDS_FASTA="${TRINITY_CDS}"
        PEP_FASTA="${TRINITY_PEP}"
    else
        CDS_FASTA="${STRG_CDS}"
        PEP_FASTA="${STRG_PEP}"
    fi

    # Output names: <receptor>_<source>_cds.fasta / _pep.fasta
    OUT_CDS="${OUT_DIR}/${RECEPTOR}_${SOURCE}_cds.fasta"
    OUT_PEP="${OUT_DIR}/${RECEPTOR}_${SOURCE}_pep.fasta"

    extract "${LIST_PATH}" "${CDS_FASTA}" "${OUT_CDS}" "CDS"
    extract "${LIST_PATH}" "${PEP_FASTA}" "${OUT_PEP}" "PEP"
done

# ============================================================
# Summary
# ============================================================
echo ""
echo "================================================"
echo "Done. Output in: ${OUT_DIR}"
echo ""
ls -lh "${OUT_DIR}"/*.fasta 2>/dev/null
echo ""
echo "If any '*_missing.txt' files were created, review them —"
echo "they list IDs that did not match exactly (often a suffix"
echo "difference like -PA vs -RA, or extra text in the header)."
echo "================================================"
