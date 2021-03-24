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

module load sra-tools

BIOPROJECT=PRJNA436008

# Find project base directory
BASE_DIR=$( pwd | rev | cut -d'/' -f2- | rev )

# Make raw data directory
mkdir $BASE_DIR/raw_data

# Download RunInfo table for BioProject
wget 'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&rettype=runinfo&db=sra&term='${BIOPROJECT} -O - | tee $BASE_DIR/raw_data/SraRunInfo.csv

# Use RunInfo to guide SRA downloads
esearch -db sra -query $BIOPROJECT | efetch -format runinfo | cut -d',' -f 1 | grep SRR | xargs -n 1 -P 12 fastq-dump -O $BASE_DIR/raw_data -X 10 --split-files
wait
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
