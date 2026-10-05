#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=03.2_Culex_vs_Quinq_Blastn
#SBATCH --output=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/03.2_quinq_blastn/03.2_Culex_vs_Quinq_Blastn_%j.out
#SBATCH --error=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/03.2_quinq_blastn/03.2_Culex_vs_Quinq_Blastn_%j.err
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=ALL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 03.2 - BLASTN the ENTIRE transcriptome (not just the 11,993
# candidates - same scope as the Aedes run in 02.2) against the Culex
# quinquefasciatus genome, then extract one best hit per query by bitscore.
#
# Uses a single-pass awk for best-hit extraction from the start (the two-pass
# sort|sort -u pipeline used originally for Aedes had a real bug: combined
# -rn flags apply to ALL sort keys unless scoped per-key, which silently
# broke query grouping and produced far more than one row per query).

set -euo pipefail

source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/blast_env

BASE=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized
DB_DIR=$BASE/data/quinquefasciatus
RESULTS_DIR=$BASE/results/03.2_quinq_blastn

mkdir -p $RESULTS_DIR

cd $DB_DIR

blastn -query $BASE/data/transcriptome.fasta \
  -db culex_quinquefasciatus_genome \
  -out $RESULTS_DIR/transcriptome_vs_quinq_blastn.tsv \
  -outfmt "6 qseqid sseqid pident length mismatch evalue bitscore stitle" \
  -evalue 1e-10 \
  -max_target_seqs 5 \
  -num_threads 8

echo "Total hit rows:"
wc -l $RESULTS_DIR/transcriptome_vs_quinq_blastn.tsv

cd $RESULTS_DIR

# Best hit per query (top bitscore) - column 7 in this 8-column custom outfmt
awk -F'\t' '
  ($1 in best) == 0 || $7+0 > best[$1] {
    best[$1] = $7+0
    line[$1] = $0
  }
  END { for (q in line) print line[q] }
' transcriptome_vs_quinq_blastn.tsv > best_hits.tsv

echo "Unique queries with a best hit:"
wc -l best_hits.tsv
