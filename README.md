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

Background
Ticks transmit a wider range of pathogens than any other arthropod vector. Current control strategies rely largely on acaricides and synthetic repellents, raising concerns of toxicity, environmental impact and the development of resistance. The tick chemosensory system plays a critical role in host seeking, feeding and mating, making it a promising target for developing alternative control agents. Ticks lack antennae and instead detect chemical signals through Haller's organ on the first legs and gustatory sensilla on the mouthparts. Yet our understanding of the underlying chemosensory receptor genes remains limited. In particular, none of them has been functionally linked to a ligand.
Results
We curated the chemosensory receptor (CR) gene repertoire of Ixodes ricinus from a chromosome-level genome, and profiled receptor expression across sixteen RNA-seq libraries spanning nymphs and different body parts of adult males and females (mouthparts, first legs, fourth legs and the remaining body). The repertoire comprises 183 CR genes across four families: 71 gustatory receptors (GRs), 80 ionotropic receptors (IRs)/ionotropic glutamate receptors (iGluRs), 20 transient receptor potential (TRP) channels and 12 pickpocket (PPK) receptors. The four receptor families showed pronounced genomic clustering, with 52% of GRs located on chromosome 5, all twelve kainate receptors on chromosome 4 and all five AMPA receptors on chromosome X. Multi-species phylogenies placed these duplications before the divergence of Ixodes species or even before the tick–spider split, supporting the retention of ancestral synteny rather than recent lineage-specific expansion. Ninety-eight of CR genes had high-confidence expressed transcripts. Seventeen showed expression restricted to the first legs, including the conserved co-receptors IricIR25a and IricIR93a together with six other IRs, while another set was restricted to the mouthparts, reflecting the anatomical division between olfactory and contact chemoreception.
Conclusions
We provide a comprehensive, stringently curated chemosensory receptor repertoire of I. ricinus and revealed patterns of genomic organization and evolutionary diversification across receptor families. Tissue-biased expression identified both conserved co-receptors and tick-specific receptors as candidates for peripheral chemosensation, particularly in the first legs bearing Haller's organ and in the mouthparts. These findings provide a framework for functional characterization of tick CRs and for understanding the molecular basis of tick sensory biology.
<img width="468" height="650" alt="image" src="https://github.com/user-attachments/assets/1ace467f-6d70-44cc-8ad6-e18ab7bb69c8" />


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
| [`04_chromosomal_mapping/`](04_chromosomal_mapping/) | miniprot placement on the *I. ricinus* assembly |
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
| GNU grep | 3.7 | 02.03 |
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

### Tick genomes

The 14 species assessed with QUAST and BUSCO in
[`01_data_processing/03_transcriptome_assembly/`](01_data_processing/03_transcriptome_assembly/).
**Row order matches [`03_phylogeny/tick_species_list.txt`](03_phylogeny/tick_species_list.txt)
line for line**, and that line number *is* the `SLURM_ARRAY_TASK_ID` — appending
a species is safe, reordering silently reassigns every array task.

