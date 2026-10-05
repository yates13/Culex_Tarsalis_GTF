#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.16_blastn_selfcheck
#SBATCH --output=../logs/01.16_blastn_selfcheck_%j.out
#SBATCH --error=../logs/01.16_blastn_selfcheck_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 01.16 - BLASTN the high-confidence novel loci's representative
# transcripts against the C. tarsalis genome itself, as an independent
# nucleotide-level check separate from GMAP's splice-aware alignment and
# separate from the BLASTX-vs-SwissProt protein check. Reuses the genome
# BLASTN DB built by the old 01.1_BlastDB.sh if present; builds fresh
# otherwise. Depends on 01.13 (novel_highconfidence_representative.fasta).

set -euo pipefail
source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/blast_env

mkdir -p ../results/blastn_genome_db

# reuse existing genome BLASTN db if it exists at the old path, else build fresh
OLD_DB=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline/Blast_Database/CtarK1_genome_db
if [ -f "${OLD_DB}.nin" ]; then
    echo "Reusing existing genome BLASTN db from old pipeline"
    cp ${OLD_DB}.* ../results/blastn_genome_db/
else
    echo "Building fresh genome BLASTN db"
    makeblastdb -in ../data/genome.fa -dbtype nucl -out ../results/blastn_genome_db/CtarK1_genome_db
fi

echo "=== DB files ==="
ls -lh ../results/blastn_genome_db/

blastn -query ../results/novel_highconfidence_representative.fasta \
       -db ../results/blastn_genome_db/CtarK1_genome_db \
       -out ../results/blastn_genome_selfcheck_hits.tsv \
       -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen" \
       -evalue 1e-5 -max_target_seqs 3 -num_threads 8

echo "=== Total hit rows ==="
wc -l ../results/blastn_genome_selfcheck_hits.tsv
