## Benchmarking Peakcallers For ATAC-Seq
This repository is a publicly available benchmark of recent peak calling tools used for ATAC-seq data analysis. All steps have been written for the Scripps Garibaldi HPC cluster based on its available modules and appropriate headers for the Slurm scheduler that can be modified to run. Commands should never be executed on the head node of any HPC machine. If working on the Garibaldi cluster, you should use `sbatch scriptname` after modifying the script for each stage.

Contents

1. Overview
2. Downloading data from SRA

### Overview
Assay for Transposase Accessible Chromatin Sequencing (ATAC-seq) data is analyzed by tools designed for predecessor genomic genrichment assays, such as the ubiquitous [ChIP-seq](1). Here I document the benchmarking of several of these tools within a standard ATAC-seq pipeline for differential peak analysis. The tools included in the benchmarking are as follows.
* MACS2
* Genrich

### Downloading data from SRA
We will use ATAC-seq data generated by Wang and Diao *et al.* for the paper [*Runx3 pioneers chromatin accessibility of cis-regulatory landscapes that drive memory CTL formation*](https://doi.org/10.1016/j.immuni.2018.03.028). 
Download the data then unzip from NCBI's Sequence Read Archive (SRA) with the script [data_retrieval.slurm](./scripts/data_retrieval.slurm):

```bash
#!/bin/bash
#SBATCH --job-name=data_retrieval
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ATrouern-Trend@scripps.edu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=2gb
#SBATCH -o dataret.%j.out
#SBATCH -e dataret.%j.err

BIOPROJECT=PRJNA436008

# Find project base directory
BASE_DIR=$( pwd | rev | cut -d'/' -f2- | rev )

# Make raw data directory
mkdir $BASE_DIR/raw_data

# Download RunInfo table for BioProject
wget 'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&rettype=runinfo&db=sra&term='${BIOPROJECT} -O - | tee $BASE_DIR/raw_data/SraRunInfo.csv

# Use RunInfo to guide SRA downloads
esearch -db sra -query $BIOPROJECT | efetch -format runinfo | cut -d',' -f 1 | grep SRR | xargs -n 1 -P 12 fastq-dump -O $BASE_DIR/raw_data --split-files
# Match run with BioSample
cd $BASE_DIR/raw_data

declare -a BIOSAMPLES
BIOSAMPLES=( $(cut -d, -f26 $BASE_DIR/raw_data/SraRunInfo.csv | grep SAM | sort | uniq | tr '\n' ' ' ) )

# Concatenate runs for each BioSample
for i in ${BIOSAMPLES[@]}; do
    RUNS=( $(cat $BASE_DIR/raw_data/SraRunInfo.csv | grep $i | cut -d, -f1 | tr '\n' ' ') )
    echo concatenating biosample $i runs: "${RUNS[*]}"
    RUNS1=( "${RUNS[@]/%/_1.fastq}" )
    RUNS2=( "${RUNS[@]/%/_2.fastq}" )
    cat "${RUNS1}" > ${i}_1.fastq
    cat "${RUNS2}" > ${i}_2.fastq
done

# Clean house
rm SRR*.fastq

```

[data_retrieval.slurm](./scripts/data_retrieval.slurm) downloads the metadata (saved as SraRunInfo.csv) for a given [NCBI Bioproject](https://www.ncbi.nlm.nih.gov/bioproject) and uses the 'Run' and 'Biosample' fields from that metadata to guide the concatenation of multiple files representing the same sample sequenced across multiple lanes. 

Data is pulled from SRA using the command-line utility, [EDirect](https://dataguide.nlm.nih.gov/edirect/documentation.html). The download command, fastq-dump, is parallelized across 12 cores by xargs. I have EDirect installed in my home directory and the path is added to my $PATH variable, which lets me call the functions without referencing location. You can install EDirect with the following command: `sh -c "$(wget -q ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh -O -)"`

### Quality control with FastQC
Quality control reports can be generated with [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/). Running the program on both pre-trimming and post-trimming reads will give help to visualize the effect of adaptor/quality trimming on each library. Here, I load fastqc/0.11.4 which is installed as a module on Garibaldi.


```bash
#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ATrouern-Trend@scripps.edu
#SBATCH --partition=flits
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=4gb
#SBATCH -o fastqc_pretrim.%j.out
#SBATCH -e fastqc_pretrim.%j.err

module load fastqc

# Line 29 can be commented out and 32 uncommented after read trimming with cutadapt to get post-trimming QC report.

BASE_DIR=$( pwd | rev | cut -d'/' -f2- | rev )

# Check for fastQC directory and make if doesn't exist
if [[ ! -d "${BASE_DIR}/fastqc" ]]; then
    mkdir -p ${BASE_DIR}/fastqc/pretrim
fi
if [[ ! -d "${BASE_DIR}/fastqc/posttrim" ]]; then
    mkdir ${BASE_DIR}/fastqc/posttrim
fi

# Pretrimming FastQC
READS=( ${BASE_DIR}/raw_data/* )
echo "${READS[@]}" | xargs -n 4 fastqc -t 4 -o ${BASE_DIR}/fastqc/pretrim -f fastq {}

# Postrimming FastQC
#echo "${READS[@]}" | xargs -n 4 fastqc -t 4 -o ${BASE_DIR}/fastqc/posttrim -f fastq {}
```

