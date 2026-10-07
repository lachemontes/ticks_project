# 02.02 — InterProScan domain annotation

## Purpose

Independent, homology-free confirmation that each BLAST candidate carries the
domain architecture of its assigned family — the second of the three curation
filters described in [`../README.md`](../README.md).

The `TMHMM` application is included because topology is diagnostic here:
IRs and iGluRs have three transmembrane helices with a large extracellular
N-terminal region, while GRs are 7TM receptors with an **inverted** topology
(intracellular N-terminus). Candidates whose predicted topology contradicts the
BLAST-assigned family were flagged for manual inspection.

## Scripts

| Script | Target | Description |
|--------|--------|-------------|
| `09_InterPro_2.sh` | Whole *de novo* proteome | Annotates `transcripts_final_busco_inter_pep_98_denovo.fasta`; the broad pass that supplies GO terms for the full peptide set |
| `09_interpro_claudia.sh` | Curated receptor set | Loops over the files in `QUERIES`, skipping any whose `.tsv` already exists; adds GFF3 output. Currently set to `iqtree_final_80iric_phylo2026_zm.fasta` (the 80-receptor alignment input) |

`09_interpro_claudia.sh` is the one to edit when adding a new receptor set — append
to the `QUERIES` array.

## Input

- `analysis/cd-hit/de_novo/transcripts_final_busco_inter_pep_98_denovo.fasta`
  — from [`../../01_data_processing/03_transcriptome_assembly/`](../../01_data_processing/03_transcriptome_assembly/)
- `data/phylo/iqtree_final_80iric_phylo2026_zm.fasta` — curated receptor set
  from [`../01_blast_curation/`](../01_blast_curation/)

Protein FASTA only (`-t p`). **Strip trailing `*` stop characters first** —
InterProScan rejects them. `07_cd-hit_2.sh` already does this for the *de novo*
set.

## Output

| File | Content |
|------|---------|
| `analysis/interpro/de_novo/Iric_de_novo_interPro.tsv` | Tabular matches: accession, signature, start–end, e-value, InterPro entry, GO terms |
| `analysis/interpro/de_novo/Iric_de_novo_interPro.xml` | Full hierarchical output |
| `analysis/interpro/<set>_interpro_iGluR_IRs_2208.{tsv,xml,gff3}` | Per-receptor-set annotation |

## Diagnostic signatures

| Family | Signature | Name |
|--------|-----------|------|
| IR / iGluR | `PF00060` | Lig_chan (ligand-gated ion channel) |
| iGluR | `PF01094` | ANF_receptor (periplasmic binding fold, N-terminal domain) |
| GR | `PF08395` | 7tm_7 (insect gustatory receptor) |
| PPK | `PF00858` | ASC (amiloride-sensitive sodium channel / DEG-ENaC) |
| TRP | `PF00520` | Ion_trans |

Pull them out of the TSV directly:

```bash
# All IR/iGluR candidates carrying the Lig_chan domain
awk -F'\t' '$5=="PF00060" {print $1}' Iric_de_novo_interPro.tsv | sort -u

# Transmembrane helix count per sequence
awk -F'\t' '$4=="TMHMM" {c[$1]++} END {for (s in c) print s"\t"c[s]}' *.tsv
```

## Software versions

| Tool | Version | Parameters |
|------|---------|------------|
| InterProScan | 5.52-86.0 | `-t p -goterms --cpu 8` |

Applications: `PANTHER,CDD,Pfam,SUPERFAMILY,TMHMM`
Formats: `TSV,XML` (`09_InterPro_2.sh`) / `TSV,XML,GFF3` (`09_interpro_claudia.sh`)

The application subset is deliberate — the full default set (which adds
SignalP, PRINTS, ProSite, Gene3D, …) takes several times longer and adds nothing
for these families.

## How to run

```bash
mkdir -p logs
sbatch 09_InterPro_2.sh          # whole proteome: ~24-48 h, 8 cores, 30 GB
sbatch 09_interpro_claudia.sh    # curated set:    ~1-2 h,  8 cores, 40 GB
```

Notes:

- Both scripts load `InterProScan/5.52-86.0` via `module`. The PANTHER and
  TMHMM data files must be installed in the InterProScan distribution — on a
  fresh install, run `python3 setup.py -f interproscan.properties` once.
- `09_interpro_claudia.sh` **skips any query whose `.tsv` already exists.**
  Delete the output to force a re-run.
- The whole-proteome run is the long pole of the annotation step. Submit it early
  and continue with the BLAST curation while it finishes.
