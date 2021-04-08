#!/bin/bash
#SBATCH --job-name=macs2
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ATrouern-Trend@scripps.edu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --partition=flits
#SBATCH --cpus-per-task=1
#SBATCH --mem=20gb
#SBATCH -o mac2_default.%j.out
#SBATCH -e mac2_default.%j.err

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
cd $BASE_DIR/bowtie2
MTBAMS_IN=( $(ls -d $PWD/t*.bam | tr '\n' ' ') )
MITO=$(grep '>' $BASE_DIR/genome/GRCm39.fasta | grep 'mito' | cut -d' ' -f1 | tr -d '>')

for FILE in "${MTBAMS[@]}"; do
    BASENAME=$( echo $FILE | sed 's/trimmed_/mtclean_/g' | xargs -n 1 basename )
    samtools view -h  $FILE  |  $BASE_DIR/scripts/removeChrom.py - - $MITO  |  samtools view -b - > $BASENAME
done

# Remove PCR duplicates
PCRBAMS=( $(ls -d $PWD/mt*.bam | tr '\n' ' ') )
for FILE in "${PCRBAMS[@]}"; do
    BASENAME=$( echo $FILE | sed 's/mtclean_/nopcr_/g' | xargs -n 1 basename )
    DUPFILE=$( echo $BASENAME | sed 's/.bam/.dups.txt/g' )
    java -jar picard.jar MarkDuplicates I=$FILE O=$BASENAME M=$DUPFILE REMOVE_DUPLICATES=true
done

# Set variables for bam input
#WT_IN=$(awk '{ if ($2 == "wt") print $3}' $BASE_DIR/samplesheet.csv | tr '\n' ',' | sed 's/,/.bam,/g' | sed 's/SAMN/trimmed_SAMN/g' | sed 's/,$//g')
#echo $WT_IN
#KO_IN="$(awk '{ if ($2 == "ko") print $3}' $BASE_DIR/samplesheet.csv | tr '\n' ',' | sed 's/,/.bam,/g' | sed 's/SAMN/trimmed_SAMN/g' | sed 's/,$//g')"
#echo $KO_IN


# Get mitochondral sequence ID from genome

# Without unpaired reads
cd $BASE_DIR/bowtie/



# With unpaired reads
#/gpfs/group/flits/atrouern/tools/Genrich/Genrich  -t -o $OUTDIR/genrich  -j  -y  -r  -e $MITO  -v