| # | Species | Family | Common name | Accession |
|---|---------|--------|-------------|-----------|
| 0 | *Amblyomma americanum* | Ixodidae | Lone star tick | [GCA_030143305.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_030143305.2/) |
| 1 | *Amblyomma maculatum* | Ixodidae | Gulf Coast tick | [GCA_023969395.1](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_023969395.1/) |
| 2 | *Dermacentor albipictus* | Ixodidae | Winter tick | [GCF_038994185.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_038994185.2/) |
| 3 | *Dermacentor andersoni* | Ixodidae | Rocky Mountain wood tick | [GCF_023375885.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_023375885.2/) |
| 4 | *Dermacentor silvarum* | Ixodidae | Pasture tick | [GCF_013339745.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_013339745.2/) |
| 5 | *Dermacentor variabilis* | Ixodidae | American dog tick | [GCA_049308735.1](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_049308735.1/) |
| 6 | *Hyalomma asiaticum* | Ixodidae | Asian tick | [GCA_013339685.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_013339685.2/) |
| 7 | *Haemaphysalis longicornis* | Ixodidae | Asian longhorned tick | [GCA_013339765.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_013339765.2/) |
| 8 | *Ixodes persulcatus* | Ixodidae | Taiga tick | [GCA_964199295.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_964199295.2/) |
| 9 | ***Ixodes ricinus*** ★ | Ixodidae | European / sheep tick | [BIPAA assembly 1.0](https://bipaa.genouest.org/sp/ixodes_ricinus/download/ixodes_ricinus/assembly_1.0/fasta/) |
| 10 | *Ixodes scapularis* | Ixodidae | Black-legged tick | [GCA_031841145.1](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_031841145.1/) |
| 11 | *Ornithodoros turicata* | **Argasidae** | Relapsing fever tick | [GCF_037126465.1](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_037126465.1/) |
| 12 | *Rhipicephalus microplus* | Ixodidae | Cattle tick | [GCF_013339725.1](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_013339725.1/) |
| 13 | *Rhipicephalus sanguineus* | Ixodidae | Brown dog tick | [GCF_013339695.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_013339695.2/) |

★ = focal species of this study.

Composition: 13 Ixodidae (hard ticks) and a single Argasidae, *O. turicata*,
which serves as the **soft-tick outgroup**. By genus: 4 *Dermacentor*,
3 *Ixodes*, 2 *Amblyomma*, 2 *Rhipicephalus*, 1 *Hyalomma*, 1 *Haemaphysalis*.

Two things to watch:

- **`H_asiaticum` and `H_longicornis` are different genera** — *Hyalomma* and
  *Haemaphysalis* respectively. The abbreviations in `tick_species_list.txt`
  collide, so always resolve them against this table rather than guessing.
- 6 assemblies are **GCF** (RefSeq, with NCBI annotation) and 7 are **GCA**
  (GenBank, assembly only). BUSCO genome mode does not care, but anything that
  needs a reference GFF is only available for the GCF accessions.

### The *Ixodes ricinus* assembly

Everything in this project — read mapping, transcript assembly, BLAST against the
official gene set, and the chromosomal placement — uses the single **BIPAA
assembly 1.0** (row 9 above), with its **OGS 1.3** protein set for the
annotation-based searches.

| Used for | Where |
|----------|-------|
| HISAT2 read mapping, transcript assembly | [`01_data_processing/03_transcriptome_assembly/`](01_data_processing/03_transcriptome_assembly/) |
| BLAST against the official gene set (OGS 1.3) | [`02_annotation/01_blast_curation/`](02_annotation/01_blast_curation/) |
| miniprot placement and the ideogram | [`04_chromosomal_mapping/`](04_chromosomal_mapping/), [`06_figures/`](06_figures/) |

### Other reference data

| Dataset | Source |
|---------|--------|
| *D. melanogaster* receptor references | FlyBase |
| *Argiope bruennichi* receptor references | published repertoire |
| Kraken2 standard database | NCBI RefSeq — **record the build date**, results are not comparable across builds (see [01.02](01_data_processing/02_taxonomic_classification/)) |

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

One reconstructed step is flagged in its own README: the original scripts for
[QC/trimming](01_data_processing/01_qc_trimming/) were lost and the committed
versions were rebuilt from the MultiQC report and the trimming logs. The
[GR motif discovery](02_annotation/03_motif_discovery_GR/) scripts were also lost,
but are reconstructed from the author's own analysis record
([`ANALYSIS.md`](02_annotation/03_motif_discovery_GR/ANALYSIS.md)), which documents
every command line and parameter — so they are faithful, not inferred. Everything
else is the original submission script, unmodified.

---

## License

[MIT](LICENSE) © 2026 Zaide Montes-Ortiz

---

## Contact

**Zaide Montes-Ortiz**
Department of Biology, Lund University
📧 [zaide.montes_ortiz@biol.lu.se](mailto:zaide.montes_ortiz@biol.lu.se)
🐙 [@lachemontes](https://github.com/lachemontes)

For questions about a specific step, check that folder's `README.md` first — each
one documents its inputs, outputs, exact parameters and known caveats.
