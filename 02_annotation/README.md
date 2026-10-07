# 02 — Receptor annotation and curation

Identification and curation of the chemosensory receptor repertoire of
*Ixodes ricinus*: ionotropic receptors (IRs) and ionotropic glutamate receptors
(iGluRs), gustatory receptors (GRs), pickpocket channels (PPKs) and transient
receptor potential channels (TRPs).

| Step | Folder | What it does |
|------|--------|--------------|
| 1 | [`01_blast_curation/`](01_blast_curation/) | Homology search against curated reference sets, best-hit selection, redundancy removal, sequence extraction |
| 2 | [`02_interproscan/`](02_interproscan/) | Domain validation (Pfam, PANTHER, CDD, SUPERFAMILY) and transmembrane topology |
| 3 | [`03_motif_discovery_GR/`](03_motif_discovery_GR/) | *De novo* motif discovery in GRs, cross-species motif comparison |
| 4 | [`04_residue_analysis_IR/`](04_residue_analysis_IR/) | Glutamate-binding residue scoring that separates IRs from iGluRs |

## Curation logic

A candidate enters the final set only if it clears all three filters:

1. **Homology** — reciprocal BLASTp against the curated *D. melanogaster* +
   *Argiope bruennichi* reference sets at `e < 1e-5`, best hit by percent identity.
2. **Domain architecture** — the family-diagnostic domain is present in
   InterProScan output (e.g. `PF00060` / Lig_chan for IRs and iGluRs,
   `PF08395` / 7tm_7 for GRs), and TMHMM predicts a plausible topology.
3. **Length** — sequences shorter than 200 aa are dropped as fragments
   (CD-HIT `-l 199`).

The IR/iGluR split is then resolved on the glutamate-binding residues, not on
BLAST identity — see [`04_residue_analysis_IR/`](04_residue_analysis_IR/).

The curated set that feeds the phylogeny is `IR_iGluR_final_80.fasta` (80
sequences), later extended to the 98-transcript hybrid CDS set used for
expression quantification.
