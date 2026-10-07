# 02.04 — IR / iGluR glutamate-binding residue analysis

## Purpose

Separate true **ionotropic receptors (IRs)** from **ionotropic glutamate
receptors (iGluRs)** on functional rather than phylogenetic grounds.

iGluRs bind glutamate through a conserved set of residues in the S1/S2 lobes of
the ligand-binding domain. IRs evolved from iGluRs but lost glutamate binding —
the diagnostic residues are substituted. Because BLAST identity between a
divergent IR and an iGluR can be high enough to be ambiguous, and because
phylogenetic placement alone can be driven by long-branch artefacts, the residue
state at these specific alignment positions is the decisive criterion used in
the paper.

## Contents

| File | Description |
|------|-------------|
| `Residues_iGluRs_IRs.ipynb` | Reads a MAFFT alignment, scores each sequence at the diagnostic positions, exports an Excel table |

## Method

The notebook checks **five alignment columns** against expected residues:

| Position (current alignment) | Expected | Role |
|------|----------|------|
| 391 | `R` | Arginine — binds the glutamate α-carboxyl group |
| 455 | `T` / `S` | S1 lobe hydroxyl contact |
| 455 | `S` / `T` | (same column, both orders accepted) |
| 496 | `D` / `E` | Acidic residue binding the glutamate α-amino group |
| 496 | `E` / `D` | (same column, both orders accepted) |

A sequence matching at all positions is scored as a **glutamate-binding iGluR**;
substitutions at the arginine or the acidic position indicate an **IR**.

> **Positions are alignment-specific, not absolute.** Column indices shift
> whenever the alignment is rebuilt or sequences are added or removed. The
> notebook keeps the earlier sets commented out as a record:
>
> | Alignment | Positions |
> |-----------|-----------|
> | 1 | 537, 717, 717, 748, 748 |
> | 2 | 1093, 1403, 1403, 1468, 1468 |
> | 3 | 551, 742, 742, 787, 787 |
> | **current** | **391, 455, 455, 496, 496** |
>
> **If you re-align, you must re-derive these indices** — locate the residues in
> a reference iGluR (e.g. *D. melanogaster* GluRIIA or rat GluA2) and read off its
> aligned column numbers. Do not reuse the values above with a different alignment.

## Input

- `aln_soft_resudues2.fasta` — MAFFT alignment of the IR/iGluR set, including the
  *D. melanogaster* and *A. bruennichi* references that anchor the positions.
  Produced by [`../../03_phylogeny/`](../../03_phylogeny/).

Place it in the same directory as the notebook, or edit `alignment_file` in cell 2.

## Output

- `residues_iGluR_IRsZAIDE.xlsx` — one row per sequence: ID, sequence, and the
  residue found at each diagnostic position.
- The same table printed to stdout as TSV (cell 5), convenient for pasting into
  the supplementary material.

## Software

| Package | Version |
|---------|---------|
| Python | 3.11 |
| Biopython | 1.81 (`Bio.AlignIO`) |
| openpyxl | 3.1 |

```bash
conda create -n ticks_py python=3.11 biopython openpyxl pandas jupyter
conda activate ticks_py
```

## How to run

```bash
jupyter notebook Residues_iGluRs_IRs.ipynb
```

Execute cells in order. Cell 3 is the one to edit: set `positions` and
`expected_aa` for your alignment. Cell 2 (the commented-out historical position
sets) can be skipped.

Sanity check before trusting the output — the known iGluR references must come
back as matches at all five positions. If they do not, the column indices are
wrong for this alignment.
