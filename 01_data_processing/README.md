# 01 — Data processing

From raw Illumina reads to a curated *Ixodes ricinus* proteome used for all
downstream receptor annotation.

| Step | Folder | What it does |
|------|--------|--------------|
| 1 | [`01_qc_trimming/`](01_qc_trimming/) | FastQC/MultiQC on raw reads, adapter and quality trimming with Trim Galore |
| 2 | [`02_taxonomic_classification/`](02_taxonomic_classification/) | Kraken2 contamination screen of trimmed reads |
| 3 | [`03_transcriptome_assembly/`](03_transcriptome_assembly/) | Genome-guided (HISAT2 + StringTie) and *de novo* (Trinity) assembly, ORF prediction, redundancy removal, completeness assessment |

**Sequencing design.** 16 paired-end libraries (8 sample pairs × 2 tissues:
appendages vs. rest-of-body), male and female, sequenced on Illumina NovaSeq.

**Two parallel assemblies** are carried through the whole project on purpose:
a genome-guided one (better exon structure, used for chromosomal mapping) and a
*de novo* one (recovers transcripts absent from the reference annotation). The
final receptor set is a **hybrid** of both — see
[`../05_expression/`](../05_expression/).
