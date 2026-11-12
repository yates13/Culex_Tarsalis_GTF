#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=03.1_Build_Quinq_BlastDB
#SBATCH --output=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/03.1_aedes_blastn/03.1_Build_Quinq_BlastDB_%j.out
#SBATCH --error=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/03.1_aedes_blastn/03.1_Build_Quinq_BlastDB_%j.err
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=ALL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 03.1 - download the Culex quinquefasciatus chromosome-scale genome
# (GCF_015732765.1, VPISU_Cqui_1.0_pri_paternal, Ryazansky et al. 2024) and
# build a BLAST nucleotide database from it. This is a third, independent
# species-conservation check alongside the Aedes comparison (02.x) -
# Cx. quinquefasciatus is more closely related to Cx. tarsalis than Aedes is.

set -euo pipefail

source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/blast_env

DATA_DIR=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/data/quinquefasciatus
mkdir -p $DATA_DIR
cd $DATA_DIR

ACCESSION="GCF_015732765.1"
ASSEMBLY_NAME="VPISU_Cqui_1.0_pri_paternal"
GENOME_FASTA="${ACCESSION}_${ASSEMBLY_NAME}_genomic.fna"

# Download from NCBI FTP (path derived from the accession's digit groups)
wget -O ${GENOME_FASTA}.gz \
  "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/015/732/765/${ACCESSION}_${ASSEMBLY_NAME}/${ACCESSION}_${ASSEMBLY_NAME}_genomic.fna.gz"

gunzip ${GENOME_FASTA}.gz

echo "Downloaded genome:"
ls -lh $GENOME_FASTA
grep -c "^>" $GENOME_FASTA
echo "sequences found in genome FASTA"

makeblastdb -in $GENOME_FASTA \
  -dbtype nucl \
  -parse_seqids \
  -out culex_quinquefasciatus_genome \
  -title "Culex quinquefasciatus VPISU_Cqui_1.0 chromosome-scale genome"

ls -lh culex_quinquefasciatus_genome.*
blastdbcmd -db culex_quinquefasciatus_genome -info
