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
