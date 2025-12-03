#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 17
#SBATCH --mem=50G
#SBATCH --time=00:10:00
#SBATCH -o remultiplex_matq.out
#SBATCH -e remultiplex_matq.err


#Current folder="matqseq"

TRIMMED_READS="./trimmed_reads/BBDuk_L_R_G"  
OUTPUT_DIR="./remultiplex_reads"

echo "Starting FASTQ remultiplexing"

mkdir -p "$OUTPUT_DIR"

# Run the parallel remultiplexing script
python ./remultiplex.py \
    "$TRIMMED_READS" \
    "$OUTPUT_DIR/remultiplexed_output" \
    --cores 16 \
    --chunk-size 5000 \
    --barcode-length 8

echo "Remultiplexing complete. Output files:"
echo "$OUTPUT_DIR/remultiplexed_output.fastq.gz"
echo "$OUTPUT_DIR/remultiplexed_output_barcode_mapping.txt"
