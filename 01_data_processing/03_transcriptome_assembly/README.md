# 01.03 — Transcriptome assembly

## Purpose

Build the two protein sets that the whole receptor annotation rests on:

1. a **genome-guided** assembly — reads mapped to the *I. ricinus* reference with
   HISAT2, transcripts assembled with StringTie, ORFs called with TransDecoder;
2. a ***de novo*** assembly (Trinity, run outside this repo — see note below),
   also passed through TransDecoder.

Both are made non-redundant with CD-HIT and scored for completeness with BUSCO.
Reference tick genomes from 14 species are assessed in parallel (QUAST + BUSCO)
to put the *I. ricinus* assembly in context and to pick the genomes used for the
comparative chromosomal analysis.

> **Trinity.** The *de novo* assembly (`Transcriptomes_2023_2024.fasta`) was
> produced in an earlier project phase and its submission script is not part of
> this repository. The scripts here take the resulting
> `*.transdecoder.pep` / `*.transdecoder.cds` files as input.

## Scripts

Numeric prefixes reflect the order they were run in.

### Reference genome assessment
| Script | Tool | Description |
|--------|------|-------------|
| `00_quast.sh` | QUAST | Contiguity stats for 14 tick genomes (SLURM array 0–13); adds `--fragmented` for non-chromosome-level assemblies |
| `01_busco_genomes.sh` | BUSCO (genome mode) | Completeness of the 14 genomes, `arthropoda_odb10`; module-based BUSCO 6.0.0 + AUGUSTUS |
| `01_busco.sh` | BUSCO (genome mode) | Same, conda-based `busco` entry point, re-run for individual species |

### Read mapping and transcript assembly
| Script | Tool | Description |
|--------|------|-------------|
| `03_histat_idex.sh` | `hisat2-build` | Build the HISAT2 index from the *I. ricinus* assembly — run **once**, before mapping |
| `03_hisat_main.sh` | HISAT2 | Map 32 trimmed libraries to the index (array 1–32). **This is the version that was used** |
| `03_hisat.sh` | HISAT2 | Earlier variant expecting `_R*_paired.fastq.gz` names; kept for provenance, superseded |
| `05_samToBam.sh` | samtools | SAM → BAM, sort, index, then merge in array task 1. Superseded by the two scripts below |
| `06_samTobam_gemini.sh` | samtools | Streamed `view \| sort` in one pass — faster, no intermediate BAM. **Preferred** |
| `06_samTobam_gpt.sh` | samtools | Same with an explicit node-local `/scratch` temp dir for sorting |
| `07_merge_bam_dardel.sh` | samtools | Merge all `*_sorted.bam` into `merged_all_samples.bam` + index (separate job, replaces the merge inside `05_`) |
| `08_stringtie.sh` | StringTie | Genome-guided assembly on the merged BAM → `final_transcriptome_assembly_2.gtf` + gene abundances |
| `08_stringtie2.sh` | StringTie | **Incomplete stub** (`stringtie` with no arguments). Kept only to document the parameter block; use `08_stringtie.sh` |

### ORF prediction and redundancy removal
| Script | Tool | Description |
|--------|------|-------------|
| `06_Transdecoder_manual.sh` | TransDecoder | `LongOrfs` + `Predict` on the StringTie transcripts |
| `07_cd-hit_2.sh` | CD-HIT + awk/sed | Collapse the *de novo* peptides at **98 % identity**, then clean headers: unwrap sequences, strip `*` stop characters, truncate headers at the first space |

### Completeness assessment
| Script | Tool | Description |
|--------|------|-------------|
| `08_busco.sh` | BUSCO (protein) | Single run on the genome-guided peptide set |
| `buco_claudia.sh` | BUSCO | Loop over 4 runs: *de novo* pep, genome-guided pep, TransDecoder CDS, CD-HIT CDS |
| `21_busco_proteome.sh` | BUSCO | *de novo* set in both `protein` and `transcriptome` mode |
| `22_busco_transcriptome.sh` | BUSCO | Genome-guided vs. *de novo* CDS, both in `transcriptome` mode |

The four BUSCO scripts overlap by design — they were run as the assemblies were
revised. `buco_claudia.sh` is the most complete single summary.

## Input

