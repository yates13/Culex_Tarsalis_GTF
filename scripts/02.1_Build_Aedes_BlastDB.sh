#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=02.1_Build_Aedes_BlastDB
#SBATCH --output=logs/02.1_aedes_blastn/02.1_Build_Aedes_BlastDB.out
#SBATCH --error=logs/02.1_aedes_blastn/02.1_Build_Aedes_BlastDB.err
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=ALL
#SBATCH --mail-user=c832500103@colostate.edu

source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/blast_env

cd /scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/data/aedes

makeblastdb -in GCF_002204515.2_AaegL5.0_genomic.fna \
  -dbtype nucl \
  -parse_seqids \
  -out aedes_aegypti_genome \
  -title "Aedes aegypti AaegL5 genome"

ls -lh aedes_aegypti_genome.*
blastdbcmd -db aedes_aegypti_genome -info
