#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 10
#SBATCH --mem=50G
#SBATCH --time=5:00:00
#SBATCH --exclusive
#SBATCH -o matqpipeline.out
#SBATCH -e matqpipeline.err


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

TIME_BIN="$HOME/miniconda3/envs/matqseq/bin/time"

# Find the directory where this script is located
SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# Define relative paths based on script location

TRIMMED_READS="${SCRIPT_DIR}/trimmed_reads/BBDuk_L_R_G"
GENOME="${SCRIPT_DIR}/genome"
OUTPUT_DIR="${SCRIPT_DIR}/matqseq_pipeline"

cd "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/bowtie2_aligned" "$OUTPUT_DIR/featureCounts"
BOWTIE="$OUTPUT_DIR/bowtie2_aligned"
FEATURECOUNTS="$OUTPUT_DIR/featureCounts"

# ------------------------------------------------------------------------------
# Alignment
# ------------------------------------------------------------------------------
#genome index
# bowtie2-build "$GENOME/salmonella_sl1344.fa" sl1344_index

# #alignment _ count
# #$TIME_BIN -v bash -c '
for file in "$TRIMMED_READS"/*.fastq.gz; do
  filename="${file##*/}"          
  filename="${filename%.fastq.gz}"
  bam_file="${filename}.bam"
  count_file="${filename}.count"

bowtie2 -p 8 --local \
-x sl1344_index \
-U $file | samtools view -@ 8 -bS -h - > \
bowtie2_aligned/$bam_file

featureCounts -T 8 \
-a "$GENOME/salmonella_sl1344.gff3" \
-t "gene" -g "ID" \
-o featureCounts/$count_file \
bowtie2_aligned/$bam_file
done
#' 2> "$OUTPUT_DIR/matq_pipeline.txt"

echo "Pipeline complete. Timing stats in $OUTPUT_DIR/matq_pipeline.txt"
