#!/bin/bash
#SBATCH --job-name=genrich
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ATrouern-Trend@scripps.edu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --partition=flits
#SBATCH --cpus-per-task=1
#SBATCH --mem=20gb
#SBATCH -o genrich_default.%j.out
#SBATCH -e genrich_default.%j.err

# Genrich is not multi-threaded.

# Make genrich dir
BASE_DIR=$( pwd | rev | cut -d'/' -f2- | rev )

if [[ ! -d "${BASE_DIR}/genrich" ]]; then
    mkdir ${BASE_DIR}/genrich
fi

# Set variables for bam input
WT_IN=$(awk '{ if ($2 == "wt") print $3}' $BASE_DIR/samplesheet.csv | tr '\n' ',' | sed 's/,/.bam,/g' | sed 's/SAMN/trimmed_SAMN/g' | sed 's/,$//g')
echo $WT_IN
KO_IN="$(awk '{ if ($2 == "ko") print $3}' $BASE_DIR/samplesheet.csv | tr '\n' ',' | sed 's/,/.bam,/g' | sed 's/SAMN/trimmed_SAMN/g' | sed 's/,$//g')"
echo $KO_IN

# Get mitochondral sequence ID from genome
MITO=$(grep '>' $BASE_DIR/genome/GRCm39.fasta | grep 'mito' | cut -d' ' -f1 | tr -d '>')

# Without unpaired reads
cd $BASE_DIR/bowtie/
/gpfs/group/flits/atrouern/tools/Genrich/Genrich -t $WT_IN -o $BASE_DIR/genrich/wt_genrich.peaks -f wt_genrich.log -j -r -e $MITO -v
/gpfs/group/flits/atrouern/tools/Genrich/Genrich -t $KO_IN -o $BASE_DIR/genrich/ko_genrich.peaks -f ko_genrich.log -j -r -e $MITO -v

# With unpaired reads
#/gpfs/group/flits/atrouern/tools/Genrich/Genrich  -t -o $OUTDIR/genrich  -j  -y  -r  -e $MITO  -v
