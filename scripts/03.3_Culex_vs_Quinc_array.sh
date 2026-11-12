#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=03.2_Culex_vs_Quinq_Blastn
#SBATCH --output=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/03.2_quinq_blastn/blastn_%A_%a.out
#SBATCH --error=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/03.2_quinq_blastn/blastn_%A_%a.err
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --array=1-10
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu

set -euo pipefail
source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/blast_env

BASE=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized
DB_DIR=$BASE/data/quinquefasciatus
CHUNK_DIR=$BASE/data/transcriptome_chunks
RESULTS_DIR=$BASE/results/03.2_quinq_blastn/chunks

mkdir -p $RESULTS_DIR
cd $DB_DIR

CHUNK_FASTA=$CHUNK_DIR/chunk_${SLURM_ARRAY_TASK_ID}.fasta

blastn -query $CHUNK_FASTA \
  -db culex_quinquefasciatus_genome \
  -out $RESULTS_DIR/chunk_${SLURM_ARRAY_TASK_ID}.tsv \
  -outfmt "6 qseqid sseqid pident length mismatch evalue bitscore stitle" \
  -evalue 1e-10 \
  -max_target_seqs 5 \
  -num_threads 4

echo "Chunk ${SLURM_ARRAY_TASK_ID} hit rows:"
wc -l $RESULTS_DIR/chunk_${SLURM_ARRAY_TASK_ID}.tsv
