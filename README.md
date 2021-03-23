## Benchmarking Peakcallers For ATAC-Seq
This repository is a publicly available benchmark of recent peak calling tools used for ATAC-seq data analysis. All steps have been written for the Scripps Garibaldi HPC cluster based on its available modules and appropriate headers for the Slurm scheduler that can be modified to run. Commands should never be executed on the head node of any HPC machine. If working on the Garibaldi cluster, you should use `sbatch scriptname` after modifying the script for each stage.

Contents

1. Overview
2. Acessing the Data using ...
3. OK
#### Introduction
Assay for Transposase Accessible Chromatin Sequencing (ATAC-seq) data is analyzed by tools designed for predecessor genomic genrichment assays, such as the ubiquitous [ChIP-seq](1). Here I document the benchmarking of several of these tools within a standard ATAC-seq pipeline for differential peak analysis. The tools included in the benchmarking are as follows.
* MACS2
* Genrich

#### Data

#### Pipeline


