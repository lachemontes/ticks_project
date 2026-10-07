# 01.02 — Taxonomic classification

## Purpose

Screen the trimmed libraries for non-tick sequences before assembly.
*Ixodes ricinus* field and colony material routinely carries endosymbionts and
tick-borne bacteria (*Rickettsia*, *Borrelia*, *Midichloria*), and transcripts of
bacterial origin would otherwise be assembled and could be mistaken for
divergent receptor candidates.

Classification is used **diagnostically** — reads were *not* removed on the basis
of the Kraken2 assignment. The reported per-library fraction of non-arthropod
reads was low enough (see Additional file 1) that assembly proceeded on the full
trimmed set, and contamination was instead controlled at the protein level by the
BLAST reciprocity and InterProScan domain checks in
[`../../02_annotation/`](../../02_annotation/).

## Scripts

| Script | Tool | Description |
|--------|------|-------------|
| `kraken2.sh` | Kraken2 | *k*-mer classification of paired trimmed reads against the standard database |

## Input

- `data/trimmed_libs/<sample>_val_1.fq.gz` / `_val_2.fq.gz` — from
  [`../01_qc_trimming/`](../01_qc_trimming/)
- Kraken2 **standard database** (NCBI RefSeq archaea, bacteria, viral, plasmid,
  human, UniVec_Core). Set `DB` at the top of the script to your local copy.

## Output

| File | Content |
|------|---------|
| `data/kraken2_output/<sample>.kraken2.report` | Hierarchical report: % reads and read counts per taxon — this is the file you read |
| `data/kraken2_output/<sample>.kraken2.out` | Per-read classification (large; gitignored) |

## Software versions

| Tool | Version |
|------|---------|
| Kraken2 | 2.1.3 |

Database: Kraken2 standard, built 2024. Note that Kraken2 results are **not
comparable across database builds** — report the build date alongside the
version in any methods section.

## How to run

```bash
mkdir -p logs
# Set DB to your Kraken2 standard database path first.
sbatch kraken2.sh    # ~4 h, 16 cores, 64 GB  (the DB is held in RAM)
```

Memory is the binding constraint: the standard database needs ~50 GB resident.
If your allocation is smaller, use a capped database (`--max-db-size`) or
Kraken2's standard-8 / standard-16 prebuilt indices and say so in the methods.

### Summarising across libraries

```bash
# Fraction of reads assigned outside Arthropoda, per library
for f in data/kraken2_output/*.report; do
    echo -ne "$(basename $f .kraken2.report)\t"
    awk -F'\t' '$4=="U" {u=$1} END {print 100-u"% classified"}' "$f"
done
```
