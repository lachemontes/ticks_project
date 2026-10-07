# Conservation of the S7b signature motif across chelicerate and insect GRs

Zaide Montes-Ortiz

> Analysis record for the GR motif discovery step. The runnable scripts in this
> folder implement exactly the command lines given below; see
> [`README.md`](README.md) for the folder's inputs, outputs and how to run it.

---

## Why I ran this

While working on the *Ixodes ricinus* GR repertoire I wanted to see whether the
C-terminal motif described for *Argiope bruennichi* was also present in ticks. The
tick analysis worked, so I extended it to a three-species comparison. The results
below refine rather than replace the *Argiope* analysis, and they resolve one point
that the original run could not settle.

---

## Software versions

| Tool | Version | Role |
|---|---|---|
| CD-HIT | 4.8.1 | redundancy reduction (Iric only) |
| MEME Suite | 5.5.5 | motif discovery, comparison, scanning |
| └─ `fasta-shuffle-letters` | 5.5.5 | shuffled negative control |
| └─ `meme` | 5.5.5 | motif discovery |
| └─ `tomtom` | 5.5.5 | motif-to-motif similarity |
| └─ `fimo` | 5.5.5 | motif-to-sequence scanning |
| GNU grep | 3.7 | literal pattern search |

---

## Datasets

| Species | Raw GRs | Post CD-HIT | Source |
|---|---:|---:|---|
| *I. ricinus* | 71 | **65** | This study (curated BMC set) |
| *A. bruennichi* | 368 | ~330 | Montes-Ortiz et al. 2026 (368-seq file, not full 490) |
| *D. melanogaster* | 68 | 68 (no reduction) | FlyBase r6.54 |

**Only the *I. ricinus* set was reduced with CD-HIT.** The spider and fly sets
were already non-redundant and passed through unchanged. Reducing them further
would have deleted biologically real paralogues.

---

## Full command lines

### Step 1 — CD-HIT redundancy reduction (Iric only)

```bash
cd-hit \
    -i Iric_GR.fasta \
    -o Iric_GR_nr90.fasta \
    -c 0.90 \
    -n 5 \
    -M 0 \
    -T 8 \
    -d 0
```

**Parameters:**

| Flag | Value | Meaning |
|---|---|---|
| `-i` | `Iric_GR.fasta` | input (71 curated IricGR proteins) |
| `-o` | `Iric_GR_nr90.fasta` | output (65 non-redundant sequences) |
| `-c` | `0.90` | **90% identity threshold** — collapses recent tandem duplicates that would otherwise dominate MEME output |
| `-n` | `5` | word length (standard for 70-100% identity range) |
| `-M` | `0` | unlimited memory |
| `-T` | `8` | 8 CPU threads |
| `-d` | `0` | preserve full sequence headers (no truncation at first space) |

### Step 2 — Generate shuffled negative control

```bash
# For each species' input FASTA
for sp in Iric_GR_nr90 Abru_GR Dmel_GR; do
    fasta-shuffle-letters \
        -kmer 1 \
        -seed 42 \
        -dna false \
        ${sp}.fasta \
        ${sp}_shuffled.fasta
done
```

**Parameters:**

| Flag | Value | Meaning |
|---|---|---|
| `-kmer` | `1` | shuffle single residues (preserves amino acid composition exactly) |
| `-seed` | `42` | fixed random seed — reproducible shuffle, same control every run |
| `-dna` | `false` | treat input as protein |

**Why this control matters:** without `-objfun de` + negative control, MEME
returns motifs driven by amino acid composition bias (e.g., high-Leu regions in
TM helices). A composition-matched shuffled control is the only way to tell a
real conserved motif from a trivial compositional pattern.

### Step 3 — MEME motif discovery

The *I. ricinus* input is the CD-HIT-reduced file; *A. bruennichi* and
*D. melanogaster* use their unreduced sets (see Datasets above).

```bash
# Width = 12 (standalone core) — PRIMARY RESULT
for fa in Iric_GR_nr90 Abru_GR Dmel_GR; do
    sp=${fa%%_*}
    meme ${fa}.fasta \
        -neg ${fa}_shuffled.fasta \
        -objfun de \
        -protein \
        -mod zoops \
        -nmotifs 1 \
        -minw 6 \
        -maxw 12 \
        -evt 0.05 \
        -seed 42 \
        -p 8 \
        -oc meme_output/${sp}_maxw12
done

# Width = 50 (embedded in longer block) — COMPARISON WITH ORIGINAL ARGIOPE RUN
for fa in Iric_GR_nr90 Abru_GR Dmel_GR; do
    sp=${fa%%_*}
    meme ${fa}.fasta \
        -neg ${fa}_shuffled.fasta \
        -objfun de \
        -protein \
        -mod zoops \
        -nmotifs 1 \
        -minw 6 \
        -maxw 50 \
        -evt 0.05 \
        -seed 42 \
        -p 8 \
        -oc meme_output/${sp}_maxw50
done
```

**Parameters:**

