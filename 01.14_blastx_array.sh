#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.14_blastx_array
#SBATCH --output=../logs/01.14_blastx_array_%A_%a.out
#SBATCH --error=../logs/01.14_blastx_array_%A_%a.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --qos=cpu-normal
#SBATCH --array=1-20
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu


# STEP 01.14 - BLASTX the high-confidence representative transcripts against
# swissprot, one chunk per array task (20 chunks now, scaled up from the
# original 10 for the smaller needs-review-only scope). Depends on 01.13.

set -euo pipefail
source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/blast_env

mkdir -p ../results/blastx_results

PART=$(printf "%03d" $SLURM_ARRAY_TASK_ID)
QUERY="../results/highconfidence_chunks/novel_highconfidence_representative.part_${PART}.fasta"
OUT="../results/blastx_results/blastx_part_${PART}.tsv"

if [ ! -s "$QUERY" ]; then
    echo "ERROR: query file $QUERY is missing or empty. Check 01.13 completed correctly." >&2
    exit 1
fi

blastx -query "$QUERY" \
       -db ../results/blastx_db/swissprot \
       -out "$OUT" \
       -outfmt "6 qseqid sseqid pident length evalue bitscore stitle" \
       -evalue 1e-5 -max_target_seqs 1 -num_threads 8

# Change Evalue to both E -10 and E - 20
