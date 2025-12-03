#!/bin/bash

# Submit this script with: sbatch <this-filename>
#SBATCH --time=2:00:00   # walltime
#SBATCH --ntasks=32   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem 350GB   # memory per CPU core
#SBATCH -J fadu_sweep   # job name
#SBATCH -A carnegie_poc

# Notify at the beginning, end of job and on failure.
#SBATCH --mail-user=coakes@caltech.edu   # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

## /SBATCH -p general # partition (queue)
## /SBATCH -o slurm.assembly.%N.%j.out # STDOUT
## /SBATCH -e slurm.assembly.%N.%j.err # STDERR

#LOAD MODULES, INSERT CODE, AND RUN PROGRAMS HERE 

eval "$(conda shell.bash hook)"
conda activate bac


GENOME_FOLDER=references
READS=SRR5192555

MEM=300
REF_OUTPUT=kb_ref

while read k; do
	KMER=$k
	OUTPUT_DIR=test_default_${KMER}
	echo 'Generating kb Indexes'
	FINAL_GENOME=Multi_${KMER}

	kb ref -t 32 --make-unique --overwrite -i $REF_OUTPUT/${FINAL_GENOME}.idx -g $REF_OUTPUT/${FINAL_GENOME}.t2g -f1 $REF_OUTPUT/${FINAL_GENOME}_f1.fa -k $KMER ${GENOME_FOLDER}/b_malayi.PRJNA10729.WS275.genomic.fa,${GENOME_FOLDER}/GCF_000008385.1_ASM838v1_genomic_exons.fasta ${GENOME_FOLDER}/b_malayi.PRJNA10729.WS275.annotations.filtered.gtf,${GENOME_FOLDER}/GCF_000008385.1_ASM838v1_genomic_exons.gtf

	echo 'Counting Bacterial Reads'
	p=SRR5192555
	f1=${READS}_fastq/${READS}_1.fastq
	f2=${READS}_fastq/${READS}_2.fastq
	echo $f1,$f2

	kb count -x BULK --parity paired -t 32 \
		-m ${MEM}G -i $REF_OUTPUT/${FINAL_GENOME}.idx -g $REF_OUTPUT/${FINAL_GENOME}.t2g -o $OUTPUT_DIR --h5ad --num $f1 $f2

	OUTPUT_DIR=test_mm_${KMER}
	kb count -x BULK --parity paired -t 32 --mm \
		-m ${MEM}G -i $REF_OUTPUT/${FINAL_GENOME}.idx -g $REF_OUTPUT/${FINAL_GENOME}.t2g -o $OUTPUT_DIR --h5ad --num $f1 $f2

done <kmers.txt

sleep 50
echo done
