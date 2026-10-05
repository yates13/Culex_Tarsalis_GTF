#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.6_prepare_beds
#SBATCH --output=../logs/01.6_prepare_beds_%j.out
#SBATCH --error=../logs/01.6_prepare_beds_%j.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu

# STEP 01.6 - convert basefeatures_realgenes.gtf to sorted BED with Mt contig
# naming fixed to match the genome, and sort the GMAP gene BED. Depends on
# 01.4 (gmap_genes.sorted.bed) and 01.5 (basefeatures_realgenes.gtf).

set -euo pipefail
source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/conda_envs/cellSquito

awk -F'\t' 'BEGIN{OFS="\t"} {
    split($9, a, ";"); id = a[1]; gsub(/gene_id "|"/, "", id);
    chrom = ($1=="Mt") ? "Mt_CtarK1_noOVERLAP_RC.1" : $1;
    print chrom, $4-1, $5, id, ".", $7
}' ../results/basefeatures_realgenes.gtf | sort -k1,1 -k2,2n > ../results/basefeatures_genes.sorted.fixed.bed

echo "basefeatures_genes.sorted.fixed.bed:"
wc -l ../results/basefeatures_genes.sorted.fixed.bed

#sort -k1,1 -k2,2n ../results/gmap_genes.sorted.bed -o ../results/gmap_genes.sorted.bed

# May need to run these outside of the script for some reason
sort -k1,1 -k2,2n ../results/gmap_genes.sorted.bed -o ../results/gmap_genes.sorted.bed.tmp
mv ../results/gmap_genes.sorted.bed.tmp ../results/gmap_genes.sorted.bed
echo "gmap_genes.sorted.bed - sort verification:"
sort -c -k1,1 -k2,2n ../results/gmap_genes.sorted.bed && echo "OK - correctly sorted" || echo "STILL BROKEN - investigate further"
#

echo "gmap_genes.sorted.bed:"
wc -l ../results/gmap_genes.sorted.bed

