#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=03.4_merge_blastn
#SBATCH --output=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/03.2_quinq_blastn/03.4_merge_%j.out
#SBATCH --error=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/03.2_quinq_blastn/03.4_merge_%j.err
#SBATCH --time=00:20:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal

set -euo pipefail
BASE=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized
RESULTS_DIR=$BASE/results/03.2_quinq_blastn

CHUNK_RESULTS=$RESULTS_DIR/chunks

cd $RESULTS_DIR

cat $CHUNK_RESULTS/chunk_*.tsv > transcriptome_vs_quinq_blastn.tsv
echo "Total hit rows:"
wc -l transcriptome_vs_quinq_blastn.tsv

# Same single-pass best-hit-per-query logic as before
awk -F'\t' '
  ($1 in best) == 0 || $7+0 > best[$1] {
    best[$1] = $7+0
    line[$1] = $0
  }
  END { for (q in line) print line[q] }
' transcriptome_vs_quinq_blastn.tsv > best_hits.tsv

echo "Unique queries with a best hit:"
wc -l best_hits.tsv
