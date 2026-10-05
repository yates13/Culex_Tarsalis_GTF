#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01_gmap_build
#SBATCH --output=../logs/01.1_gmap_build_%j.out
#SBATCH --error=../logs/01.1_gmap_build_%j.err
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=ALL
#SBATCH --mail-user=c832500103@colostate.edu

# STEP 01 - build the GMAP index from the genome.
# Run this first. Output feeds into 02_gmap_array.sh.
# Submit from inside scripts/ - relative paths below assume that.

set -euo pipefail
source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/conda_envs/cellSquito

mkdir -p ../results/gmap_index

gmap_build -D ../results/gmap_index -d CtarK1 ../data/genome.fa

echo "=== Index build complete - contents: ==="
ls -lh ../results/gmap_index/CtarK1/
