# Chemosensory receptor repertoire of *Ixodes ricinus*

Analysis code for:

> **Comprehensive characterization of the chemosensory receptor repertoire of
> *Ixodes ricinus* ticks reveals distinct genomic organization and
> appendage-biased expression**
>
> Zaide Montes-Ortiz, Qi Wang, Dan-Dan Zhang
>
> **In preparation**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Abstract

Ticks locate and identify hosts through chemical cues, yet the molecular basis of
chemoreception in Acari remains poorly characterised compared with insects. We
annotated and characterised the chemosensory receptor repertoire of the sheep
tick *Ixodes ricinus*, the principal vector of Lyme borreliosis in Europe,
combining genome-guided and *de novo* transcriptome assembly across appendage and
body tissues of both sexes.

Two features define the repertoire. First, the receptors do not form
lineage-specific expansions: phylogenetic reconstruction including a spider
(*Argiope bruennichi*) and an insect (*Drosophila melanogaster*) places the tick
receptors across clades that already contain the non-tick references, and
chromosomal mapping shows them dispersed rather than arranged in tandem arrays —
an **ancestral clustering** pattern indicating retention from an already
diversified ancestral set rather than recent local duplication. Second,
expression is strongly **restricted to the appendages**, the tissues bearing the
chemosensory organs, consistent with a sensory rather than a general physiological
role.

We resolve the ionotropic receptor (IR) / ionotropic glutamate receptor (iGluR)
boundary on the state of the glutamate-binding residues rather than on sequence
identity alone, and identify a conserved motif in the tick gustatory receptors
that is detectable in both the spider and the *Drosophila* GR repertoires.

*(Working abstract — to be replaced with the accepted version on publication.)*

---

## Table of contents

| Section | Contents |
|---------|----------|
| **[`Manual/`](Manual/)** | **[GuideYou.md](Manual/GuideYou.md) — start here.** Step-by-step walkthrough of the whole pipeline |
| [`01_data_processing/`](01_data_processing/) | Raw reads → curated proteome |
| &nbsp;&nbsp;[`01_qc_trimming/`](01_data_processing/01_qc_trimming/) | FastQC, MultiQC, Trim Galore |
| &nbsp;&nbsp;[`02_taxonomic_classification/`](01_data_processing/02_taxonomic_classification/) | Kraken2 contamination screen |
| &nbsp;&nbsp;[`03_transcriptome_assembly/`](01_data_processing/03_transcriptome_assembly/) | HISAT2, StringTie, TransDecoder, CD-HIT, BUSCO, QUAST |
| [`02_annotation/`](02_annotation/) | Receptor identification and curation |
| &nbsp;&nbsp;[`01_blast_curation/`](02_annotation/01_blast_curation/) | Reciprocal BLAST, best-hit selection, redundancy removal |
| &nbsp;&nbsp;[`02_interproscan/`](02_annotation/02_interproscan/) | Domain and topology validation |
| &nbsp;&nbsp;[`03_motif_discovery_GR/`](02_annotation/03_motif_discovery_GR/) | MEME, TOMTOM, FIMO |
| &nbsp;&nbsp;[`04_residue_analysis_IR/`](02_annotation/04_residue_analysis_IR/) | Glutamate-binding residue scoring |
| [`03_phylogeny/`](03_phylogeny/) | MAFFT + IQ-TREE gene trees |
| [`04_chromosomal_mapping/`](04_chromosomal_mapping/) | miniprot against the chromosome-level assembly |
| [`05_expression/`](05_expression/) | kallisto quantification across 16 libraries |
| [`06_figures/`](06_figures/) | Ideogram preparation; notes on the other figures |
| [`Supplementary/`](Supplementary/) | Additional files for the manuscript |

Every folder has its own `README.md` documenting purpose, scripts, inputs,
outputs, software versions and how to run that step.

---

## Pipeline overview

```
 raw reads (16 PE libraries: appendages vs. body, ♀ and ♂)
        │
        ├─ FastQC / MultiQC ──────────────► QC report
        │
   Trim Galore
        │
        ├─ Kraken2 ───────────────────────► contamination screen
        │
        ├──────────────────┬──────────────────┐
        ▼                  ▼                  │
  HISAT2 → StringTie   Trinity                │  (two parallel
   (genome-guided)    (de novo)               │   assemblies)
        │                  │                  │
        └── TransDecoder ──┘                  │
                 │                            │
             CD-HIT ───► BUSCO ───────────────┘
                 │
                 ▼
        ┌─── reciprocal BLASTp ───┐
        │   + InterProScan        │   curation: homology,
        │   + length filter       │   domains, length
        └────────────┬────────────┘
                     ▼
        curated receptor set (80 IR/iGluR; GR, PPK, TRP)
                     │
     ┌───────────┬───┴────────┬──────────────┬───────────────┐
     ▼           ▼            ▼              ▼               ▼
  MAFFT +    miniprot →   residue        MEME →         hybrid CDS →
  IQ-TREE    ideogram     analysis      TOMTOM/FIMO      kallisto
     │           │            │              │               │
  ancestral  dispersed    IR / iGluR    conserved GR    appendage-
  clustering  in genome    boundary        motif        restricted
                                                        expression
```

