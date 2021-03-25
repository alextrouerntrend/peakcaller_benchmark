#!/bin/bash
#SBATCH --job-name=cutadapt
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ATrouern-Trend@scripps.edu
#SBATCH --partition=flits
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=20gb
#SBATCH -o cutadapt.%j.out
#SBATCH -e cutadapt.%j.err

#get version number
/gpfs/group/flits/pipelines/atacseq/dev/dependencies/cutadapt --version

BASE_DIR=$( pwd | rev | cut -d'/' -f2- | rev )

# -a and -A are 3' sequence adapters for both pairs of reads
# -g and -G are 5' sequence adapters for both pairs of reads
NEXTERA_PAIRED="-a CTGTCTCTTATACACATCT -A CTGTCTCTTATACACATCT -g XAGATGTGTATAAGAGACAG -G XAGATGTGTATAAGAGACAG"

if [[ ! -d "${BASE_DIR}/trimmed" ]]; then
    mkdir ${BASE_DIR}/trimmed
fi

# Generate arrays of input and output fastq files
READS1=( ${BASE_DIR}/raw_data/*_1.fastq )
READS2=( ${BASE_DIR}/raw_data/*_2.fastq )
OUT1=( $( echo "${READS1[@]}" | sed 's/SAMN/trimmed_SAMN/g' | xargs -n 1 basename ) ) 
OUT2=( $( echo "${READS2[@]}" | sed 's/SAMN/trimmed_SAMN/g' | xargs -n 1 basename ) )

# .${#READS1[@]}}
# Call cutadapt for each pair of reads.

END=${#READS1[@]}

for ((i=0;i<=END;i++)); do
    echo $i
    /gpfs/group/flits/pipelines/atacseq/dev/dependencies/cutadapt \
    $NEXTERA_PAIRED \
    -j 16 \
    --max-n 0.1 \
    -m 35 \
    --nextseq-trim=20 \
    -o ${BASE_DIR}/trimmed/${OUT1[i]} \
    -p ${BASE_DIR}/trimmed/${OUT2[i]} ${READS1[i]} ${READS2[i]}
done
