#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=02.2_Culex_vs_Aedes_Blastn
#SBATCH --output=logs/02.2_aedes_blastn/02.2_Culex_vs_Aedes_Blastn.out
#SBATCH --error=logs/02.2_aedes_blastn/02.2_Culex_vs_Aedes_Blastn.err
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=ALL
#SBATCH --mail-user=c832500103@colostate.edu

source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/blast_env

BASE=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized
DB_DIR=$BASE/data/aedes
RESULTS_DIR=$BASE/results/02.2_aedes_blastn

cd $DB_DIR

blastn -query $BASE/data/transcriptome.fasta \
  -db aedes_aegypti_genome \
  -out $RESULTS_DIR/transcriptome_vs_aedes_blastn.tsv \
  -outfmt "6 qseqid sseqid pident length mismatch evalue bitscore stitle" \
  -evalue 1e-10 \
  -max_target_seqs 5 \
  -num_threads 8

# Best hit per query (top bitscore)
# NOTE: this outfmt is 8 columns (qseqid sseqid pident length mismatch evalue bitscore stitle)
# Using awk instead of sort|sort -u: a two-pass sort pipeline is fragile here because
# combined -rn flags apply to ALL sort keys unless scoped per-key, which silently broke
# the qseqid grouping and produced 214,360 lines instead of one-per-query (27,484).
cd $RESULTS_DIR
awk -F'\t' '
  ($1 in best) == 0 || $7+0 > best[$1] {
    best[$1] = $7+0
    line[$1] = $0
  }
  END { for (q in line) print line[q] }
' transcriptome_vs_aedes_blastn.tsv > best_hits.tsv
