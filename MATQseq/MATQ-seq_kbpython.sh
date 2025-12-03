#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 10
#SBATCH --mem=50G
#SBATCH --time=5:00:00
#SBATCH --exclusive
#SBATCH -o kb_matq.out
#SBATCH -e kb_matq.err

# Exit on any error
set -euo pipefail

# ------------------------------------------------------------------------------
# Env
# ------------------------------------------------------------------------------
source ~/miniconda3/bin/activate
conda activate kb_env

# ------------------------------------------------------------------------------
# Paths
# ------------------------------------------------------------------------------
#Current folder="matqseq"

TIME_BIN="$HOME/miniconda3/envs/kb_env/bin/time"

# Find the directory where this script is located
SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# Define relative paths based on script location
MULTIPLEX_READS="${SCRIPT_DIR}/remultiplex_reads"
GENOME="${SCRIPT_DIR}/genome"
PRIMERS="${SCRIPT_DIR}/primers"
KB="${SCRIPT_DIR}/kb"

cd "$KB"

# ------------------------------------------------------------------------------
# Kb reference
# ------------------------------------------------------------------------------
echo "=== Creating kb reference index ==="
kb ref -t 10 --make-unique --overwrite --workflow nac \
    -i "index.idx" \
    -g "t2g.txt" \
    -f1 "f1.fasta" \
    -f2 "f2.fasta" \
    -c1 "c1.txt" \
    -c2 "c2.txt" \
    "$GENOME/salmonella_sl1344.fa" \
    "$GENOME/salmonella_sl1344.gtf"

# ------------------------------------------------------------------------------
# Run pipeline 
# ------------------------------------------------------------------------------
echo "Starting full pipeline timing..."

#$TIME_BIN -v bash -c '
  kb count \
            -w "$PRIMERS/onlist_matqseqprimer.txt" \
            -x="0,0,8:-1,-1,-1:0,8,108" \
            -t 10 -m 50G \
            -i "index.idx" \
            -g "t2g.txt" \
            -c1 "c1.txt" \
            -c2 "c2.txt" \
            --workflow nac \
            --tmp "tmp" \
            -o "remultiplex_timing_results" \
            --h5ad --num \
           "$MULTIPLEX_READS/remultiplexed_output.fastq.gz"

#' 2> "$KB/remultiplex_kb_time.txt"

echo "Pipeline complete. Timing stats in $KB/remultiplex_kb_time.txt"

