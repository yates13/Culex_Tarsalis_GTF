#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.12_split_merge_final
#SBATCH --output=../logs/01.12_split_merge_final_%j.out
#SBATCH --error=../logs/01.12_split_merge_final_%j.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 01.12 - split novel loci into high-confidence (<=10kb span) vs
# needs-review (>10kb span), merge each set with the Mt-fixed original genes
# into final basefeatures GTFs, and run sanity checks (no duplicate gene_ids,
# no stray Mt seqname). Depends on 01.11.

set -euo pipefail

awk -F'\t' '$0 !~ /very_large_span_review_recommended/' ../results/novel_loci.formatted.gtf > ../results/novel_loci.high_confidence.gtf
awk -F'\t' '$0 ~ /very_large_span_review_recommended/'  ../results/novel_loci.formatted.gtf > ../results/novel_loci.needs_review.gtf

echo "high_confidence / needs_review counts:"
wc -l ../results/novel_loci.high_confidence.gtf ../results/novel_loci.needs_review.gtf

cat ../results/basefeatures_realgenes.mtfixed.gtf ../results/novel_loci.high_confidence.gtf | \
    sort -k1,1 -k4,4n > ../results/basefeatures_updated_high_confidence.gtf

cat ../results/basefeatures_realgenes.mtfixed.gtf ../results/novel_loci.formatted.gtf | \
    sort -k1,1 -k4,4n > ../results/basefeatures_updated_all.gtf

cp ../results/novel_loci.needs_review.gtf ../results/basefeatures_needs_review_candidates.gtf

echo ""
echo "=== Final file gene counts ==="
grep -c $'\tgene\t' ../results/basefeatures_updated_high_confidence.gtf
grep -c $'\tgene\t' ../results/basefeatures_updated_all.gtf

echo ""
echo "=== Sanity checks ==="
echo "Duplicate gene_ids (expect 0):"
grep -oP 'gene_id "\K[^"]+' ../results/basefeatures_updated_all.gtf | sort | uniq -d | wc -l
echo "Stray Mt seqname (expect 0):"
awk -F'\t' '$1=="Mt"' ../results/basefeatures_updated_all.gtf | wc -l
