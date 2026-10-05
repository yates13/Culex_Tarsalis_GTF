#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.7_intersect
#SBATCH --output=../logs/01.7_intersect_%j.out
#SBATCH --error=../logs/01.7_intersect_%j.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu


# STEP 01.7 - for every GMAP-aligned transcript, determine whether it overlaps
# an already-known basefeatures gene (confirmed) or not (novel candidate).
# Depends on 01.6.

set -euo pipefail
source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/conda_envs/cellSquito


#bedtools intersect -a ../results/gmap_genes.sorted.bed -b ../results/basefeatures_genes.sorted.fixed.bed \

#this line is using the file made the first run, need to rework how to make this file
bedtools intersect -a ../results/gmap_genes.sorted.bed -b ../results/basefeatures_genes.sorted.fixed.bed \
    -wao > ../results/transcript_vs_basefeatures.tsv
echo "transcript_vs_basefeatures.tsv:"
wc -l ../results/transcript_vs_basefeatures.tsv

awk -F'\t' '$NF>0' ../results/transcript_vs_basefeatures.tsv > ../results/transcripts_confirmed_genes.tsv
awk -F'\t' '$NF==0' ../results/transcript_vs_basefeatures.tsv > ../results/transcripts_novel_loci.tsv
echo "confirmed / novel:"
wc -l ../results/transcripts_confirmed_genes.tsv ../results/transcripts_novel_loci.tsv

cut -f1-6 ../results/transcripts_novel_loci.tsv | sort -k1,1 -k2,2n -u > ../results/novel_transcripts_only.sorted.bed
echo "novel_transcripts_only.sorted.bed:"
wc -l ../results/novel_transcripts_only.sorted.bed