| Flag | Value | Meaning |
|---|---|---|
| `-neg` | shuffled FASTA | negative control for `-objfun de` |
| `-objfun` | `de` | **differential enrichment** — scores motifs by their enrichment in positive vs. control. Alternative `classic` ignores composition bias |
| `-protein` | — | protein alphabet (not DNA) |
| `-mod` | `zoops` | **z**ero **o**r **o**ne occurrence **p**er **s**equence (standard for conserved domains that may be missing in some paralogues) |
| `-nmotifs` | `1` | find a single top motif only (we are asking whether *a* shared motif exists, not catalogue all motifs) |
| `-minw` | `6` | minimum motif width (6 residues) |
| `-maxw` | `12` or `50` | maximum motif width — see "Width setting" section below |
| `-evt` | `0.05` | E-value threshold for reporting motifs |
| `-seed` | `42` | fixed random seed for reproducibility |
| `-p` | `8` | 8 CPU threads (parallel MEME) |
| `-oc` | directory | output clobber (overwrite if exists) |

### Step 4 — TOMTOM cross-species motif comparison

```bash
# Tick vs spider
tomtom \
    -evalue \
    -thresh 10 \
    -min-overlap 5 \
    -dist pearson \
    -oc tomtom_output/Iric_vs_Abru \
    meme_output/Iric_maxw12/meme.txt \
    meme_output/Abru_maxw12/meme.txt

# Tick vs Dmel
tomtom \
    -evalue \
    -thresh 10 \
    -min-overlap 5 \
    -dist pearson \
    -oc tomtom_output/Iric_vs_Dmel \
    meme_output/Iric_maxw12/meme.txt \
    meme_output/Dmel_maxw12/meme.txt

# Spider vs Dmel
tomtom \
    -evalue \
    -thresh 10 \
    -min-overlap 5 \
    -dist pearson \
    -oc tomtom_output/Abru_vs_Dmel \
    meme_output/Abru_maxw12/meme.txt \
    meme_output/Dmel_maxw12/meme.txt
```

**Parameters:**

| Flag | Value | Meaning |
|---|---|---|
| `-evalue` | — | report E-values (default is q-values, which are unreliable here — see Caveats) |
| `-thresh` | `10` | permissive threshold to see all alignments; filter afterwards by p-value |
| `-min-overlap` | `5` | minimum overlap of 5 positions between motifs |
| `-dist` | `pearson` | Pearson correlation as similarity metric |
| `-oc` | directory | output clobber |

### Step 5 — FIMO cross-scanning

```bash
# Scan tick motif against each D. melanogaster GR
fimo \
    --oc fimo_output/Iric_motif_vs_Dmel_GRs \
    --thresh 0.05 \
    --qv-thresh \
    --max-stored-scores 100000 \
    meme_output/Iric_maxw12/meme.txt \
    Dmel_GR.fasta
```

**Parameters:**

| Flag | Value | Meaning |
|---|---|---|
| `--oc` | directory | output clobber |
| `--thresh` | `0.05` | significance threshold |
| `--qv-thresh` | — | **CRITICAL**: makes `--thresh` apply to the FDR-corrected **q-value**, not the raw p-value. Without this flag, reporting raw p-values across tens of thousands of positions means reporting noise |
| `--max-stored-scores` | `100000` | buffer for q-value calibration |

### Step 6 — Literal grep as sanity check

```bash
# Count D. melanogaster GRs matching the tick consensus pattern
grep -c -P 'TY[ILVFAM]{5}Q' Dmel_GR.fasta
# → 13

# Find exact matches to the closest literal variant
grep -B1 'TYMVILVQ' Dmel_GR.fasta
# → 2 sequences
```

**Pattern:** `TY[ILVFAM]{5}Q`

- `TY` — fixed Tyr-Tyr
- `[ILVFAM]{5}` — exactly 5 hydrophobic residues (I, L, V, F, A, M)
- `Q` — fixed terminal Gln

---

## The width setting turned out to matter

At `-maxw 50`, MEME returns the motif embedded in a longer conserved block. In
*A. bruennichi* it appears at the end of a 24-residue motif, `TAWGIFPLKRSLILSSFGTLLTYG`,
which terminates in TY. This is consistent with the original analysis, where the
recovered motif gave TY followed by four hydrophobic positions and the fifth had to
be read from the adjacent alignment position.

At `-maxw 12`, MEME is forced to isolate the conserved core and returns it as a
standalone motif:

| Species | Motif | Sites | E-value |
|---|---|---|---|
| *I. ricinus* | **TYTVILVQ** | 46 / 65 | **4.2 × 10⁻²⁰** |
| *A. bruennichi* | **TYGVIIYQ** | 35 standalone + 242 within motif 1 | **1.4 × 10⁻⁰⁸** |
| *D. melanogaster* | (variable) | — | not significant alone |

Both are eight residues: TY, five hydrophobic positions, terminal Q. The fifth
hydrophobic position falls inside the motif, so it no longer needs to be inferred
from the flanking alignment.

---

## Cross-species comparison — results

