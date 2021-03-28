#!/bin/bash
#SBATCH --job-name=bowtie2
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ATrouern-Trend@scripps.edu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --partition=flits
#SBATCH --cpus-per-task=16
#SBATCH --mem=50gb
#SBATCH -o bowtie2.%j.out
#SBATCH -e bowtie2.%j.err

module load bowtie2
module load samtools

# Get Project Directory
BASE_DIR=$( pwd | rev | cut -d'/' -f2- | rev )

# Create Bowtie and genome directory
if [[ ! -d "${BASE_DIR}/bowtie" ]]; then
    mkdir ${BASE_DIR}/bowtie
fi

if [[ ! -d "${BASE_DIR}/genome" ]]; then
    mkdir ${BASE_DIR}/genome
fi

# get trimmed reads
READS1=( ${BASE_DIR}/trimmed/*_1.fastq )
READS2=( ${BASE_DIR}/trimmed/*_2.fastq )
OUT=( $( echo "${READS1[@]}" | sed 's/_1.fastq/.bam/g' | xargs -n 1 basename ) )

# Download Mus musculus genome and index it.
wget -O ${BASE_DIR}/genome/GRCm39.fasta.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/635/GCA_000001635.9_GRCm39/GCA_000001635.9_GRCm39_genomic.fna.gz"

gunzip ${BASE_DIR}/genome/GRCm39.fasta.gz

bowtie2-build --threads 16 --offrate 0 ${BASE_DIR}/genome/GRCm39.fasta ${BASE_DIR}/genome/mus_musculus

# align reads to genome
END=${#READS1[@]}
for ((i=0;i<=END;i++))
do
    bowtie2 --phred33 -p 16 -k 10 -x ${BASE_DIR}/genome/mus_musculus -1 "${READS1[i]}" -2 "${READS2[i]}" | samtools view -@ 16 -u - | samtools sort -@ 16 -n -o ${BASE_DIR}/bowtie/${OUT[i]} -
done

