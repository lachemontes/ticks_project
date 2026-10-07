# 05 — Expression quantification

## Purpose

Quantify receptor expression across tissues to test the paper's second main
claim: **appendage-restricted expression**. Sixteen libraries cover appendages
(the chemosensory organs — palps, tarsi with Haller's organ) against
rest-of-body, in both sexes. A receptor enriched in appendages and near-absent
elsewhere is a chemosensory candidate; one expressed uniformly is not.

**Quantification is restricted to a 98-transcript hybrid CDS set, not the whole
transcriptome.** This is deliberate and matters for interpretation:

- a receptor is quantified against the *best* available CDS for it, whichever
  assembly recovered it (81 from genome-guided StringTie, 17 only from
  *de novo* Trinity);
- TPMs are therefore **within-set relative abundances** — comparable across
  samples and across receptors in this set, but **not** comparable to
  whole-transcriptome TPMs, because the denominator is the receptor set alone.
  Report them as such.

## Scripts

Run in numeric order.

| Script | Tool | Description |
|--------|------|-------------|
| `18_hybrid_cds_builder.sh` | seqkit | Builds the 98-sequence hybrid CDS FASTA: 81 StringTie + 17 Trinity transcripts, pulled by ID list from the two TransDecoder CDS outputs. Verifies the count and reports any missing IDs |
| `19_kallisto_claudia.sh` | kallisto | Builds the index from the hybrid CDS — run **once** |
| `20_kallisto_quent.sh` | kallisto | Quantification, **unstranded** (array 1–16). The safe first pass |
| `20_kallisto_quent_fr-stranded.sh` | kallisto | Same with `--fr-stranded` |
| `20_kallisto_quent_RFstranded.sh` | kallisto | Same with `--rf-stranded` |

### On the three quantification scripts

All three exist because library strandedness was **determined empirically**, not
assumed. The procedure: run unstranded first, read `p_pseudoaligned` from
`run_info.json`, then run both stranded variants and keep whichever matches the
unstranded rate. The wrong strandedness setting roughly halves the
pseudoalignment rate, which is unmistakable in the logs. Each script prints its
own rate:

```
Pseudoalignment rate: 72.4% pseudoaligned (18,203,118 / 25,141,002 reads)
```

Compare across all three before choosing:

```bash
for d in analysis/kallisto{,/frstranded,/rfstranded}/*/; do
    printf '%-55s ' "$d"
    python3 -c "import json,sys; print(json.load(open('$d/run_info.json'))['p_pseudoaligned'])" 2>/dev/null || echo "-"
done
```

For the dUTP protocols typical of Illumina stranded mRNA kits, `--rf-stranded`
is the expected answer — but verify rather than assume, and state the chosen
setting in the methods.

## Input

| File | Source |
|------|--------|
| `analysis/transdecoder/genomeGuide_transdecoder/genomeGuide.transdecoder.cds` | [`../01_data_processing/03_transcriptome_assembly/`](../01_data_processing/03_transcriptome_assembly/) |
| `analysis/transdecoder/deNovo_transdecoder/deNovo.transdecoder.cds` | idem |
| `analysis/transdecoder/hybrid_CDS_STRG_ids.txt` | 81 StringTie IDs, one per line — manually curated |
| `analysis/transdecoder/hybrid_CDS_TRINITY_ids.txt` | 17 Trinity IDs |
| `data/trimmed_libs/<prefix>_R{1,2}_001_val_{1,2}.fq.gz` | [`../01_data_processing/01_qc_trimming/`](../01_data_processing/01_qc_trimming/) |
| `analysis/kallisto/kallisto_samples.txt` | Sample sheet, **tab-separated, 4 columns, no header** |

### `kallisto_samples.txt`

One line per library; `SLURM_ARRAY_TASK_ID` indexes it directly, so it must have
exactly 16 lines in the array's order.

```
file_prefix<TAB>sample_name<TAB>tissue<TAB>sex
P12345_101_S1_L001	F1	appendages	F
P12345_102_S2_L001	F1	body	F
...
```

`file_prefix` must reproduce the trimmed filename exactly — the scripts append
`_R1_001_val_1.fq.gz`. Output directories are named `<sample_name>_<tissue>`, so
those two columns together must be unique.

## Output

| File | Content |
|------|---------|
| `analysis/kallisto/hybrid_CDS_receptors.fasta` | The 98-sequence hybrid CDS |
| `analysis/kallisto/hybrid_CDS_full.idx` | kallisto index |
| `analysis/kallisto[/{fr,rf}stranded]/<sample>_<tissue>/abundance.tsv` | **The results table**: `target_id`, `length`, `eff_length`, `est_counts`, `tpm` |
| `.../abundance.h5` | Same plus bootstrap replicates (for sleuth) |
| `.../run_info.json` | `n_processed`, `n_pseudoaligned`, `p_pseudoaligned` — the diagnostic |

Assemble the TPM matrix for the heatmaps:

```bash
# One column per sample, rows = transcripts
paste <(cut -f1 analysis/kallisto/rfstranded/*/abundance.tsv | head -99) \
      $(for d in analysis/kallisto/rfstranded/*/; do echo "<(cut -f5 $d/abundance.tsv)"; done)
```

or, more robustly, in R with `tximport`.

## Software versions

| Tool | Version | Parameters |
|------|---------|------------|
| kallisto | 0.48.0 | `index`: defaults (*k* = 31); `quant`: `--threads 12`, paired-end, 16 libraries |
| seqkit | 2.3.1 | `grep -f` |

No bootstrap replicates were requested (`-b` is absent), so `abundance.h5`
carries point estimates only. Add `-b 100` if you intend to use sleuth for
differential testing.

## How to run

```bash
mkdir -p logs

# 1. Build the hybrid CDS  (check it reports 98 sequences)
sbatch 18_hybrid_cds_builder.sh

# 2. Index — once, after step 1 completes
sbatch 19_kallisto_claudia.sh

# 3. Quantify; start unstranded, then test both stranded variants
sbatch 20_kallisto_quent.sh
sbatch 20_kallisto_quent_RFstranded.sh
sbatch 20_kallisto_quent_fr-stranded.sh
```

Notes:

- **Index filename mismatch.** `19_kallisto_claudia.sh` writes
  `hybrid_CDS_full.idx` (from `hybrid_CDS_full.fasta`), while the two stranded
  scripts read `hybrid_CDS_receptors.idx` and `18_hybrid_cds_builder.sh` writes
  `hybrid_CDS_receptors.fasta`. **Reconcile these names before submitting** —
  point all three at one index, or the stranded runs fail on the missing-index
  check.
- `18_hybrid_cds_builder.sh` flags its `GG_CDS` / `DN_CDS` paths as needing
  adjustment (`⚠️` in the script). Confirm the actual TransDecoder output names
  first.
- The builder warns loudly if it does not recover exactly 98 sequences and lists
  the missing IDs — do not proceed past that warning.
- Downstream TPM analysis and heatmaps: [`../06_figures/`](../06_figures/).
