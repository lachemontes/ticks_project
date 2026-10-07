# 02.01 — BLAST-based receptor curation

## Purpose

Find chemosensory receptor candidates in the two *I. ricinus* proteomes
(genome-guided and *de novo*), confirm them against curated reference sets, and
reduce them to one non-redundant sequence per locus.

The searches run in **both directions** on purpose:

- *reference → tick* finds candidates we would otherwise miss
  (`15_blast_iGluRs.sh`, `10_blast_*.sh`, `12_blastp_proteomes.sh`);
- *tick → reference* confirms that each candidate's best match really is the
  intended family rather than a paralogous channel
  (`17_blast_IR_iGlur_cdhit100_db.sh`).

A candidate is retained when both directions agree.

## Scripts

| Script | Tool | Query → Database | Description |
|--------|------|------------------|-------------|
| `10_blast_receptors.sh` | tBLASTn | PPK, TRP references → *I. ricinus* **genome** | Locates receptor loci in genomic sequence; builds `Iricinus_genomic_DB` |
| `10_blastp_receptors.sh` | BLASTp | PPK, TRP references → *I. ricinus* OGS1.3 proteins | Protein-level equivalent of the above |
| `10_blast_GRfer_BMC.sh` | BLASTp | `GR_ref.fasta` → `GR_BMC_proteins.fasta` | Validates the curated GR set against the references |
| `10_blast_ref_TRP_PPKs.sh` | BLASTp | `PPK_ref`, `TRP_ref` → the curated PPK/TRP sets | Same validation for PPKs and TRPs, as a two-entry loop |
| `10_blast_9new_danda.sh` | `seqkit grep` + BLASTp | 9 new iGluR candidates → both proteomes | Follow-up on 9 sequences added late in curation; IDs are hard-coded in the script |
| `12_blastp_proteomes.sh` | BLASTp | `IR_iGluR_final_80.fasta` → genome-guided **and** *de novo* proteomes | SLURM array; the search that establishes which of the 80 receptors are present in which assembly. Reports `slen` so transcript completeness can be compared |
| `15_blast_iGluRs.sh` | BLASTp | `IR_iGluRs_Dmel_abru.fasta` → `IR_iGlur_cdhit100.fasta` | Reference → tick direction for IRs/iGluRs |
| `17_blast_IR_iGlur_cdhit100_db.sh` | BLASTp | `IR_iGlur_cdhit100.fasta` → `IR_iGluRs_Dmel_abru.fasta` | Reciprocal of `15_`; the confirmation step |
| `16_cd_hit_IRs.sh` | seqkit + CD-HIT | — | Strips gaps, then collapses IR/iGluR candidates at **100 % identity** and drops sequences **< 200 aa** |
| `13_seqkit_receptores.sh` | seqkit | — | Pulls CDS and peptide sequences for GR / PPK / TRP from both assemblies using ID lists; reports which IDs failed to match |
| `best_hits_by_pident.py` | Python/pandas | — | Reduces an outfmt-6 table to one best hit per query |

### `best_hits_by_pident.py`

```bash
python best_hits_by_pident.py input.tsv output.csv
```

Sorts by `pident` desc → `evalue` asc → `bitscore` desc → `length` desc and keeps
the first row per `qseqid` (stable mergesort, so ties are broken deterministically).
Writes a valid empty CSV when there are no hits, so the calling scripts do not
need to special-case that.

> **Known limitation.** The script declares the 12 standard outfmt-6 columns, but
> most of the BLAST scripts here request 13 (`... bitscore slen`). pandas assigns
> the 13th column the integer name `12`; `pident`-based selection is unaffected,
> but `slen` is unlabelled in the output CSV. Read the raw `.tsv` when you need
> subject lengths.

## Input

Reference and curated sets live in `data/blast_resorces/` *(sic — the typo is in
the cluster paths and the scripts)*:

| File | Content |
|------|---------|
| `IR_iGluRs_Dmel_abru.fasta` | Curated IR + iGluR references, *D. melanogaster* and *A. bruennichi* |
| `GR_ref.fasta`, `PPK_ref.fasta`, `TRP_ref.fasta` | Reference sets per family |
| `GR_BMC_proteins.fasta`, `PPK_BMC_proteins.fasta`, `TRP_BMC_proteins.fasta` | The curated tick sets for this paper |
| `iricinus_ass1.0_annotOGS1.3_proteins.fa` | Published *I. ricinus* official gene set |

