#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.9_filter_merge_strand
#SBATCH --output=../logs/01.9_filter_merge_strand_%j.out
#SBATCH --error=../logs/01.9_filter_merge_strand_%j.err
#SBATCH --time=00:45:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 01.9 - keep only novel transcripts with decent coverage/identity
# (>=70% coverage, >=90% identity), split by strand, then merge overlapping
# intervals within each strand. Depends on 01.7 and 01.8.
#
# NOTE: gmap_mrna_quality.tsv IDs end in .mrna1, but novel_transcripts_only's
# IDs end in .path1 - both refer to the same underlying transcript, so both
# suffixes must be stripped before matching or the join silently returns
# nothing (this is what broke the previous run).

set -euo pipefail
source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/conda_envs/cellSquito

awk -F'\t' '$6>=70 && $7>=90 {print $1}' ../results/gmap_mrna_quality.tsv | sed 's/\.mrna[0-9]*$//' \
    > ../results/passing_transcripts.txt
echo "passing_transcripts.txt:"
wc -l ../results/passing_transcripts.txt

awk -F'\t' 'BEGIN{OFS="\t"} {id=$4; sub(/\.path[0-9]*$/, "", id); print $0, id}' \
    ../results/novel_transcripts_only.sorted.bed > ../results/novel_transcripts_only.with_base_id.bed

awk -F'\t' 'NR==FNR{keep[$1]=1; next} ($NF in keep)' \
    ../results/passing_transcripts.txt ../results/novel_transcripts_only.with_base_id.bed \
    | cut -f1-6 > ../results/novel_transcripts_passing.sorted.bed

echo "novel_transcripts_passing.sorted.bed:"
wc -l ../results/novel_transcripts_passing.sorted.bed

awk -F'\t' '$6=="+"' ../results/novel_transcripts_passing.sorted.bed > ../results/filtered_plus.bed
awk -F'\t' '$6=="-"' ../results/novel_transcripts_passing.sorted.bed > ../results/filtered_minus.bed
echo "plus / minus strand counts:"
wc -l ../results/filtered_plus.bed ../results/filtered_minus.bed

bedtools merge -i ../results/filtered_plus.bed  -c 4,6 -o collapse,distinct > ../results/filtered_loci_plus.bed
bedtools merge -i ../results/filtered_minus.bed -c 4,6 -o collapse,distinct > ../results/filtered_loci_minus.bed
cat ../results/filtered_loci_plus.bed ../results/filtered_loci_minus.bed | sort -k1,1 -k2,2n > ../results/filtered_loci_merged.bed

echo "filtered_loci_merged.bed:"
wc -l ../results/filtered_loci_merged.bed
