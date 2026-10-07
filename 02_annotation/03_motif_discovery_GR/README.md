# 02.03 — GR motif discovery

## Purpose

Test whether the *Ixodes ricinus* gustatory receptors share a conserved
C-terminal motif, and whether that motif is detectable in the GR repertoires of a
non-tick chelicerate (*Argiope bruennichi*) and an insect (*Drosophila
melanogaster*).

The result is a conserved **eight-residue S7b signature** — TY, five hydrophobic
positions, terminal Q — recovered independently in tick and spider and detectable
in *Drosophila*:

| Species | Motif | Sites | E-value | Coverage |
|---------|-------|-------|---------|---------:|
| *I. ricinus* | **TYTVILVQ** | 46 / 65 | 4.2 × 10⁻²⁰ | 71 % |
| *A. bruennichi* | **TYGVIIYQ** | 35 standalone + 242 within motif 1 | 1.4 × 10⁻⁰⁸ | 84 % |
| *D. melanogaster* | variable | — | not significant alone | 59 % (by FIMO) |

**Full analysis record, with every parameter justified and the results in
context: [`ANALYSIS.md`](ANALYSIS.md).** Read that before changing anything here.

## Scripts

| Script | Tools | Description |
|--------|-------|-------------|
| `meme_motif_discovery.sh` | CD-HIT, `fasta-shuffle-letters`, MEME | CD-HIT on *I. ricinus* only, shuffled controls, then MEME at **two widths** (`-maxw 12` primary, `-maxw 50` for comparison) |
| `tomtom_cross_species.sh` | TOMTOM | All **three** pairwise motif comparisons: Iric↔Abru, Iric↔Dmel, Abru↔Dmel |
| `fimo_scan.sh` | FIMO, grep | Scans the Iric motif against the *Dmel* GRs at *q* < 0.05, then an independent literal-pattern check |

Run them in that order — each consumes the previous one's output.

## The three design choices that matter

**1 — CD-HIT on *I. ricinus* only (`-c 0.90`).** Tick GRs include recent tandem
duplicates; without reduction MEME recovers a motif driven entirely by one
expanded clade, i.e. a within-clade signature mistaken for a family-wide one. The
*A. bruennichi* and *D. melanogaster* sets are already non-redundant and pass
through **unchanged** — reducing them would delete biologically real paralogues.

**2 — A composition-matched negative control (`-objfun de -neg`).** `-kmer 1
-seed 42` shuffling preserves amino-acid composition and length distribution
exactly, so a motif cannot be a composition artefact (high-Leu TM helices, for
instance). The fixed seed makes the control reproducible.

> An earlier run **without** a negative control returned E-values of 10⁻⁶⁸¹ to
> 10⁻⁹⁵⁶. Those were inflated by non-independence among paralogues and are not
> reported. For protein motif discovery in a gene family with recent duplicates,
> `-objfun de` plus a shuffled control is not optional.

**3 — Two width settings.** At `-maxw 50` the motif comes back embedded at the end
of a longer conserved block (in *A. bruennichi*, a 24-residue
`TAWGIFPLKRSLILSSFGTLLTYG` terminating in TY), which is what the original spider
analysis saw. At `-maxw 12` MEME is forced to isolate the conserved core and
returns it standalone, so the fifth hydrophobic position falls *inside* the motif
instead of having to be read off the flanking alignment. **`maxw12` is the primary
result**; `maxw50` is kept for comparability.

## ⚠️ Read p-values from TOMTOM, q-values from FIMO

The two tools are not alike here, and getting this backwards misreports the result.

| Tool | Use | Why |
|------|-----|-----|
| **TOMTOM** | **p-values only** | The target databases hold only 10–15 motifs each, so TOMTOM cannot estimate `pi_0` and warns about it. Its FDR correction is unreliable; the p-values depend only on the alignment statistics and are usable. `-evalue` moves the output off the q-value default |
| **FIMO** | **q-values** | `pi_0` is estimated from 10,000+ scanned p-values (one per position × sequence), so the FDR correction is well calibrated. `--qv-thresh` is what makes `--thresh 0.05` apply to the q-value rather than the raw p-value |

