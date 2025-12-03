#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 10
#SBATCH --mem=50G
#SBATCH --time=15:00:00
#SBATCH --exclusive
#SBATCH -o petripipeline.out
#SBATCH -e petripipeline.err


# Exit on any error
set -euo pipefail

# ------------------------------------------------------------------------------
# Env
# ------------------------------------------------------------------------------
source ~/miniconda3/bin/activate
conda activate petri_seq_2021

#Current folder="petriseq"

cd ./petriseq_pipeline/ecoli2

# ------------------------------------------------------------------------------
# PETRI-seq pipeline provided
# ------------------------------------------------------------------------------

python ../scripts/sc_pipeline_11.py ecolisamp_S1 1 #when timing comment out fastqc in sc_pipeline_11.py 

../scripts/pipeline.sh ecolisamp 40000 ../scripts/ecolimg1655.fna ../scripts/ecolimg1655.gff ecolisamp