- `data/trimmed_libs/*_val_{1,2}.fq.gz` — from [`../01_qc_trimming/`](../01_qc_trimming/)
- `data/trimmed_libs/libraries.txt` — one sample prefix per line, indexed by `SLURM_ARRAY_TASK_ID`
- `data/genomes/I_ricinus/.../Iricinus_assembly_genomic.fna` — reference assembly
- `data/genomes/<species>/data/*_genomic.fna` — the 14 tick genomes
- `03_phylogeny/tick_species_list.txt` — species order for the QUAST/BUSCO arrays
- `data/genomes/assembly_levels.tsv` — `species<TAB>level` (Chromosome / Scaffold / Contig), drives the QUAST `--fragmented` flag
- `Transcriptomes_2023_2024.fasta.transdecoder.pep` / `.cds` — Trinity *de novo* set

## Output

| File | Produced by |
|------|-------------|
| `analysis/hisat/genome_Index.*.ht2` | `03_histat_idex.sh` |
| `analysis/hisat/<sample>.sam` | `03_hisat_main.sh` |
| `analysis/bam/<sample>_sorted.bam{,.bai}` | `06_samTobam_*.sh` |
| `analysis/bam/merged_all_samples.bam{,.bai}` | `07_merge_bam_dardel.sh` |
| `analysis/stringtie/final_transcriptome_assembly_2.gtf` | `08_stringtie.sh` |
| `analysis/stringtie/gene_abundances.txt` | `08_stringtie.sh` |
| `analysis/transdecoder/transcripts.fasta.transdecoder.{pep,cds}` | `06_Transdecoder_manual.sh` |
| `analysis/cd-hit/de_novo/transcripts_final_busco_inter_pep_98_denovo.fasta` | `07_cd-hit_2.sh` |
| `analysis/cd-hit/transcripts_final_busco_inter_pep.fasta` | genome-guided equivalent |
| `analysis/busco/*/short_summary.*.txt` | the BUSCO scripts |
| `analysis/quast/<species>/report.tsv` | `00_quast.sh` |

The two CD-HIT peptide sets are the BLAST databases `genomeGuide_DB` and
`deNovo_DB` used in [`../../02_annotation/01_blast_curation/`](../../02_annotation/01_blast_curation/).

## Software versions

| Tool | Version | Notes |
|------|---------|-------|
| QUAST | 5.2.0 | `--eukaryote`, `--fragmented` for non-chromosomal assemblies |
| BUSCO | 6.0.0 (module) / 5.x (conda) | lineage `arthropoda_odb10` throughout |
| AUGUSTUS | 3.4.0 | required by BUSCO genome mode |
| HISAT2 | 2.2.1 | defaults, `-p 12` |
| samtools | 1.20 | |
| StringTie | 2.2.1 | `-p 12`, `-A gene_abundances.txt` |
| TransDecoder | 5.7.1 | `LongOrfs` then `Predict`, defaults |
| CD-HIT | 4.8.1 | `-c 0.98 -n 5 -M 0 -T 0` |

Two BUSCO entry points appear across the scripts: `run_BUSCO.py` (BUSCO 6 module
on Dardel) and `busco` (conda env `BUSCO`). They are equivalent for our purposes;
`-l` takes `$BUSCO_LINEAGE_SETS/arthropoda_odb10` with the module and a bare
`arthropoda_odb10` with conda.

## How to run

Order matters — later steps consume earlier outputs.

```bash
mkdir -p logs

# ── Reference genomes (independent of the RNA-seq track) ──
sbatch 00_quast.sh                  # array 0-13
sbatch 01_busco_genomes.sh          # array 0,2-6

# ── RNA-seq track ──
sbatch 03_histat_idex.sh            # once; wait for it to finish
sbatch 03_hisat_main.sh             # array 1-32
sbatch 06_samTobam_gemini.sh        # array 1-16; wait for the whole array
sbatch 07_merge_bam_dardel.sh
sbatch 08_stringtie.sh
sbatch 06_Transdecoder_manual.sh
sbatch 07_cd-hit_2.sh

# ── Completeness ──
sbatch buco_claudia.sh
```

Notes:

- Edit the `#SBATCH -A <project>` line in every script; the allocation changed
  over the course of the project (`naiss2023-23-109`, `naiss2024-5-647`,
  `naiss2025-5-763`) and the paths follow (`naiss2023-23-109` vs
  `naiss2025-23-132`). **Check both before submitting.**
- `--array` ranges must match the line count of `libraries.txt` /
  `tick_species_list.txt`.
- The BUSCO scripts assume the conda env is already active at submission time
  (`conda activate BUSCO`) unless they load the module themselves.
- SAM files are large and are deleted by the BAM step; they are gitignored.