| Comparison | Method | Statistic |
|---|---|---|
| tick against spider | TOMTOM, offset 0, overlap 8/8 | **p = 9.4 × 10⁻⁰⁸** |
| tick against *D. melanogaster* | TOMTOM | **p = 2.0 × 10⁻⁰⁵** |
| spider against *D. melanogaster* | TOMTOM | **p = 5.6 × 10⁻⁰⁴** |
| tick motif scanned in *D. melanogaster* | FIMO, q < 0.05 | **40 / 68 GRs** |
| literal `TY[ILVFAM]{5}Q` in *D. melanogaster* | grep | **13 sequences** |

The tick and spider motifs align position for position with no offset across their
full width.

The closest literal match in *D. melanogaster* is **TYMVILVQ**, present in two
sequences, which differs from the tick consensus at one conservative position
(T → M).

**Coverage** is comparable across the three repertoires:

| Species | Coverage |
|---|---:|
| *I. ricinus* | **71 %** (46/65) |
| *A. bruennichi* | **84 %** |
| *D. melanogaster* | **59 %** (40/68 by FIMO) |

The lower figure for *D. melanogaster* is expected, since the scanning model was
trained on tick sequences.

---

## What this changes for the *Argiope* section

Two points, both minor and both improvements.

**1 — The fifth hydrophobic position no longer needs to be read from outside the motif.**
The current text states that the adjacent alignment position was examined and found
to be predominantly hydrophobic. With the shorter width setting this position is
recovered inside the motif, so the observation stands on the MEME output alone.

**2 — The Q position is better conserved than the wider window suggested.** In the
`-maxw 12` run the terminal Q appears in the consensus for both species, and in the
tick it is present in 100% of sites. The variability at that position described for
*Argiope* is real, but it looks like variation within a conserved signature rather
than loss of it.

**One consequence for the interpretation.** The current text concludes that the motif
supports both the annotation of the *Argiope* GRs and their divergence from insect
GRs. The first half is strengthened by these results. The second may need
qualifying: the spider motif matches *D. melanogaster* motifs directly, and 13
*D. melanogaster* sequences carry the pattern in close to exact form. The QF
variability is genuine, but the overall picture is conservation across roughly 500
million years rather than divergence.

---

## Caveats

- **TOMTOM q-values are unreliable here.** The target databases contain only 10 to
  15 motifs each, and TOMTOM warns that it cannot estimate `pi_0` (the proportion
  of true null hypotheses). The reported **p-values are usable** because they
  depend only on the alignment statistics; the **q-values are not**, because the
  FDR correction requires a well-estimated null distribution that a 10-motif
  database cannot provide. **Report p-values only.**

- **FIMO q-values are fine**, since `pi_0` was estimated from 10,000+ scanned
  p-values (one per position × sequence combination). The `--qv-thresh` flag is
  what makes this work — without it, FIMO would report raw p-values.

- **An earlier run without a negative control** returned E-values of 1 × 10⁻⁶⁸¹
  to 1 × 10⁻⁹⁵⁶. Those were inflated by non-independence among paralogues (recent
  duplicates share composition and local sequence), and are **not reported**.
  Always run `-objfun de` + shuffled control for protein motif discovery in gene
  families with recent duplicates.

- **The *A. bruennichi* set** used here is the 368-sequence file, not the full
  490-sequence catalogue. Re-running on the full set is unlikely to change the
  conclusion (the motif is already recovered in 84% of 330 non-redundant
  sequences), but if you want strict comparability, use the 368-sequence file.

- **Reproducibility:** every random step uses `-seed 42`. Changing this seed
  will produce slightly different shuffled controls and MEME starting conditions,
  but the recovered motifs should be stable within ±1 position.

---

## File inventory

```
meme_output/
├── Iric_maxw12/
│   ├── meme.txt          ← primary input for TOMTOM and FIMO
│   ├── meme.html         ← human-readable report with sequence logo
│   ├── meme.xml          ← machine-readable
│   └── logo1.png         ← the TYTVILVQ sequence logo
├── Iric_maxw50/          ← comparison run (24-residue embedded motif)
├── Abru_maxw12/          ← TYGVIIYQ
├── Abru_maxw50/
└── Dmel_maxw12/

tomtom_output/
├── Iric_vs_Abru/
│   └── tomtom.html       ← alignment with p-values
├── Iric_vs_Dmel/
└── Abru_vs_Dmel/

fimo_output/
└── Iric_motif_vs_Dmel_GRs/
    ├── fimo.html         ← per-sequence matches
    └── fimo.tsv          ← tab-separated hits with q-values
```

---

## Quick-start reproduction

```bash
# From the project root
cd 02_annotation/03_motif_discovery_GR
mkdir -p logs meme_output tomtom_output fimo_output

# Submit in order (wait between steps)
sbatch meme_motif_discovery.sh   # ~30 min
# wait, then:
sbatch tomtom_cross_species.sh   # ~5 min
sbatch fimo_scan.sh              # ~5 min

# Check that MEME found something significant
grep -A2 'MOTIF' meme_output/Iric_maxw12/meme.txt | head -20
# Expected: TYTVILVQ with E-value 4.2e-20
```
