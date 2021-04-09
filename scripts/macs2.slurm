#!/bin/bash
#SBATCH --job-name=macs2
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ATrouern-Trend@scripps.edu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --partition=flits
#SBATCH --cpus-per-task=1
#SBATCH --mem=20gb
#SBATCH -o macs2_default.%j.out
#SBATCH -e macs2_default.%j.err

# This script is based largely on the old Harvard FAS Informatics ATACseq guidelines
# Accessed April 2021 (https://informatics.fas.harvard.edu/atac-seq-guidelines-old-version.html#peak)

module load R/4.0.0
module load macs/2.1.0
module load samtools
module load picard

# Make macs2 dir
BASE_DIR=$( pwd | rev | cut -d'/' -f2- | rev )

if [[ ! -d "${BASE_DIR}/macs2" ]]; then
    mkdir ${BASE_DIR}/macs2
fi

# Remove Mitochondrial reads
MTBAMS_IN=( $(ls -d $BASE_DIR/bowtie/t*.bam | tr '\n' ' ') )
MITO=$(grep '>' $BASE_DIR/genome/GRCm39.fasta | grep 'mito' | cut -d' ' -f1 | tr -d '>')

for FILE in "${MTBAMS_IN[@]}"; do
    echo $FILE
    BASENAME1=$( echo $FILE | sed 's/trimmed_/mtclean_/g' | xargs -n 1 basename )
    echo $BASENAME1
    samtools view -h --verbosity 9  $FILE  |  $BASE_DIR/scripts/removeChrom.py - - $MITO  |  samtools view -b - > $BASE_DIR/macs2/$BASENAME1
done

# Remove PCR duplicates
PCRBAMS=( $(ls -d $BASE_DIR/macs2/mt*.bam | tr '\n' ' ') )
for FILE in "${PCRBAMS[@]}"; do
    BASENAME2=$( echo $FILE | sed 's/mtclean_/nopcr_/g' | xargs -n 1 basename )
    DUPFILE=$( echo $BASENAME | sed 's/.bam/.dups.txt/g' )
    java -jar picard.jar MarkDuplicates I=$FILE O=$BASE_DIR/macs2/$BASENAME2 M=$BASE_DIR/macs2/$DUPFILE REMOVE_DUPLICATES=true
done

# Exclude multimapped reads
NOMULTIBAMS=( $(ls -d $BASE_DIR/macs2/nopcr_*.bam | tr '\n' ' ') )
for FILE in "${NOMULTIBAMS[@]}"; do
    BASENAME3=$( echo $FILE | sed 's/nopcr_/final_/g' | xargs -n 1 basename )
    samtools view -b -q 10 $FILE $BASE_DIR/macs2/$BASENAME3 # remove alignments with MAPQ < 10
done

# Convert sam files to BED files
BED_INPUT=( $(ls -d $BASE_DIR/macs2/final_*.bam | tr '\n' ' ') )
for FILE in "${BED_INPUT[@]}"; do
    BED_OUT=$( echo $FILE | sed 's/.bam/.bed/g' | xargs -n 1 basename )
    SUMMARY=$( echo $FILE | sed 's/.bam/len_summ.txt/g' | xargs -n 1 basename )
    samtools view -h $FILE | $BASE_DIR/scripts/SAMtoBED.py -i - -o $BASE_DIR/macs2/$BED_OUT -v -n -t $SUMMARY
done

# Run MACS2 default atac-seq settings
MACS_IN=( $(ls -d $BASE_DIR/macs2/final*.bed | tr '\n' ' ') )
for FILE in "${MACS_IN[@]}"; do
    MACSNAME=$(echo $FILE | sed 's/.bed//g' | xargs -n 1 basename )
    macs2 callpeak -t $FILE -f BEDPE -n $MACSNAME -g mm  --keep-dup all
done

