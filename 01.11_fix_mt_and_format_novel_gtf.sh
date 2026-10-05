#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.11_mtfix_format_gtf
#SBATCH --output=../logs/01.11_mtfix_format_gtf_%j.out
#SBATCH --error=../logs/01.11_mtfix_format_gtf_%j.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 01.11 - fix the Mt contig-name mismatch in basefeatures (Mt ->
# Mt_CtarK1_noOVERLAP_RC.1, matching the genome FASTA), and convert the
# QC-passed novel loci from BED into proper GTF gene records, each tagged
# with a span_flag (typical_span / large_span / very_large_span_review_recommended)
# for downstream confidence tiering. Depends on 01.5 and 01.10.

set -euo pipefail

# 1. Mt contig name fix on basefeatures
awk -F'\t' 'BEGIN{OFS="\t"} {
    if ($1=="Mt") $1="Mt_CtarK1_noOVERLAP_RC.1";
    print
}' ../results/basefeatures_realgenes.gtf > ../results/basefeatures_realgenes.mtfixed.gtf

echo "Mt rows remaining (expect 0):"
awk -F'\t' '$1=="Mt"' ../results/basefeatures_realgenes.mtfixed.gtf | wc -l
echo "Mt rows renamed (expect 6-7):"
grep -c "Mt_CtarK1_noOVERLAP_RC.1" ../results/basefeatures_realgenes.mtfixed.gtf

# 2. novel loci BED -> GTF gene records with span_flag
awk -F'\t' 'BEGIN{OFS="\t"; n=0}
{
    n++;
    ntx = split($4, a, ",");
    span = $3 - $2;
    id = sprintf("novel_gene_%05d", n);
    start = $2 + 1;
    end   = $3;
    strand = $5;

    if (span <= 5000)       flag = "typical_span";
    else if (span <= 10000) flag = "large_span";
    else                    flag = "very_large_span_review_recommended";

    printf "%s\tgmap_rnaspades\tgene\t%d\t%d\t.\t%s\t.\tgene_id \"%s\"; ID \"%s\"; Name \"novel locus, n=%d supporting transcripts\"; support_transcripts \"%d\"; span_flag \"%s\";\n", \
        $1, start, end, strand, id, id, ntx, ntx, flag;
}' ../results/novel_loci_final_QC_passed.bed > ../results/novel_loci.formatted.gtf

echo "novel_loci.formatted.gtf:"
wc -l ../results/novel_loci.formatted.gtf
echo "span_flag breakdown:"
grep -o 'span_flag "[^"]*"' ../results/novel_loci.formatted.gtf | sort | uniq -c
