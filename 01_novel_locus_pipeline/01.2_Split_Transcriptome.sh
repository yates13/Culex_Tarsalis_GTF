#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.2_split_transcriptome
#SBATCH --output=../logs/01.2_split_%j.out
#SBATCH --error=../logs/01.2_split_%j.err
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=ALL
#SBATCH --mail-user=c832500103@colostate.edu

# STEP 01.2 - split the rnaSPAdes transcriptome into 100 chunks so the GMAP
# alignment can run as a SLURM array job instead of one giant single job.
# Submit from inside scripts/.

set -euo pipefail

source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/conda_envs/cellSquito

mkdir -p ../results/chunks

seqkit split2 -p 100 -O ../results/chunks ../data/transcriptome.fasta

echo "=== Chunk files created: ==="
ls ../results/chunks/ | wc -l
ls ../results/chunks/ | head -5

