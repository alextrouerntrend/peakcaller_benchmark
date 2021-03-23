## Benchmarking Peakcallers For ATAC-Seq
This repository is a publicly available benchmark of recent peak calling tools used for ATAC-seq data analysis. All steps have been written for the Scripps Garibaldi HPC cluster based on its available modules and appropriate headers for the Slurm scheduler that can be modified to run. Commands should never be executed on the head node of any HPC machine. If working on the Garibaldi cluster, you should use `sbatch scriptname` after modifying the script for each stage.

Contents

1. Overview
2. Downloading data from GEO

#### Overview
Assay for Transposase Accessible Chromatin Sequencing (ATAC-seq) data is analyzed by tools designed for predecessor genomic genrichment assays, such as the ubiquitous [ChIP-seq](1). Here I document the benchmarking of several of these tools within a standard ATAC-seq pipeline for differential peak analysis. The tools included in the benchmarking are as follows.
* MACS2
* Genrich

#### Downloading data from GEO
We will use ATAC-seq data generated for the paper [Runx3 pioneers chromatin accessibility of cis-regulatory landscapes that drive memory CTL formation](https://doi.org/10.1016/j.immuni.2018.03.028). 
Download the data then unzip from NCBI's Gene Expression Omnibus (GEO) with the script [data_retrieval.slurm](./scripts/data_retrieval.slurm):

```bash
#!/bin/bash
#SBATCH --job-name=data_retrieval
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ATrouern-Trend@scripps.edu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=200mb
#SBATCH -o dataret.%j.out
#SBATCH -e dataret.%j.err

# Find project base directory
BASE_DIR=$( pwd | rev | cut -d'/' -f2- | rev )

# Make raw data directory
mkdir $BASE_DIR/raw_data

# Download files from GEO
wget -O $BASE_DIR/raw_data/data.tar "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE111149&f
ormat=file"

```




