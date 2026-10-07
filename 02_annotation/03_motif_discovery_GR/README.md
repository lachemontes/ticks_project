# 02.03 — GR motif discovery

## ⚠️ Note on provenance

The three scripts in this folder were **reconstructed** from the MEME Suite HTML
reports and command lines recorded in the output directories; the original
submission scripts were lost. The parameters below are the ones in the surviving
`meme.html` / `tomtom.html` / `fimo.html` headers and reproduce the published
results.

## Purpose

Test whether the *I. ricinus* gustatory receptors share a conserved motif, and
whether that motif is detectable in the GR repertoires of a non-tick chelicerate
(*Argiope bruennichi*) and an insect (*Drosophila melanogaster*).

The logic is three steps:

1. **MEME** — discover a motif *de novo*, per species, against a shuffled
   background so that composition bias alone cannot produce a hit;
2. **TOMTOM** — ask whether the motif found in *I. ricinus* is the *same motif*
   as the ones found independently in the other two species;
3. **FIMO** — ask whether the *I. ricinus* motif occurs in individual
   *D. melanogaster* GR sequences, with per-sequence significance.

TOMTOM compares motifs to motifs; FIMO compares a motif to sequences. Both are
needed: TOMTOM establishes that the motifs correspond, FIMO establishes which
sequences actually carry it.

## Scripts

| Script | Tool | Description |
|--------|------|-------------|
| `meme_motif_discovery.sh` | CD-HIT + `fasta-shuffle-letters` + MEME | Per species: redundancy reduction (Iric only), shuffled control, then motif discovery |
| `tomtom_cross_species.sh` | TOMTOM | Iric motif vs. Abru motif; Iric motif vs. Dmel motif |
| `fimo_scan.sh` | FIMO | Iric motif scanned against the *D. melanogaster* GR repertoire |

## Exact parameters

### MEME

```
cd-hit -i <Iric_GR.fasta> -o <Iric_GR_nr.fasta> -c 0.90 -n 5       # Iric only
fasta-shuffle-letters -kmer 1 -seed 42 <input> > <shuffled>
meme <input> -neg <shuffled> -objfun de -protein -nmotifs 1 -maxw 12 -oc <outdir>
```

| Parameter | Value | Why |
|-----------|-------|-----|
| `-objfun de` | differential enrichment | Scores the motif against the `-neg` set instead of a zero-order background; required for the shuffled-control design |
| `-neg` | 1-mer shuffled input, `-seed 42` | Preserves amino-acid composition and length distribution exactly, so a hit cannot be a composition artefact. The fixed seed makes the control reproducible |
| `-protein` | — | Protein alphabet |
| `-nmotifs 1` | 1 | One motif per species — the question is whether *a* shared motif exists, not an exhaustive catalogue |
| `-maxw 12` | 12 | Upper bound on motif width |
| CD-HIT `-c 0.90` | 90 % identity, **Iric only** | *I. ricinus* GRs include recent tandem duplicates; without this, MEME recovers a motif driven by a single expanded clade. Abru and Dmel sets are already non-redundant and are passed through unchanged |

### TOMTOM

```
tomtom -oc <outdir> <query_meme.txt> <target_meme.txt>
```

Run twice: Iric vs. Abru, Iric vs. Dmel. Defaults otherwise
(`-dist pearson`, `-thresh 0.5` on *q*-value — read the reported *q* per match
rather than relying on the threshold).

### FIMO

```
fimo --oc <outdir> --thresh 0.05 --qv-thresh <meme.txt> <Dmel_GR.fasta>
```

`--qv-thresh` makes `--thresh` apply to the **q-value**, so this reports matches
at ***q* < 0.05** — FDR-corrected across all sequence positions scanned, not a
raw *p*-value cutoff.

## Input

- `data/phylo/GR_sequences/Iric_GR.fasta` — curated *I. ricinus* GRs
- `data/phylo/GR_sequences/Abru_GR.fasta` — *Argiope bruennichi* GRs
- `data/phylo/GR_sequences/Dmel_GR.fasta` — *D. melanogaster* GRs

All three are protein FASTA, from [`../01_blast_curation/`](../01_blast_curation/).
Set `PROJECT` at the top of each script to your project root.

## Output

| File | Content |
|------|---------|
| `analysis/meme/<species>/meme_run/meme.{txt,html,xml}` | Discovered motif: PWM, E-value, site list |
| `analysis/meme/<species>/<species>_nr.fasta` | CD-HIT-reduced input (Iric) |
| `analysis/meme/<species>/<species>_shuffled.fasta` | Shuffled control |
| `analysis/tomtom/Iric_vs_{Abru,Dmel}/tomtom.{tsv,html}` | Motif–motif matches with *p*, *E*, *q*, offset, orientation |
| `analysis/fimo/Iric_motif_vs_Dmel_GRs/fimo.{tsv,html}` | Per-sequence motif occurrences with *p* and *q* |

`meme.txt` is the input for both TOMTOM and FIMO — do not delete it.

## Software versions

| Tool | Version |
|------|---------|
| MEME Suite (`meme`, `tomtom`, `fimo`, `fasta-shuffle-letters`) | 5.5.5 |
| CD-HIT | 4.8.1 |

Cite as Bailey *et al.* (2015) *Nucleic Acids Res* 43:W39–W49.

## How to run

Strictly in order — each step consumes the previous one's output.

```bash
mkdir -p logs
sbatch meme_motif_discovery.sh     # ~30 min, 8 cores
# wait for completion, then:
sbatch tomtom_cross_species.sh     # ~5 min
sbatch fimo_scan.sh                # ~5 min
```

Check that MEME actually found something before running TOMTOM:

```bash
grep -A2 'MOTIF' analysis/meme/Iric/meme_run/meme.txt | head -20
```

A motif with E-value > 0.05 should not be carried forward.
