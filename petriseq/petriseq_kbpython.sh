#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 10
#SBATCH --mem=50G
#SBATCH --time=00:30:00
#SBATCH --exclusive
#SBATCH -o petri-kb.out
#SBATCH -e petri-kb.err

# Exit on any error
set -euo pipefail

# ------------------------------------------------------------------------------
# Env
# ------------------------------------------------------------------------------
source ~/miniconda3/bin/activate
conda activate kb_env


#----------------------------------------------------
# Paths
#----------------------------------------------------
TIME_BIN="$HOME/miniconda3/envs/matqseq/bin/time"

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"


READS="${SCRIPT_DIR}/renamed_reads"
GENOME="${SCRIPT_DIR}/genome"
KB="${SCRIPT_DIR}/kb"

cd "$KB"

#----------------------------------------------------
# Index
#----------------------------------------------------

KMER=15 #as determined best for lenght of sequence

kb ref -k $KMER -t 10 --make-unique --overwrite --workflow nac \
-i index.idx -g t2g.txt -f1 f1.fasta -f2 f2.fasta -c1 c1.txt -c2 c2.txt \
${GENOME}/ecolimg1655.fna ${GENOME}/ecolimg1655.gtf

#----------------------------------------------------
# Align
#----------------------------------------------------
#check seqspec
seqspec check spec_with_primer.yaml

#onlist_joined_petri.txt is the 3 barcodes from PETRI-seq
#"$TIME_BIN" -v bash -c '
kb count \
-w onlist_joined_petri.txt \
-x "$(seqspec index -t kb -m rna -i R1.fastq.gz,R2.fastq.gz spec_with_primer.yaml)" \
-t 10 -m 50G \
-i "index.idx" -g "t2g.txt" -c1 "c1.txt" -c2 "c2.txt" \
--workflow nac \
--tmp "tmp" \
-o "kbpython_results" \
--h5ad --num \
"$READS/ecolisamp_S1_L001_R1_001.fastq.gz" "$READS/ecolisamp_S1_L001_R2_001.fastq.gz"

 # '2> "full_pipeline_time.txt"
