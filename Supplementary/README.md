# Supplementary material

Additional files submitted with the manuscript.

| File | Content | Produced from |
|------|---------|---------------|
| `additional_file_1_qc.xlsx` | Per-library read counts, trimming statistics, HISAT2 mapping rates, Kraken2 classification summary | [`../01_data_processing/`](../01_data_processing/) |
| `additional_file_2_annotation.xlsx` | Curated receptor table: IDs, family, best BLAST hit, percent identity, InterProScan domains, predicted TM helices, length, source assembly | [`../02_annotation/`](../02_annotation/) |
| `additional_file_3_phylogeny/` | Alignments (`*_mafft.fasta`), trees (`*.treefile`), IQ-TREE reports (`*.iqtree`) per family | [`../03_phylogeny/`](../03_phylogeny/) |
| `additional_file_4_expression.xlsx` | TPM matrix across the 16 libraries, plus the IR/iGluR glutamate-binding residue table | [`../05_expression/`](../05_expression/), [`../02_annotation/04_residue_analysis_IR/`](../02_annotation/04_residue_analysis_IR/) |

## Status

> The additional files are **not yet committed** — the manuscript is in
> preparation and these tables are still being revised. This README records the
> intended contents and provenance of each one.

## Notes for assembly

- **Record software versions in the files themselves**, not only in the per-step
  READMEs. Kraken2 results in particular depend on the database build date, and
  BUSCO scores on the `arthropoda_odb10` version — a version table alone does not
  make them reproducible.
- The TPM matrix must state the strandedness setting that was finally used, and
  that TPMs are relative **within the 98-transcript receptor set**, not
  whole-transcriptome values. See
  [`../05_expression/README.md`](../05_expression/README.md).
- Residue positions in the IR/iGluR table are indices into a **specific
  alignment**. Ship the alignment alongside the table, or the positions cannot be
  checked. See
  [`../02_annotation/04_residue_analysis_IR/README.md`](../02_annotation/04_residue_analysis_IR/README.md).
- Keep individual files under GitHub's 100 MB hard limit (50 MB triggers a
  warning). Large alignments and tree sets belong in a Zenodo deposit with a DOI
  cited from the paper, not in the repository.
