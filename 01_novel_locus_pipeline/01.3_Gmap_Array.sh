#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.3_gmap_array
#SBATCH --output=../logs/01.3_gmap_array_%A_%a.out
#SBATCH --error=../logs/01.3_gmap_array_%A_%a.err
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --qos=cpu-normal
#SBATCH --array=1-100
#SBATCH --mail-type=ALL
#SBATCH --mail-user=c832500103@colostate.edu

# STEP 01.3 - align each transcriptome chunk to the genome with GMAP.
# Depends on 01.2 (chunks must exist first). Submit from inside scripts/.

set -euo pipefail

source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/conda_envs/cellSquito

mkdir -p ../results/gmap_results

PART=$(printf "%03d" $SLURM_ARRAY_TASK_ID)
QUERY="../results/chunks/transcriptome.part_${PART}.fasta"
OUT="../results/gmap_results/gmap_part_${PART}.gff3"

gmap -D ../results/gmap_index -d CtarK1 \
     -t 8 \
     -f gff3_gene \
     -n 1 \
     "$QUERY" \
     > "$OUT"
