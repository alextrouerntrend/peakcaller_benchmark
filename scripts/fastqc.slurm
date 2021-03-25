#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ATrouern-Trend@scripps.edu
#SBATCH --partition=flits
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=4gb
#SBATCH -o fastqc.%j.out
#SBATCH -e fastqc.%j.err

module load fastqc

# Line 29 can be commented out and 33 uncommented after read trimming with cutadapt to get post-trimming QC report.  

BASE_DIR=$( pwd | rev | cut -d'/' -f2- | rev )

# Check for fastQC directory and make if doesn't exist
if [[ ! -d "${BASE_DIR}/fastqc" ]]; then
    mkdir -p ${BASE_DIR}/fastqc/pretrim
fi
if [[ ! -d "${BASE_DIR}/fastqc/posttrim" ]]; then
    mkdir ${BASE_DIR}/fastqc/posttrim
fi

# Pretrimming FastQC
READS=( ${BASE_DIR}/raw_data/*.fastq )
echo "${READS[@]}" | xargs -n 4 fastqc -t 4 -o ${BASE_DIR}/fastqc/pretrim -f fastq {}

# Postrimming FastQC
TRIMMED=( ${BASE_DIR}/trimmed/*.fastq )
#echo "${TRIMMED[@]}" | xargs -n 4 fastqc -t 4 -o ${BASE_DIR}/fastqc/posttrim -f fastq {}