---

## Requirements

Everything was run on the Swedish NAISS clusters (Dardel/PDC) under SLURM.
Scripts load software with `module load` where available and fall back to conda
environments otherwise.

### Software

| Tool | Version | Used in |
|------|---------|---------|
| FastQC | 0.11.9 | 01.01 |
| MultiQC | 1.12 | 01.01 |
| Trim Galore | 0.6.1 | 01.01 |
| Cutadapt | 2.1 | 01.01 |
| Kraken2 | 2.1.3 | 01.02 |
| QUAST | 5.2.0 | 01.03 |
| BUSCO | 6.0.0 / 5.x | 01.03 |
| AUGUSTUS | 3.4.0 | 01.03 |
| HISAT2 | 2.2.1 | 01.03 |
| samtools | 1.20 | 01.03, 04 |
| StringTie | 2.2.1 | 01.03 |
| TransDecoder | 5.7.1 | 01.03 |
| CD-HIT | 4.8.1 | 01.03, 02.01, 02.03 |
| BLAST+ | 2.9.0+ | 02.01 |
| seqkit | 2.3.1 | 02.01, 05 |
| InterProScan | 5.52-86.0 | 02.02 |
| MEME Suite | 5.5.5 | 02.03 |
| MAFFT | 7.520 | 03 |
| IQ-TREE | 2.2.2.6 | 03 |
| miniprot | 0.13 | 04 |
| kallisto | 0.48.0 | 05 |
| MG2C | v2.1 (web) | 06 |
| iTOL | v6 (web) | 06 |

BUSCO lineage: `arthropoda_odb10` throughout.

### Python environment

```bash
conda create -n ticks_py python=3.11 pandas biopython openpyxl jupyter
conda activate ticks_py
```

---

## Reference data

| Dataset | Accession / source |
|---------|--------------------|
| *I. ricinus* chromosome-level assembly | [GCA_964199275.3](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_964199275.3/) (IXRI_v3) — used for chromosomal mapping |
| *I. ricinus* scaffold assembly + OGS1.3 | used for read mapping and transcript assembly |
| 14 tick genomes | NCBI Datasets; species listed in [`03_phylogeny/tick_species_list.txt`](03_phylogeny/tick_species_list.txt) |
| *D. melanogaster* receptor references | FlyBase |
| *Argiope bruennichi* receptor references | published repertoire |
| Kraken2 standard database | NCBI RefSeq (build date matters — see [01.02](01_data_processing/02_taxonomic_classification/)) |

**Raw reads** will be deposited in the NCBI SRA under BioProject
`PRJNA[pending]` on publication.

---

## What this repository does and does not contain

**Contains:** all analysis scripts, notebooks and documentation.

**Does not contain:** sequence data, alignments, trees, BLAST databases, or
analysis outputs. These are excluded by [`.gitignore`](.gitignore) — the
repository is code only. Data will be available through the SRA deposit and a
Zenodo archive cited from the paper.

Cluster paths are hard-coded in the scripts as a record of what was run. The
project allocation changed over the course of the work
(`naiss2023-23-109`, `naiss2024-5-647`, `naiss2025-5-763`) and the data paths
follow (`naiss2023-23-109` vs `naiss2025-23-132`). **Check both the `#SBATCH -A`
line and the paths before submitting any script.**

Two reconstructed steps are flagged in their own READMEs: the original scripts for
[QC/trimming](01_data_processing/01_qc_trimming/) and
[GR motif discovery](02_annotation/03_motif_discovery_GR/) were lost, and the
committed versions were rebuilt from logs and tool reports. Everything else is the
original submission script, unmodified.

---

## Citation

Please cite the paper:

```bibtex
@article{MontesOrtiz2026_Iricinus_chemoreceptors,
  author  = {Montes-Ortiz, Zaide and Wang, Qi and Zhang, Dan-Dan},
  title   = {Comprehensive characterization of the chemosensory receptor
             repertoire of {\emph{Ixodes ricinus}} ticks reveals distinct
             genomic organization and appendage-biased expression},
  year    = {2026},
  note    = {In preparation},
  doi     = {<DOI on acceptance>}
}
```

<!-- Add journal, volume, pages and DOI on acceptance. -->

To cite the code itself, use the repository URL:
<https://github.com/lachemontes/ticks_project>

---

## License

[MIT](LICENSE) © 2026 Zaide Montes-Ortiz

---

## Contact

**Zaide Montes-Ortiz**
Department of Biology, Lund University
📧 [zaide_katherine.montes_ortiz@biol.lu.se](mailto:zaide_katherine.montes_ortiz@biol.lu.se)
🐙 [@lachemontes](https://github.com/lachemontes)

For questions about a specific step, check that folder's `README.md` first — each
one documents its inputs, outputs, exact parameters and known caveats.
