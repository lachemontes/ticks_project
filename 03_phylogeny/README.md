# 03 — Phylogenetic analysis

## Purpose

Reconstruct maximum-likelihood gene trees for each receptor family, together with
*D. melanogaster* and *Argiope bruennichi* references. These trees are the basis
for the paper's central claim of **ancestral clustering**: the *I. ricinus*
receptors do not form one lineage-specific expansion but distribute across
clades that already contain the chelicerate and insect references.

Including *A. bruennichi* (a spider) is what makes that inference possible —
with *Drosophila* alone, every tick clade would appear lineage-specific by
construction.

## Scripts

| Script | Tool | Description |
|--------|------|-------------|
| `14_phylotree.sh` | MAFFT + IQ-TREE | SLURM array: alignment, then model selection and ML tree with bootstrap, one receptor family per array task |
| `tick_species_list.txt` | — | The 14 tick species, one per line; indexes the QUAST and BUSCO arrays in [`../01_data_processing/03_transcriptome_assembly/`](../01_data_processing/03_transcriptome_assembly/) |

### Array layout of `14_phylotree.sh`

| Task | Input FASTA | Output subdir | Prefix |
|------|-------------|---------------|--------|
| 0 | `GR_sequences_aa_phylo.fasta` | `GRs/` | `GR_phylo` |
| 1 | `PPK_sequences_aa.fasta` | `PPKs/` | `PPK_phylo` |
| 2 | `TRP_sequences_aa.fasta` | `TRPs/` | `TRP_phylo` |
| 3 | `IR_sequences_aa.fasta` | `IR_phylo/` | `IR_phylo` |

The committed script has `--array=3` (the IR tree, the last one re-run). Use
`sbatch --array=0-3 14_phylotree.sh` to build all four.

### `tick_species_list.txt`

```
A_americanum    A_maculatum     D_albipictus    D_andersoni
D_silvarum      D_variabilis    H_asiaticum     H_longicornis
I_persulcatus   I_ricinus       I_scapularis    O_turicata
R_microplus     R_sanguineus
```

14 species: 2 *Amblyomma*, 4 *Dermacentor*, 2 *Haemaphysalis*, 3 *Ixodes*,
1 *Ornithodoros* (the soft-tick outgroup, Argasidae), 2 *Rhipicephalus*.
Line order **is** the array index — appending is safe, reordering is not.

## Pipeline

```
FASTA  ──MAFFT --auto──►  alignment  ──IQ-TREE -m MFP -B 1000──►  tree
```

| Step | Command | Notes |
|------|---------|-------|
| 1 | `mafft --auto --thread 16 <in> > <aln>` | `--auto` picks the strategy from sequence number and length (L-INS-i for small sets, FFT-NS-2 for large). Skipped if the alignment file already exists |
| 2 | `iqtree -s <aln> -m MFP -merit BIC -B 1000 -T 16 --prefix <p> -redo` | ModelFinder Plus selects the substitution model by **BIC**, then infers the ML tree with 1000 **ultrafast** bootstrap replicates |

> **No alignment trimming.** There is no trimAl step: these receptors are
> divergent and the variable regions carry phylogenetic signal that
> gap-threshold trimming removes. IQ-TREE's rate-heterogeneity models absorb the
> site-rate variation instead. If you add trimming, say so — it changes the
> topology.

`-B` is ultrafast bootstrap (UFBoot), **not** the `-b` standard bootstrap. UFBoot
support values are differently calibrated: ≥ 95 % is the conventional threshold
for "well supported", against ≥ 70 % for standard bootstrap. Do not mix the two
scales when reading the figures.

## Input

In `data/phylo/`, protein FASTA, from
[`../02_annotation/01_blast_curation/`](../02_annotation/01_blast_curation/):

- `GR_sequences_aa_phylo.fasta`
- `PPK_sequences_aa.fasta`
- `TRP_sequences_aa.fasta`
- `IR_sequences_aa.fasta` (and the curated `IR_iGluR_final_80.fasta`)

Each must contain the *D. melanogaster* and *A. bruennichi* references in
addition to the tick sequences.

## Output

In `analysis/phylo/<subdir>/`:

| File | Content |
|------|---------|
| `<prefix>_mafft.fasta` | MAFFT alignment — also the input for [`../02_annotation/04_residue_analysis_IR/`](../02_annotation/04_residue_analysis_IR/) |
| `<prefix>.treefile` | ML tree, Newick, with UFBoot support — **load this into iTOL/FigTree** |
| `<prefix>.iqtree` | Full report: selected model, likelihoods, model-test table |
| `<prefix>.contree` | Consensus tree |
| `<prefix>.log` | IQ-TREE log |
| `<prefix>.ckp.gz` | Checkpoint (allows resuming without `-redo`) |

Read the selected model out of the report:

```bash
grep "Best-fit model" analysis/phylo/IR_phylo/IR_phylo.iqtree
```

## Software versions

| Tool | Version | Parameters |
|------|---------|------------|
| MAFFT | 7.520 | `--auto --thread 16` |
| IQ-TREE | 2.2.2.6 | `-m MFP -merit BIC -B 1000 -T 16 -redo` |

Both from the conda env `IQtree`.

## How to run

```bash
mkdir -p logs
sbatch --array=0-3 14_phylotree.sh    # ~6-24 h per task, 16 cores, 60 GB
```

Notes:

- **`-redo` overwrites previous results without warning.** Remove it if you want
  IQ-TREE to resume from `.ckp.gz` instead.
- MAFFT is skipped when `<prefix>_mafft.fasta` exists, so re-running only redoes
  the tree. Delete the alignment to force re-alignment.
- Trees were annotated and coloured in **iTOL v6** for the figures; the
  annotation files live in [`../06_figures/`](../06_figures/).
