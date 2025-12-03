#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 10
#SBATCH --mem=50G
#SBATCH --time=2:00:00
#SBATCH -o matq_trimming.out
#SBATCH -e matq_trimming.err

# Exit on any error
set -euo pipefail

# ------------------------------------------------------------------------------
# Env
# ------------------------------------------------------------------------------
source ~/miniconda3/bin/activate
conda activate matqseq

# ------------------------------------------------------------------------------
# Paths
# ------------------------------------------------------------------------------
#Current folder="matqseq"

RAW_READS="./fastq"
PRIMER_DIR="./primers" #matqseq_primers.fa + nextera_and_primers.fa provided by https://doi.org/10.1038/s41596-025-01157-5
TRIMMED_READS="./trimmed_reads"

# ------------------------------------------------------------------------------
# Trimming
# ------------------------------------------------------------------------------
mkdir -p "$TRIMMED_READS/BBDuk_L_G" "$TRIMMED_READS/BBDuk_L_R_G"

bbduk_opts="-Xmx50g t=10 minlen=18 qtrim=rl trimq=20 k=17 mink=11 hdist=1"

echo "=== BBDuk trimming ==="
for infile in "$RAW_READS"/*.fastq.gz; do
    filename=$(basename "$infile")

    echo "Processing $infile"
    
    #left trim
    bbduk.sh $bbduk_opts in="$infile" \
      out="$TRIMMED_READS/BBDuk_L_G/$filename" \
      ref="$PRIMER_DIR/matqseq_primers.fa" ktrim=l trimpolya=30 trimpolyg=30

    #right trim 
    bbduk.sh $bbduk_opts in="$TRIMMED_READS/BBDuk_L_G/$filename" \
      out="$TRIMMED_READS/BBDuk_L_R_G/$filename" \
      ref="$PRIMER_DIR/nextera_and_primers.fa" ktrim=r
done

echo "Trimming completed"