Without `--qv-thresh`, FIMO reports raw p-values across tens of thousands of
positions — which is reporting noise.

## Results

| Comparison | Method | Statistic |
|------------|--------|-----------|
| tick vs. spider | TOMTOM, offset 0, overlap 8/8 | **p = 9.4 × 10⁻⁰⁸** |
| tick vs. *D. melanogaster* | TOMTOM | **p = 2.0 × 10⁻⁰⁵** |
| spider vs. *D. melanogaster* | TOMTOM | **p = 5.6 × 10⁻⁰⁴** |
| tick motif scanned in *D. melanogaster* | FIMO, *q* < 0.05 | **40 / 68 GRs** |
| literal `TY[ILVFAM]{5}Q` in *D. melanogaster* | grep | **13 sequences** |

Tick and spider motifs align position for position with **no offset** across the
full eight residues. The closest literal *Drosophila* match is **TYMVILVQ** in two
sequences — one conservative substitution (T → M) from the tick consensus.

The lower *D. melanogaster* coverage is expected: the scanning model was trained
on tick sequences.

> **Interpretation.** The motif matches across tick, spider and fly, which points
> to conservation over roughly 500 My rather than chelicerate-specific divergence.
> See the closing section of [`ANALYSIS.md`](ANALYSIS.md) for what this changes in
> the *Argiope* text.

## Input

Protein FASTA, from [`../01_blast_curation/`](../01_blast_curation/). Set `IN_DIR`
if they are not in the working directory.

| File | Sequences | Source |
|------|----------:|--------|
| `Iric_GR.fasta` | 71 → **65** after CD-HIT | This study (curated BMC set) |
| `Abru_GR.fasta` | 368 (~330 non-redundant) | Montes-Ortiz *et al.* 2026 |
| `Dmel_GR.fasta` | 68 | FlyBase r6.54 |

> The *A. bruennichi* set is the **368-sequence** file, not the full 490-sequence
> catalogue. Use the same file for strict comparability.

## Output

| File | Content |
|------|---------|
| `Iric_GR_nr90.fasta` | CD-HIT-reduced tick set (65 seqs) |
| `*_shuffled.fasta` | Composition-matched negative controls |
| `meme_output/<SP>_maxw12/meme.txt` | **Primary motif** — PWM, E-value, site list. Input to TOMTOM and FIMO; do not delete |
| `meme_output/<SP>_maxw12/meme.html`, `logo1.png` | Report and sequence logo |
| `meme_output/<SP>_maxw50/` | Wider-window comparison run |
| `tomtom_output/<pair>/tomtom.tsv` | Motif–motif alignments with p, E, q, offset, orientation |
| `fimo_output/Iric_motif_vs_Dmel_GRs/fimo.tsv` | Per-sequence occurrences with q-values |

## Software versions

| Tool | Version |
|------|---------|
| CD-HIT | 4.8.1 |
| MEME Suite (`meme`, `tomtom`, `fimo`, `fasta-shuffle-letters`) | 5.5.5 |
| GNU grep | 3.7 |

Cite the MEME Suite as Bailey *et al.* (2015) *Nucleic Acids Res* 43:W39–W49.

## How to run

```bash
cd 02_annotation/03_motif_discovery_GR
mkdir -p logs meme_output tomtom_output fimo_output

sbatch meme_motif_discovery.sh   # ~30 min, 8 cores
# wait for it to finish, then:
sbatch tomtom_cross_species.sh   # ~5 min
sbatch fimo_scan.sh              # ~5 min
```

Check that MEME found something before going on:

```bash
grep -A2 'MOTIF' meme_output/Iric_maxw12/meme.txt | head -20
# expected: TYTVILVQ, E = 4.2e-20
```

A motif with E-value > 0.05 should not be carried forward, however good the logo
looks.

### Reproducibility

Every random step is seeded with `-seed 42`. Changing the seed produces slightly
different shuffled controls and MEME starting points; the recovered motifs should
be stable to within ±1 position.
