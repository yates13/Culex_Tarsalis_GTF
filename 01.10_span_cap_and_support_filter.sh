#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.10_span_cap_support_filter
#SBATCH --output=../logs/01.10_span_cap_support_filter_%j.out
#SBATCH --error=../logs/01.10_span_cap_support_filter_%j.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu


# STEP 01.10 - cap any merged locus over 60kb (mega-block artifact guard from
# mitochondrial polycistronic transcription and repeat-region chaining), then
# require >=3 independently-assembled supporting transcripts to call a locus
# QC-passed. Depends on 01.9.


set -euo pipefail 

awk -F'\t' 'BEGIN{OFS="\t"} {
    span = $3 - $2;
    if (span <= 60000) print > "../results/novel_loci_final_accepted.bed";
    else                print > "../results/novel_loci_flagged_large.bed";
}' ../results/filtered_loci_merged.bed

echo "accepted (<=60kb):"
[ -f ../results/novel_loci_final_accepted.bed ] && wc -l ../results/novel_loci_final_accepted.bed || echo "0 (no loci accepted)"

echo "flagged (>60kb):"
[ -f ../results/novel_loci_flagged_large.bed ] && wc -l ../results/novel_loci_flagged_large.bed || echo "0 (no loci flagged - none exceeded 60kb)"

awk -F'\t' '{ n = split($4, a, ","); if (n>=3) print }' ../results/novel_loci_final_accepted.bed \
    > ../results/novel_loci_final_QC_passed.bed

echo "novel_loci_final_QC_passed.bed (final novel loci set):"
wc -l ../results/novel_loci_final_QC_passed.bed

