# ticks_project

ticks_project/
├── README.md                          ← Overview + ruta rápida al Manual
├── LICENSE                            ← MIT o similar
├── .gitignore                         ← Para no subir datos grandes
│
├── Manual/
│   └── GuideYou.md                    ← La guía principal paso a paso
│
├── 01_data_processing/
│   ├── 01_qc_trimming/
│   │   ├── fastqc.sh
│   │   ├── trimgalore.sh
│   │   └── README.md
│   ├── 02_taxonomic_classification/
│   │   ├── kraken2.sh
│   │   └── README.md
│   └── 03_transcriptome_assembly/
│       ├── hisat2_mapping.sh
│       ├── stringtie2.sh
│       ├── trinity.sh
│       ├── transdecoder.sh
│       ├── cdhit.sh
│       └── README.md
│
├── 02_annotation/
│   ├── 01_blast_curation/
│   │   ├── blast_vs_dmel.sh
│   │   ├── blast_vs_abru.sh
│   │   └── README.md
│   ├── 02_interproscan/
│   │   ├── run_interproscan.sh
│   │   └── README.md
│   ├── 03_motif_discovery_GR/
│   │   ├── meme_motif_discovery.sh
│   │   ├── tomtom_cross_species.sh
│   │   ├── fimo_scan.sh
│   │   └── README.md
│   └── 04_residue_analysis_IR/
│       ├── alignment_residues.py
│       └── README.md
│
├── 03_phylogeny/
│   ├── mafft_align.sh
│   ├── trimal.sh
│   ├── iqtree.sh
│   ├── itol_annotations.txt
│   └── README.md
│
├── 04_chromosomal_mapping/
│   ├── miniprot.sh
│   ├── mg2c_input_prep.py
│   └── README.md
│
├── 05_expression/
│   ├── kallisto_index.sh
│   ├── kallisto_quant.sh
│   ├── tpm_analysis.R
│   ├── heatmaps.R
│   └── README.md
│
├── 06_figures/
│   ├── fig1_qc.R
│   ├── fig2_IR_phylogeny.R
│   ├── fig3_GR_phylogeny.R
│   ├── fig4_TRP_PPK.R
│   ├── chromosome_ideogram.py
│   └── README.md
│
└── Supplementary/
    ├── additional_file_1_qc.xlsx
    ├── additional_file_2_annotation.xlsx
    ├── additional_file_3_phylogeny/
    └── additional_file_4_expression.xlsx
