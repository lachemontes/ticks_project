# Chemosensory receptors in *Ixodes ricinus* — a guide to the pipeline

## Project Description

This guide walks through the complete analysis behind *"Comprehensive
characterization of the chemosensory receptor repertoire of Ixodes ricinus ticks
reveals distinct genomic organization and appendage-biased expression"*. It is
written for the person who has to run this again — a new student in the group, a
reviewer who wants to check a step, or me in two years when I have forgotten why
the CD-HIT threshold is 0.98 in one place and 1.0 in another.

*Ixodes ricinus* is the sheep tick, the main European vector of *Borrelia
burgdorferi* s.l. and tick-borne encephalitis virus. It finds its host by smell
and touch: it waits on vegetation, detects host cues with the sensory organs on
its first pair of legs (**Haller's organ**) and its palps, and then climbs on.
Those cues are chemical, so there must be chemoreceptors — but ticks are
chelicerates, not insects, and almost everything we know about arthropod
chemoreception comes from *Drosophila*. The receptor families are shared by
descent, but we cannot assume the repertoire is organised the same way.

That is the question this pipeline answers. We annotate the receptor families
(**IRs/iGluRs, GRs, PPKs, TRPs**), place them in a phylogeny that includes both a
spider and a fly, map them onto the chromosomes, and quantify where in the animal
they are expressed.

Two results shape how the pipeline is built, and knowing them in advance makes the
design choices make sense:

1. **Ancestral clustering.** The tick receptors are not one big lineage-specific
   expansion. They sit across clades that already contain the spider and fly
   references, and on the chromosomes they are dispersed rather than stacked in
   tandem arrays. This is why the phylogeny *must* include *Argiope bruennichi* —
   with *Drosophila* alone, every tick clade looks tick-specific by construction —
   and why the chromosomal mapping is a separate, load-bearing analysis rather
   than a decorative figure.
2. **Appendage-restricted expression.** The receptors are expressed in the
   appendages and nearly absent elsewhere. This is why the libraries are
   tissue-split (appendages vs. rest-of-body) in both sexes, 16 in total.

Before I start: before **ChatGPT** and friends, I learned how to document a
pipeline from people who wrote their methods down properly and put them online.
This guide is me paying that forward. If something here is unclear, it is my fault,
not yours — open an issue.

The pipeline was executed between 2022 and 2026 on the Swedish NAISS systems
(primarily the Dardel cluster at PDC). Scripts carry three different `#SBATCH -A`
allocations reflecting this history, and some data paths point to a legacy
project ID. See the 'Clusters and allocations' section below.

### Pipeline overview

Numbers in brackets are the step sections under **Analysis** below.

```
 raw reads  (16 PE libraries: appendages vs. body, female and male)
        |
        |-- FastQC / MultiQC ---------------->  QC report              [1]
        |
   Trim Galore                                                        [1]
        |
        |-- Kraken2 ------------------------->  contamination screen   [2]
        |
        |------------------+------------------+
        v                  v                  |
  HISAT2 -> StringTie   Trinity               |   two parallel          [3]
   (genome-guided)      (de novo, external)   |   assemblies
        |                  |                  |
        +-- TransDecoder --+                  |
                 |                            |
             CD-HIT ----> BUSCO --------------+
                 |
                 v
        +--- reciprocal BLASTp ---+
        |    + InterProScan       |   curation: homology,            [4][5]
        |    + length filter      |   domains, length >= 200 aa
        +------------+------------+
                     v
        curated receptor set  (80 IR/iGluR; GR, PPK, TRP)
                     |
     +-----------+---+--------+--------------+---------------+
     v           v            v              v               v
  MAFFT +    miniprot ->   residue        MEME ->       hybrid CDS ->
  IQ-TREE    ideogram      analysis     TOMTOM/FIMO       kallisto
    [6]       [9][11]        [7]            [8]             [10]
     |           |            |              |               |
  ancestral  dispersed    IR / iGluR    conserved GR     appendage-
  clustering  in genome    boundary         motif         restricted
                                                          expression
```

The five branches below the curated set map onto the paper's two claims.
Phylogeny [6] and chromosomal mapping [9] together establish **ancestral
clustering** — the tree alone cannot distinguish it from recent local
duplication, which is why the mapping is load-bearing rather than decorative.
Quantification [10] establishes **appendage-restricted expression**. The residue
analysis [7] and motif discovery [8] support the annotation itself rather than
either claim directly.

## Data description

### Sequencing

16 paired-end Illumina libraries:

| Factor | Levels |
|--------|--------|
| Tissue | appendages (palps + tarsi I, incl. Haller's organ) / rest-of-body |
| Sex | female / male |
| Replicates | 4 per tissue × sex combination |

The tissue split is the whole point. A receptor that is enriched in appendages and
near-absent in the body is a chemosensory candidate; one expressed evenly
everywhere is doing something else.

### Reference genomes

| Dataset | Accession | Used for |
|---------|-----------|----------|
| *I. ricinus* scaffold assembly + OGS1.3 | — | read mapping, transcript assembly |
| *I. ricinus* chromosome-level | **GCA_964199275.3** (IXRI_v3) | chromosomal mapping |
| 14 tick genomes | NCBI Datasets | comparative context (QUAST + BUSCO) |

⚠️ **The two *I. ricinus* assemblies are not coordinate-compatible.** Mapping
happens against the scaffold assembly, chromosomal placement against IXRI_v3.
If you mix them you will get coordinates that look plausible and are wrong.

The 14 tick species are in
[`03_phylogeny/tick_species_list.txt`](../03_phylogeny/tick_species_list.txt).
**Line order is the SLURM array index.** Appending a species is safe; reordering
silently reassigns every array task.

### Receptor references

Curated sets in `data/blast_resorces/` *(yes, the typo is in the real paths — the
scripts depend on it, so I left it)*:

| File | Content |
|------|---------|
| `IR_iGluRs_Dmel_abru.fasta` | IRs + iGluRs, *D. melanogaster* and *A. bruennichi* |
| `GR_ref.fasta`, `PPK_ref.fasta`, `TRP_ref.fasta` | per-family references |
| `*_BMC_proteins.fasta` | our curated tick sets |

---

## Before you start

### Clusters and allocations

Everything ran on the Swedish NAISS systems (mainly **Dardel**/PDC) under SLURM.
The allocation changed three times over the project, so every script has a
different `#SBATCH -A`:

| Allocation | Period |
|------------|--------|
| `naiss2023-23-109` | early phase; **most data paths still live here** |
| `naiss2024-5-647` | assembly phase |
| `naiss2025-5-763` | annotation and expression phase |

And the storage paths diverge independently of the compute allocation —
`naiss2023-23-109` vs `naiss2025-23-132`.

**So: before submitting anything, check two lines, not one.**

```bash
grep -n '#SBATCH -A' script.sh          # compute allocation
grep -n '^[A-Z_]*=.*klemming' script.sh  # data paths
```

I keep a project root variable in my shell to make this less painful:

```bash
export TICKS=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks
```

### Environments

Some tools come from modules, some from conda. The scripts try modules first and
fall back, which means a missing tool often shows up as a confusing error deep in
the job rather than at the top. Set the conda envs up once:

```bash
# BUSCO
conda create -n BUSCO -c bioconda -c conda-forge busco=5.5.0
# MAFFT + IQ-TREE
conda create -n IQtree -c bioconda mafft=7.520 iqtree=2.2.2.6
# general assembly / BLAST helpers (needs pandas for the best-hit script)
conda create -n Gassembly -c bioconda -c conda-forge \
    blast=2.9.0 seqkit=2.3.1 cd-hit=4.8.1 miniprot=0.13 pandas
# notebooks
conda create -n ticks_py python=3.11 pandas biopython openpyxl jupyter
```

### Logs

Nearly every script writes to `logs/` **relative to where you submit from**. If it
does not exist, SLURM fails the job before your code runs and the error message
is unhelpful. Just always:

```bash
mkdir -p logs
```

---

## Software versions

| Tool | Version | Used in step |
|------|---------|--------------|
| FastQC | 0.11.9 | 1 |
| MultiQC | 1.12 | 1 |
| Trim Galore | 0.6.1 | 1 |
| Cutadapt | 2.1 | 1 |
| Kraken2 | 2.1.3 | 2 |
| HISAT2 | 2.2.1 | 3 |
| SAMtools | 1.17 | 3 |
| StringTie | 2.2.1 | 3 |
| Trinity | 2.14.0 | 3 (external) |
| TransDecoder | 5.7.0 | 3 |
| CD-HIT | 4.8.1 | 3, 4, 8 |
| BUSCO | 5.5.0 | 3 |
| QUAST | 5.2.0 | 3 |
| BLAST+ | 2.9.0 | 4 |
| seqkit | 2.3.1 | 4 |
| InterProScan | 5.52-86.0 | 5 |
| MAFFT | 7.520 | 6 |
| IQ-TREE | 2.2.2.6 | 6 |
| miniprot | 0.13 | 9 |
| MEME Suite | 5.5.5 | 8 |
| kallisto | 0.48.0 | 10 |
| MG2C | 2.1 (web) | figures |
| iTOL | 6 (web) | figures |

Report build dates alongside versions where results depend on a reference
database (notably Kraken2 and InterProScan).

---

## Analysis

### 1. Read quality control and trimming

📁 [`01_data_processing/01_qc_trimming/`](../01_data_processing/01_qc_trimming/)

> ⚠️ **Reconstructed step.** The original submission scripts for this step were
> lost. The two scripts here were rebuilt from the MultiQC report and the Trim
> Galore logs. They reproduce what was run, but they are not the original files.
> Everything from step 2 onwards is the original script.

#### FastQC and MultiQC

Standard first look: adapter content, per-base quality, duplication, overrepresented
sequences. Nothing clever, but do not skip reading the report — tick RNA-seq
libraries are where you notice a failed library before it poisons the assembly.

```bash
mkdir -p logs
sbatch fastqc.sh      # ~1 h, 8 cores
```

MultiQC collapses the 32 individual FastQC reports into one HTML. That is the file
you actually look at:

```
data/qc_raw/multiqc_report_raw.html
```

#### Trim Galore

```bash
sbatch trimgalore.sh  # ~8 h, 8 cores
```

Trim Galore wraps Cutadapt and auto-detects the adapter, which is why there is no
adapter sequence in the script. **It was run with defaults** — Phred 20, minimum
length 20 bp. That is the one parameter fact worth recording: no custom thresholds
were applied, so if you re-run with your own cutoffs you are no longer reproducing
this paper.

The output naming matters:

```
<sample>_R1_001_val_1.fq.gz
<sample>_R2_001_val_2.fq.gz
```

Those `_val_1` / `_val_2` suffixes are Trim Galore's convention, and **HISAT2,
Kraken2 and kallisto all have them hard-coded**. Do not tidy them up.

### 2. Taxonomic classification

📁 [`01_data_processing/02_taxonomic_classification/`](../01_data_processing/02_taxonomic_classification/)

Ticks are full of other organisms. *Rickettsia*, *Borrelia*, *Midichloria* —
endosymbionts and pathogens that will happily assemble into transcripts. A
bacterial transcript with a plausible length and no close homolog can look
*exactly* like an exciting divergent receptor candidate.

```bash
sbatch kraken2.sh     # ~4 h, 16 cores, 64 GB
```

Memory is the binding constraint, not CPU: the standard database sits in RAM at
~50 GB. If your allocation is smaller, use a capped build (`--max-db-size`) or one
of the prebuilt standard-8 / standard-16 indices — and say which in your methods.

#### An important interpretive point

**We did not remove reads based on Kraken2.** The classification is diagnostic.
The non-arthropod fraction was low, so assembly proceeded on the full trimmed set,
and contamination was controlled later at the protein level by the reciprocal BLAST
and the InterProScan domain check. Doing it this way keeps a genuine tick transcript
that happens to have a weird *k*-mer profile from being thrown away.

Also: **Kraken2 results are not comparable across database builds.** Report the
build date next to the version number, or the number is meaningless.

### 3. Transcriptome assembly

📁 [`01_data_processing/03_transcriptome_assembly/`](../01_data_processing/03_transcriptome_assembly/)

This is the longest step and the one where the design choice matters most.

#### Why two assemblies

We build **both** a genome-guided and a *de novo* assembly and carry both all the
way through. They fail in opposite directions:

- **Genome-guided** (HISAT2 → StringTie) gets exon structure right, which is what
  the chromosomal mapping needs — but it cannot recover a transcript that is
  missing or broken in the reference assembly.
- ***De novo*** (Trinity) recovers those, but its exon boundaries are guesses and
  it produces more fragments and more redundancy.

Chemoreceptors are exactly the kind of fast-evolving, tandem-duplicated,
poorly-annotated gene family where the reference lets you down. So we take the
union, and the final receptor set is a **hybrid** — 81 transcripts from the
genome-guided assembly and 17 that only the *de novo* assembly found. That hybrid
is what gets quantified in step 8.

> **Trinity itself is not in this repo.** The *de novo* assembly
> (`Transcriptomes_2023_2024.fasta`) was produced in an earlier project phase and
> its submission script is not part of this repository. The scripts here start
> from its TransDecoder output.

#### Reference genome assessment

Independent of the RNA-seq track, we characterise 14 tick genomes to provide
comparative context and to choose which assemblies the comparative analysis can
rely on.

```bash
sbatch 00_quast.sh            # array 0-13
sbatch 01_busco_genomes.sh    # array 0,2-6
```

`00_quast.sh` does something worth copying: it reads an `assembly_levels.tsv`
(`species<TAB>Chromosome|Scaffold|Contig`) and adds `--fragmented` only for the
assemblies that are not chromosome-level. Without that, QUAST reports misleading
misassembly statistics for draft genomes and you end up comparing apples to a
fruit salad.

#### Mapping

Build the index **once**, then map:

```bash
sbatch 03_histat_idex.sh      # once; wait for it
sbatch 03_hisat_main.sh       # array 1-32
```

Use `03_hisat_main.sh`. There is also `03_hisat.sh` — an earlier version that
expects `_R*_paired.fastq.gz` filenames from a Trimmomatic-based workflow we
abandoned. I kept it for provenance. It will not find your files.

HISAT2 runs with defaults and `-p 12`. Check the mapping rates; the script
concatenates all the `.err` files into one summary:

```bash
cat $TICKS/analysis/hisat/logs/concatenated_hisat2_mapping_rate.txt
```

#### SAM → BAM, and a note on three scripts

There are three `samTobam` scripts because I kept making this faster. Use
**`06_samTobam_gemini.sh`**:

```bash
sbatch 06_samTobam_gemini.sh  # array 1-16
```

| Script | What it does | Verdict |
|--------|--------------|---------|
| `05_samToBam.sh` | view → write BAM → sort → index, then merges inside array task 1 | superseded; the in-array merge is a race condition waiting to happen |
| `06_samTobam_gemini.sh` | `samtools view \| samtools sort` streamed in one pass, no intermediate BAM | **use this** |
| `06_samTobam_gpt.sh` | same, with an explicit node-local `/scratch` temp dir for sorting | use if your sort runs out of temp space |

The merge is now its own job, which is the right way round:

```bash
sbatch 07_merge_bam_dardel.sh   # waits for nothing; run after the array finishes
```

#### StringTie

```bash
sbatch 08_stringtie.sh
```

Run on the merged BAM, so you get one assembly across all tissues rather than 16
that you then have to reconcile. `-A gene_abundances.txt` gives per-gene coverage
as a free sanity check.

`08_stringtie2.sh` is an **incomplete stub** — it ends with a bare `stringtie`
call and no arguments. It is committed only because its parameter block documents
the reference GTF path. Do not submit it.

#### ORFs and redundancy

```bash
sbatch 06_Transdecoder_manual.sh
sbatch 07_cd-hit_2.sh
```

TransDecoder runs as `LongOrfs` then `Predict`, both with defaults.

`07_cd-hit_2.sh` is worth reading rather than just running. It collapses the
*de novo* peptides at **98 % identity** (`-c 0.98 -n 5 -M 0 -T 0`) and then does
three awk/sed passes that matter more than they look:

```bash
# 1. unwrap multi-line sequences into one line per record
awk '/^>/ {printf("\n%s\n",$0);next;} {printf("%s",$0);} END {printf("\n");}' in | sed "1d"
# 2. drop the '*' stop characters
awk '/^>/ {print $1; next} 1' step1 | sed 's/\*//g'
# 3. truncate headers at the first space
awk '{print $1;next}1' step2
```

Those three steps exist because of downstream failures I hit:
**InterProScan rejects sequences containing `*`**, and `seqkit grep -f` matches
IDs exactly, so a header with a trailing description silently fails to match your
ID list. Clean headers now or debug empty FASTA files later.

#### Why 0.98 here and 1.00 in step 4

This confused me for a while, so: the two CD-HIT runs answer different questions.

| Step | Threshold | Purpose |
|------|-----------|---------|
| `07_cd-hit_2.sh` (assembly) | `-c 0.98` | Collapse *assembly artefacts* — isoform fragments and near-identical duplicate contigs. Allowing 2 % divergence removes noise |
| `16_cd_hit_IRs_claudia.sh` (curation) | `-c 1.0`, `-l 199` | Collapse only *exact* duplicates. Receptor paralogues can be >98 % identical and are **biologically real** — collapsing them would delete genes from the repertoire |

Using 0.98 at the curation stage would quietly shrink the gene family you are
trying to count.

#### BUSCO

Four scripts, run as the assemblies were revised. `buco_claudia.sh` is the single
most complete summary — four runs covering both assemblies in both `protein` and
`transcriptome` mode:

```bash
sbatch buco_claudia.sh
```

Lineage is `arthropoda_odb10` everywhere. Two entry points appear across the
scripts (`run_BUSCO.py` from the Dardel BUSCO 6 module, `busco` from conda); the
difference is that the module needs `-l $BUSCO_LINEAGE_SETS/arthropoda_odb10`
while conda takes a bare `arthropoda_odb10`.

Read the results with:

```bash
grep "C:" $TICKS/analysis/busco/*/short_summary*.txt
```

### 4. BLAST curation

📁 [`02_annotation/01_blast_curation/`](../02_annotation/01_blast_curation/)

#### The three filters

A candidate is in the final set only if it clears all three:

1. **Homology** — reciprocal BLASTp at `e < 1e-5`, best hit by percent identity
2. **Domain architecture** — the family-diagnostic domain is present (step 5)
3. **Length** — ≥ 200 aa (shorter sequences are fragments)

#### Why reciprocal

The searches run in both directions and a candidate must satisfy both:

- **reference → tick** finds candidates. `15_blast_iGluRs_claudia.sh`,
  `12_blastp_proteomes.sh`
- **tick → reference** confirms them. `17_blast_IR_iGlur_cdhit100_db.sh`

One direction is not enough. An IR and an iGluR are homologous, and so are a PPK
and other DEG/ENaC channels. A one-way best hit tells you "this is in the
superfamily", not "this is the family I think it is". Only the reciprocal check
distinguishes them.

```bash
mkdir -p logs

# 1. non-redundant candidate set
sbatch 16_cd_hit_IRs_claudia.sh

# 2. both directions
sbatch 15_blast_iGluRs_claudia.sh
sbatch 17_blast_IR_iGlur_cdhit100_db.sh

# 3. the 80-receptor set against both proteomes
sbatch --array=0 12_blastp_proteomes.sh     # note the --array override

# 4. other families
sbatch 10_blastp_claudia_receptors.sh
sbatch 10_blast_claudia_receptors.sh
sbatch 10_blast_ref_TRP_PPKs.sh
sbatch 10_blast_GRfer_BMC.sh

# 5. extract sequences for the phylogeny (not a SLURM job)
bash 13_seqkit_receptores.sh
```

#### Three traps in this folder

These cost me time, so:

**⚠️ `12_blastp_proteomes.sh` has `--array=0-3` but only one query in the
`QUERIES` array.** The other three entries were removed during revision and the
array range was not. Because the script runs with `set -eu`, tasks 1–3 die on an
unbound variable. Submit it as `sbatch --array=0 12_blastp_proteomes.sh`, or put
the other query files back.

**⚠️ `best_hits_by_pident.py` must be copied next to the *output* directory**, not
run from where it lives. Several scripts look for `${OUT_DIR}/best_hits_by_pident.py`:

```bash
cp best_hits_by_pident.py $TICKS/analysis/blast/
cp best_hits_by_pident.py $TICKS/analysis/blast/blast_proteomes/
```

If it is missing, the scripts print a warning and **skip the best-hit step without
failing**. So you get a successful job and no `.csv`. Read the logs.

**⚠️ The 13th BLAST column is unlabelled.** The scripts request
`-outfmt "6 ... bitscore slen"` (13 columns) but `best_hits_by_pident.py` declares
only the 12 standard names, so pandas names the last column `12`. Best-hit
selection by `pident` is unaffected, but if you need `slen` — and you do, for
judging transcript completeness — read the raw `.tsv`, not the `.csv`.

#### The best-hit logic

```bash
python best_hits_by_pident.py input.tsv output.csv
```

Sorts by `pident` ↓, `evalue` ↑, `bitscore` ↓, `length` ↓ and keeps the first row
per query, with a stable mergesort so ties break deterministically. It writes a
valid empty CSV when there are no hits, so callers do not need to special-case it.

Note it ranks by **percent identity first, not e-value**. For a within-family
assignment among candidates that all clear `1e-5`, identity is the more direct
measure; e-value is length- and database-size-dependent and would favour long
partial matches.

### 5. InterProScan

📁 [`02_annotation/02_interproscan/`](../02_annotation/02_interproscan/)

Filter 2: confirm the domain architecture without using homology to our own
reference sets. This catches the case where BLAST gives a confident best hit to
the wrong family.

```bash
sbatch 09_InterPro_2.sh         # whole proteome: 24-48 h — start this early
sbatch 09_interpro_claudia.sh   # curated set: 1-2 h
```

Applications are deliberately restricted to `PANTHER,CDD,Pfam,SUPERFAMILY,TMHMM`.
The full default set adds SignalP, PRINTS, ProSite, Gene3D and more, takes several
times longer, and tells you nothing extra about these families.

#### Why TMHMM is in there

Topology is diagnostic, and it is the one signal that is independent of sequence
similarity:

| Family | Topology |
|--------|----------|
| IR / iGluR | 3 TM helices, large **extracellular** N-terminal domain |
| GR | 7 TM helices, **intracellular** N-terminus — *inverted* relative to a GPCR |

A candidate whose predicted topology contradicts its BLAST-assigned family gets
inspected by hand. That disagreement is informative, not noise.

#### The signatures to grep for

| Family | Signature | Name |
|--------|-----------|------|
| IR / iGluR | `PF00060` | Lig_chan |
| iGluR | `PF01094` | ANF_receptor (N-terminal domain) |
| GR | `PF08395` | 7tm_7 |
| PPK | `PF00858` | ASC (DEG/ENaC) |
| TRP | `PF00520` | Ion_trans |

```bash
# candidates carrying the Lig_chan domain
awk -F'\t' '$5=="PF00060" {print $1}' Iric_de_novo_interPro.tsv | sort -u

# TM helix count per sequence
awk -F'\t' '$4=="TMHMM" {c[$1]++} END {for (s in c) print s"\t"c[s]}' *.tsv
```

**Two gotchas:** strip trailing `*` from your peptides first (step 3 does this),
and note that `09_interpro_claudia.sh` **skips any query whose `.tsv` already
exists** — delete the output to force a re-run.

### 6. Phylogeny

📁 [`03_phylogeny/`](../03_phylogeny/)

```bash
sbatch --array=0-3 14_phylotree.sh    # 6-24 h per task, 16 cores
```

| Task | Family |
|------|--------|
| 0 | GR |
| 1 | PPK |
| 2 | TRP |
| 3 | IR |

The committed script has `--array=3` because the IR tree was the last one re-run.
Override it on the command line.

Two steps per task:

```bash
mafft --auto --thread 16 in.fasta > aln.fasta
iqtree -s aln.fasta -m MFP -merit BIC -B 1000 -T 16 --prefix p -redo
```

`--auto` lets MAFFT pick its own strategy from the number and length of sequences
(L-INS-i for small sets, FFT-NS-2 for large ones). `-m MFP` is ModelFinder Plus,
selecting the substitution model by **BIC** before inferring the tree.

#### Why there is no trimAl step

This is a deliberate omission, and reviewers ask about it.

These receptors are divergent, and the variable regions between the conserved
domains carry real phylogenetic signal. Gap-threshold trimming removes exactly
those columns. IQ-TREE's rate-heterogeneity models already handle site-rate
variation, which is the problem trimming is meant to address. So we align and
infer without trimming — and if you add a trimming step, say so explicitly,
because it changes the topology.

#### Reading the support values — the one that bites

`-B 1000` is **ultrafast bootstrap (UFBoot)**, not `-b` standard bootstrap. The
scales are different and not interchangeable:

| Method | "Well supported" |
|--------|------------------|
| UFBoot (`-B`) | **≥ 95** |
| Standard bootstrap (`-b`) | ≥ 70 |

Calling a UFBoot value of 75 "well supported" because you are thinking in
standard-bootstrap terms is a real and easy mistake.

#### Outputs

| File | Use |
|------|-----|
| `<prefix>.treefile` | the tree — load this into iTOL |
| `<prefix>_mafft.fasta` | the alignment — **also the input to step 7** |
| `<prefix>.iqtree` | full report, including the selected model |

```bash
grep "Best-fit model" $TICKS/analysis/phylo/IR_phylo/IR_phylo.iqtree
```

⚠️ **`-redo` overwrites previous results without asking.** Remove it if you want
IQ-TREE to resume from its checkpoint. And MAFFT is skipped when the alignment
already exists, so re-running only redoes the tree — delete the alignment to
force re-alignment.

### 7. IR vs. iGluR: the residue analysis

📁 [`02_annotation/04_residue_analysis_IR/`](../02_annotation/04_residue_analysis_IR/)

```bash
conda activate ticks_py
jupyter notebook Residues_iGluRs_IRs.ipynb
```

#### The logic

IRs evolved from iGluRs and lost glutamate binding. iGluRs bind glutamate through
conserved residues in the S1/S2 lobes of the ligand-binding domain; in IRs those
residues are substituted. So the functional distinction is readable directly off
the alignment:

| Position | Expected | Role |
|----------|----------|------|
| 391 | `R` | arginine — binds the glutamate α-carboxyl |
| 455 | `T`/`S` | S1 lobe hydroxyl contact |
| 496 | `D`/`E` | acidic residue binding the glutamate α-amino group |

All three present → glutamate-binding **iGluR**. Substitution at the arginine or
the acidic position → **IR**.

This is the criterion the paper uses, rather than BLAST identity or tree position,
because both of those can be ambiguous for a divergent receptor: identity between
a divergent IR and an iGluR can be high enough to be uninformative, and tree
placement can be driven by long-branch attraction. The residue state is a direct
functional readout.

#### ⚠️ The positions are alignment-specific

This is the single most important warning in this guide. **Those column numbers
are indices into one specific alignment.** Add or remove a sequence, re-run MAFFT,
and they all shift. The notebook keeps the history as commented-out lines, which
tells you how often this happened:

| Alignment | Positions |
|-----------|-----------|
| 1 | 537, 717, 717, 748, 748 |
| 2 | 1093, 1403, 1403, 1468, 1468 |
| 3 | 551, 742, 742, 787, 787 |
| **current** | **391, 455, 455, 496, 496** |

If you re-align, **re-derive the indices**: find the residues in a reference iGluR
(*D. melanogaster* GluRIIA, or rat GluA2) and read off its aligned column numbers.

And then check your work — **the known iGluR references must come back as matches
at all positions.** If they do not, your indices are wrong for this alignment, and
every IR/iGluR call downstream is wrong too. This is a 30-second check that
protects the paper's main taxonomic claim.

Output: `residues_iGluR_IRsZAIDE.xlsx`, plus the same table as TSV on stdout for
pasting into the supplement. **Ship the alignment with the table** — without it the
positions cannot be verified.

### 8. GR motif discovery

📁 [`02_annotation/03_motif_discovery_GR/`](../02_annotation/03_motif_discovery_GR/)

> ⚠️ **Reconstructed step.** Rebuilt from the surviving `meme.html` /
> `tomtom.html` / `fimo.html` headers. Parameters are those in the reports.

Three steps, strictly in order:

```bash
sbatch meme_motif_discovery.sh   # ~30 min
# wait, then:
sbatch tomtom_cross_species.sh
sbatch fimo_scan.sh
```

#### MEME — discover

```bash
cd-hit -i Iric_GR.fasta -o Iric_GR_nr.fasta -c 0.90 -n 5     # Iric ONLY
fasta-shuffle-letters -kmer 1 -seed 42 input > shuffled
meme input -neg shuffled -objfun de -protein -nmotifs 1 -maxw 12 -oc out
```

Every one of those choices is load-bearing:

| Parameter | Why |
|-----------|-----|
| `-objfun de` + `-neg` | Differential enrichment against a shuffled control. A motif that is just amino-acid composition bias scores no better than the control and does not survive |
| `-kmer 1 -seed 42` | The control preserves composition and length distribution **exactly**. Fixed seed so the control is reproducible — an unseeded shuffle makes your E-values unrepeatable |
| `-nmotifs 1` | The question is whether *a* shared motif exists, not an exhaustive catalogue |
| `-maxw 12` | Upper bound on width |
| `-c 0.90` **Iric only** | *I. ricinus* GRs include recent tandem duplicates. Without this, MEME recovers a motif driven entirely by one expanded clade — you find a within-clade signature and mistake it for a family-wide one. Abru and Dmel sets are already non-redundant and pass through unchanged |

Check that MEME found something real before going on:

```bash
grep -A2 'MOTIF' $TICKS/analysis/meme/Iric/meme_run/meme.txt | head -20
```

A motif with E-value > 0.05 should not be carried forward, no matter how pretty
the logo is.

#### TOMTOM and FIMO — why both

They answer different questions, and you need both:

- **TOMTOM** compares *motif to motif*. It asks: is the motif MEME found
  independently in *I. ricinus* the **same motif** it found in *Argiope* and in
  *Drosophila*?
- **FIMO** compares *motif to sequences*. It asks: **which individual
  *Drosophila* GRs** actually carry the tick motif, and how significantly?

TOMTOM establishes correspondence; FIMO localises it to specific genes. One
without the other is half an argument.

```bash
tomtom -oc out Iric/meme.txt Abru/meme.txt     # and Iric vs Dmel
fimo --oc out --thresh 0.05 --qv-thresh Iric/meme.txt Dmel_GR.fasta
```

Note `--qv-thresh`: it makes `--thresh` apply to the **q-value**, so this reports
matches at *q* < 0.05 — FDR-corrected across every position scanned. Without that
flag you would be reporting raw *p*-values across tens of thousands of positions,
which means reporting noise.

### 9. Chromosomal mapping

📁 [`04_chromosomal_mapping/`](../04_chromosomal_mapping/)

```bash
sbatch 11_miniprot_claudia.sh    # ~1-2 h, 16 cores, 80 GB
```

#### Why this analysis carries weight

The tree alone cannot distinguish two very different histories:

- a clade of similar receptors sitting in a **tandem array** on one chromosome →
  recent local duplication
- the same clade **dispersed** across chromosomes → retention from an older,
  already-diversified ancestral set

Same topology, opposite conclusion. The physical arrangement is what decides, and
it is why the paper says *ancestral* clustering. This is also why the mapping uses
the chromosome-level **GCA_964199275.3**, not the scaffold assembly used for read
mapping — on scaffolds you cannot tell dispersal from assembly fragmentation.

#### Why miniprot

It is splice-aware: it aligns a protein directly to genomic DNA across introns and
emits exon structure as GFF. BLAT or tBLASTn give you hit coordinates without
coherent exon structure, and exonerate is far slower for a whole genome.

The script is written to be re-run per family. Edit the `CONFIG` block:

```bash
QUERY="${TICKS}/data/phylo/IR_iGluR_final_80.fasta"
LABEL="IR_80"      # goes into the output filename — change it, or you overwrite
```

Genome indexing and the chromosome-length table are skipped if they exist, so
repeat runs are cheap.

#### ⚠️ Check for multi-hit receptors before plotting

```bash
grep -c $'\tmRNA\t' $TICKS/analysis/miniprot/IR_80_miniprot.gff
```

If this exceeds your query count, some proteins aligned to more than one locus —
paralogues, or a real duplication. **Inspect those by hand.** The ideogram notebook
aggregates by gene ID with `min(start)`/`max(end)`, which would merge two genuinely
separate loci into one enormous span across the chromosome. That is a wrong figure
that looks fine.

### 10. Expression quantification

📁 [`05_expression/`](../05_expression/)

```bash
sbatch 18_hybrid_cds_builder.sh   # must report 98 sequences
sbatch 19_kallisto_claudia.sh     # index, once
sbatch 20_kallisto_quent.sh                # unstranded
sbatch 20_kallisto_quent_RFstranded.sh     # --rf-stranded
sbatch 20_kallisto_quent_fr-stranded.sh    # --fr-stranded
```

#### The hybrid CDS set

`18_hybrid_cds_builder.sh` pulls 81 StringTie + 17 Trinity transcripts by ID list
into one 98-sequence FASTA — each receptor represented by the best CDS available
for it, from whichever assembly recovered it properly. The script verifies the
count and lists any missing IDs. **If it does not say 98, stop and fix it**; a
silently-missing receptor becomes an absent gene in your results.

#### ⚠️ How to read these TPMs

kallisto quantifies against the index you give it, and TPM is normalised over
that index. Because the index is 98 receptor transcripts rather than the whole
transcriptome, **these TPMs are relative abundances within the receptor set.**

They are valid for what the paper claims — comparing one receptor across tissues,
and receptors against each other. They are **not** whole-transcriptome TPMs and
must not be compared to published transcriptome-wide values. Say so in the methods;
it is the kind of thing a careful reviewer checks.

#### Why three quantification scripts

Because strandedness was **determined empirically rather than assumed**. The wrong
setting roughly halves the pseudoalignment rate, which is unmistakable once you
look. Run all three, then compare:

```bash
for d in $TICKS/analysis/kallisto{,/frstranded,/rfstranded}/*/; do
    printf '%-60s ' "$d"
    python3 -c "import json;print(json.load(open('$d/run_info.json'))['p_pseudoaligned'])" 2>/dev/null || echo -
done
```

Keep the stranded setting whose rate matches the unstranded run; the other will be
visibly worse. For the dUTP-based Illumina stranded mRNA kits, `--rf-stranded` is
the expected answer — but **verify it**, and state which setting you used.

#### ⚠️ The index filename mismatch

This one will stop you, so fix it before you submit:

| Script | Filename it uses |
|--------|------------------|
| `18_hybrid_cds_builder.sh` writes | `hybrid_CDS_receptors.fasta` |
| `19_kallisto_claudia.sh` reads/writes | `hybrid_CDS_full.fasta` → `hybrid_CDS_full.idx` |
| `20_*_stranded.sh` read | `hybrid_CDS_receptors.idx` |
| `20_kallisto_quent.sh` reads | `hybrid_CDS_full.idx` |

Pick one name and make all four agree. Otherwise the stranded runs die on the
missing-index check — which is at least a loud failure, unlike most of the traps
in this pipeline.

Also: `18_hybrid_cds_builder.sh` flags its `GG_CDS` / `DN_CDS` paths with a `⚠️`
in the script itself. Confirm your actual TransDecoder output filenames first.

#### The sample sheet

`kallisto_samples.txt`, tab-separated, no header, exactly 16 lines in array order:

```
file_prefix<TAB>sample_name<TAB>tissue<TAB>sex
P12345_101_S1_L001	F1	appendages	F
P12345_102_S2_L001	F1	body	F
```

`file_prefix` must reproduce the trimmed filename exactly — the scripts append
`_R1_001_val_1.fq.gz`. Output directories are `<sample_name>_<tissue>`, so those
two columns together must be unique or you will overwrite results.

One more thing: `-b` is absent, so there are **no bootstrap replicates**. If you
want to run sleuth for differential testing, add `-b 100` and re-quantify.

### 11. Figures

📁 [`06_figures/`](../06_figures/)

| Figure | Made with |
|--------|-----------|
| Chromosomal ideogram | `IdeoGram.ipynb` → **MG2C v2.1** (web) |
| Phylogenies | `.treefile` → **iTOL v6** |
| Expression heatmaps | TPM matrices from step 10 |
| Motif logos | `meme.html` / `tomtom.html` |
| QC summary | `multiqc_report_raw.html` |
| Final panels | Illustrator |

`IdeoGram.ipynb` prepares the two files MG2C needs — a per-gene table
(`gene_id, gene_start, gene_end, chr_id, gene_color`) and a chromosome-length
table. MG2C is a web tool, so the notebook stops at the inputs and the plot comes
out of the browser as SVG.

Its colour rule is worth knowing: `mRNA` → black, and `CDS` → **red when it is the
first or last CDS of its parent**. That marks terminal exons, which is what makes
short single-exon alignments visually distinguishable from multi-exon genes.

⚠️ **The paths in cells 2 and 7 point at an old *Argiope* analysis**
(`Spiders_Project/.../GCA_015342795.1`) and the length table in cell 8 is a leftover
example. Update them to your *I. ricinus* paths. And keep only the chromosome-scale
scaffolds (`OX3874*` for IXRI_v3) — unplaced contigs make the ideogram unreadable.

---

## Quick reference: full run order

```bash
export TICKS=/cfs/klemming/projects/supr/naiss2023-23-109/Ticks
mkdir -p logs

# ── 1. QC and trimming ──
sbatch fastqc.sh
sbatch trimgalore.sh
sbatch kraken2.sh

# ── 2. Assembly ──
sbatch 03_histat_idex.sh                 # wait
sbatch 03_hisat_main.sh                  # array 1-32, wait
sbatch 06_samTobam_gemini.sh             # array 1-16, wait
sbatch 07_merge_bam_dardel.sh            # wait
sbatch 08_stringtie.sh                   # wait
sbatch 06_Transdecoder_manual.sh         # wait
sbatch 07_cd-hit_2.sh
sbatch buco_claudia.sh

# ── 3. Annotation ──
sbatch 09_InterPro_2.sh                  # start early, runs 1-2 days
sbatch 16_cd_hit_IRs_claudia.sh
sbatch 15_blast_iGluRs_claudia.sh
sbatch 17_blast_IR_iGlur_cdhit100_db.sh
sbatch --array=0 12_blastp_proteomes.sh
sbatch 09_interpro_claudia.sh
bash   13_seqkit_receptores.sh

# ── 4. Downstream (parallel) ──
sbatch --array=0-3 14_phylotree.sh
sbatch 11_miniprot_claudia.sh
sbatch meme_motif_discovery.sh           # wait
sbatch tomtom_cross_species.sh
sbatch fimo_scan.sh
sbatch 18_hybrid_cds_builder.sh          # wait
sbatch 19_kallisto_claudia.sh            # wait
sbatch 20_kallisto_quent.sh
sbatch 20_kallisto_quent_RFstranded.sh

# ── 5. Notebooks ──
# Residues_iGluRs_IRs.ipynb   (needs the MAFFT alignment from 14_phylotree.sh)
# IdeoGram.ipynb              (needs the miniprot GFF)
```

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| Job dies instantly, no useful error | `logs/` does not exist — `mkdir -p logs` |
| `Invalid account` | wrong `#SBATCH -A`; the allocation changed three times |
| File-not-found on a path that looks right | `naiss2023-23-109` vs `naiss2025-23-132` — the storage and compute projects differ |
| BLAST ran, no `*_BestByPident.csv` | `best_hits_by_pident.py` not copied next to `OUT_DIR`; check the log for the warning |
| Array tasks 1–3 fail with unbound variable | `12_blastp_proteomes.sh` — use `--array=0` |
| InterProScan errors on your FASTA | trailing `*` stop characters; see step 3 |
| `seqkit grep` returns an empty FASTA | header has text after the ID; truncate at the first space |
| kallisto: index not found | the `hybrid_CDS_full` / `hybrid_CDS_receptors` name mismatch |
| kallisto pseudoalignment ~35 % | wrong strandedness — try the other variant |
| Kraken2 killed by OOM | standard DB needs ~50 GB resident |
| Residue table: references do not match | alignment positions are stale — re-derive them |
| IQ-TREE overwrote your previous run | `-redo` is in the command line |
| Ideogram shows one gene spanning a chromosome | a multi-locus miniprot hit got aggregated |

---

## A closing thought

Most of the time in this project did not go into running tools. It went into
noticing that a result was quietly wrong — a CD-HIT threshold that deleted real
paralogues, alignment positions that had drifted by 150 columns, an array range
that no longer matched its input list, a best-hit step that skipped itself and
reported success. None of those fail loudly. The pipeline runs, the figures look
fine, and the conclusion is wrong.

So the habit worth taking from this guide is not any particular parameter. It is
checking the thing you expect to be true: that the iGluR references really do match
at all five residue positions, that the hybrid CDS really has 98 sequences, that
the receptor count in the GFF really equals the number of proteins you submitted.
Each check takes under a minute and each one caught something real here.

And write it down as you go. I reconstructed two steps of this pipeline from HTML
reports because the scripts were gone — it worked, but only because the tools
happened to record their own command lines. Do not count on that twice.

> *"The most dangerous phrase in the language is, 'We've always done it this
> way.'"* — Grace Hopper

I hope you finish on time!!!

---

**Questions:** [zaide_katherine.montes_ortiz@biol.lu.se](mailto:zaide_katherine.montes_ortiz@biol.lu.se)
· [@lachemontes](https://github.com/lachemontes)
