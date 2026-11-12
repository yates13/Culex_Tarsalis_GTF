#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=03.2_split_transcriptome
#SBATCH --output=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/03.2_quinq_blastn/03.2_split_%j.out
#SBATCH --error=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/03.2_quinq_blastn/03.2_split_%j.err
#SBATCH --time=00:20:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal

set -euo pipefail
source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/blast_env

BASE=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized
CHUNK_DIR=$BASE/data/transcriptome_chunks
N_CHUNKS=10

mkdir -p $CHUNK_DIR
cd $CHUNK_DIR

# Requires seqkit (conda install -c bioconda seqkit if not already in blast_env)
seqkit split2 -p $N_CHUNKS -O $CHUNK_DIR $BASE/data/transcriptome.fasta

# seqkit names output like transcriptome.part_001.fasta - rename to a predictable pattern
i=1
for f in $(ls $CHUNK_DIR/*.part_*.fasta | sort); do
  mv "$f" "$CHUNK_DIR/chunk_${i}.fasta"
  i=$((i+1))
done

echo "Split into $N_CHUNKS chunks:"
ls -la $CHUNK_DIR
