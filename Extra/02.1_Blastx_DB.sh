#!/bin/bash

#SBATCH --partition=amilan
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --qos=normal
#SBATCH --array=1-10
#SBATCH --output=Blastx_Database/logs/blastx_%A_%a.out
#SBATCH --error=Blastx_Database/logs/blastx_%A_%a.err

source /scratch/alpine/$USER/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/$USER/blast_env

PART=$(printf "%03d" $SLURM_ARRAY_TASK_ID)
blastx -query "needsreview_chunks/novel_needsreview_representative.part_${PART}.fasta" \
       -db Blastx_Database/swissprot \
       -out "Blastx_Database/results/blastx_part_${PART}.tsv" \
       -outfmt "6 qseqid sseqid pident length evalue bitscore stitle" \
       -evalue 1e-5 -max_target_seqs 1 -num_threads 8