Searchable proteomes, from [`../../01_data_processing/03_transcriptome_assembly/`](../../01_data_processing/03_transcriptome_assembly/):

- genome-guided: `analysis/cd-hit/transcripts_final_busco_inter_pep.fasta`
- *de novo*: `Transcriptomes_2023_2024.fasta.transdecoder.pep`

Queries for the phylogeny track are in `data/phylo/`
(`IR_iGluR_final_80.fasta`, `IR_danda.fasta`).

ID lists for `13_seqkit_receptores.sh` (`GR_trinity.txt`, `PPKs_strg.txt`, …)
live in `data/transcriptomes/`.

## Output

| File pattern | Content |
|--------------|---------|
| `analysis/blast/**/*_blastp.tsv` | Raw outfmt-6 hits (13 columns incl. `slen`) |
| `analysis/blast/**/*_BestByPident.csv` | One best hit per query |
| `analysis/blast/*_vs_Iricinus.txt` | tBLASTn hits against the genome |
| `analysis/blast/db*/` | BLAST databases (rebuilt only if absent) |
| `data/phylo/IR_iGlur_cdhit100.fasta` | Non-redundant IR/iGluR candidates |
| `data/phylo/IR_iGlur_clean.fasta` | Gap-stripped intermediate |
| `data/receptores_seq/<FAMILY>_<source>_{cds,pep}.fasta` | Extracted receptor sequences |
| `data/receptores_seq/*_missing.txt` | IDs that did not match exactly |

## Software versions

| Tool | Version | Key parameters |
|------|---------|----------------|
| BLAST+ | 2.9.0+ | `-evalue 1e-5`, `-max_target_seqs 10` (5 for the tBLASTn runs), `-outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore slen"` |
| CD-HIT | 4.8.1 | `-c 1.0 -n 5 -l 199 -M 14000 -T 8` |
| seqkit | 2.3.1 | `grep -f` (exact ID match), `seq -g` (strip gaps) |
| Python | 3.11 + pandas 2.x | for `best_hits_by_pident.py` |

`makeblastdb` is always called with `-parse_seqids` so that `blastdbcmd` can
retrieve sequences by accession afterwards.

## How to run

```bash
mkdir -p logs

# 1. Non-redundant IR/iGluR candidate set
sbatch 16_cd_hit_IRs.sh

# 2. Both BLAST directions
sbatch 15_blast_iGluRs.sh          # reference -> tick
sbatch 17_blast_IR_iGlur_cdhit100_db.sh    # tick -> reference

# 3. The 80-receptor set against both proteomes
sbatch 12_blastp_proteomes.sh              # array; see note below

# 4. Other families
sbatch 10_blastp_receptors.sh
sbatch 10_blast_receptors.sh
sbatch 10_blast_ref_TRP_PPKs.sh
sbatch 10_blast_GRfer_BMC.sh

# 5. Extract sequences for the phylogeny
bash 13_seqkit_receptores.sh               # not a SLURM job; needs seqkit on PATH
```

Notes:

- **`12_blastp_proteomes.sh` has `--array=0-3` but only one entry in `QUERIES`.**
  Submit it as `sbatch --array=0 12_blastp_proteomes.sh`, or add the other three
  query files back to the array. As written, tasks 1–3 fail with an unbound
  variable (`set -eu`).
- Several scripts expect `best_hits_by_pident.py` **next to the output
  directory**, not next to themselves (`${OUT_DIR}/best_hits_by_pident.py`).
  Copy it there before submitting:
  ```bash
  cp best_hits_by_pident.py $TICKS/analysis/blast/
  cp best_hits_by_pident.py $TICKS/analysis/blast/blast_proteomes/
  ```
  Scripts that cannot find it print a warning and skip the best-hit step rather
  than failing, so check the logs.
- The best-hit step needs **pandas**; the scripts try `conda activate Gassembly`.
- `13_seqkit_receptores.sh` has no `#SBATCH` header — run it on a login node or
  wrap it in your own job.
