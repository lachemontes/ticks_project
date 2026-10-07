# 04 — Chromosomal mapping

## Purpose

Place the curated receptors on the chromosome-level *I. ricinus* assembly
(**GCA_964199275.3**, IXRI_v3) to test whether the phylogenetic clusters
correspond to **physical tandem arrays** or are dispersed across the genome.

This is the step that distinguishes two very different histories behind the same
tree: a clade of similar receptors sitting in a tandem array on one chromosome
implies local duplication, while the same clade scattered across chromosomes
implies retention from an older, already-diversified ancestral set. The paper's
"ancestral clustering" conclusion rests on this distinction, so the mapping is
done against the chromosome-level assembly rather than the scaffold-level one
used for transcript assembly.

**miniprot** is used rather than BLAT/BLAST or exonerate because it is
splice-aware: it aligns a protein directly to genomic DNA across introns and
emits exon structure as GFF, which is what the ideogram needs.

## Scripts

| Script | Tool | Description |
|--------|------|-------------|
| `11_miniprot.sh` | samtools + miniprot | Indexes the genome, writes a chromosome-length table, then splice-aware-aligns a receptor protein set to the genome |

The script is written to be re-run per receptor family — edit the `CONFIG` block
at the top:

```bash
QUERY="${TICKS}/data/phylo/IR_iGluR_final_80.fasta"   # the set to map
LABEL="IR_80"                                          # goes into output filenames
```

Run it once per family (`IR_80`, `GR`, `PPK`, `TRP`), changing both lines.

## Input

- `data/phylo/IR_iGluR_final_80.fasta` — curated receptor proteins, from
  [`../02_annotation/01_blast_curation/`](../02_annotation/01_blast_curation/)
- `data/genomes/Iric_chromosome_ncbi_dataset/data/GCA_964199275.3/GCA_964199275.3_IXRI_v3_genomic.fna`
  — chromosome-level assembly

> Note the two different *I. ricinus* assemblies in this project:
> `Iricinus_assembly_genomic.fna` (scaffold-level) is used for read mapping and
> transcript assembly, while **GCA_964199275.3** (chromosome-level) is used here.
> Coordinates are **not** interchangeable between them.

## Output

| File | Content |
|------|---------|
| `analysis/miniprot/<LABEL>_miniprot.gff` | Splice-aware alignments: `mRNA` and `CDS` features with chromosome, start, end, strand, per receptor |
| `analysis/miniprot/chromosome_lengths_Iric.txt` | Two columns, `chr_id<TAB>length` — needed as MG2C input file 2 |
| `<genome>.fna.fai` | samtools index (written next to the genome, once) |

The alignment count is reported at the end of the job:

```bash
grep -c $'\tmRNA\t' analysis/miniprot/IR_80_miniprot.gff
```

A receptor can produce **more than one** `mRNA` line when the protein aligns to
several loci — paralogues, or a genuinely duplicated gene. Inspect multi-hit
cases before plotting; the ideogram notebook aggregates by gene ID and would
otherwise merge two real loci into one span.

## Downstream: the ideogram

The GFF and the chromosome-length table are the two inputs to
[`../06_figures/IdeoGram.ipynb`](../06_figures/), which converts them into the
format expected by **MG2C v2.1** (<http://mg2c.iask.in/mg2c_v2.1/>):

- **input 1** — `gene_id`, `gene_start`, `gene_end`, `chr_id`, `gene_color`
  (aggregated per gene: min start, max end)
- **input 2** — `chr_id`, `chr_length` (the file produced here)

## Software versions

| Tool | Version | Parameters |
|------|---------|------------|
| miniprot | 0.13 | `-t 16 --gff-only` (defaults otherwise) |
| samtools | 1.20 | `faidx` |

`--gff-only` suppresses the alignment block in the output, leaving pure GFF3 —
required because the ideogram parser reads the GFF with pandas.

## How to run

```bash
mkdir -p logs
sbatch 11_miniprot.sh          # ~1-2 h, 16 cores, 80 GB
```

Notes:

- `miniprot` must be on `PATH`, or set `MINIPROT` in the CONFIG block to the
  binary. The script loads `bioinfo-tools` and `samtools` modules but not
  miniprot itself — activate the conda env that has it before submitting.
- Genome indexing and the length table are skipped if they already exist, so
  repeated runs for different receptor sets are cheap.
- Each run overwrites `${LABEL}_miniprot.gff`. Use a distinct `LABEL` per family.
