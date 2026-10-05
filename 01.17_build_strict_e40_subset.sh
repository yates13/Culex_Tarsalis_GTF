#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.17_strict_e40_subset
#SBATCH --output=../logs/01.17_strict_e40_subset_%j.out
#SBATCH --error=../logs/01.17_strict_e40_subset_%j.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 01.17 - build a separate, additional strict-subset GTF: original
# 14720 genes + only novel loci whose representative transcript has a
# BLASTN-vs-genome hit at e<=1e-40. This does NOT replace
# basefeatures_updated_high_confidence.gtf (the main file used for DESeq2) -
# it's a separate, more conservative file for a specific purpose.
# Depends on 01.13 (representative transcript selection) and 01.16
# (BLASTN self-check results).

set -euo pipefail

# 1. filter BLASTN hits to e<=1e-40, get the set of passing transcript IDs
awk -F'\t' '$11 <= 1e-40 {print $1}' ../results/blastn_genome_selfcheck_hits.tsv | sort -u \
    > ../results/strict_e40_transcript_ids.txt
echo "Transcripts passing e<=1e-40:"
wc -l ../results/strict_e40_transcript_ids.txt

# 2. rebuild the transcript-id -> coordinates -> gene_id mapping.
#    representative_transcript_ids_highconfidence.txt was built in the same
#    line-order as high_confidence_full.bed, which carries chrom/start/end -
#    reconstruct that same pairing here rather than assuming a direct ID join.
awk -F'\t' 'BEGIN{OFS="\t"} {
    n=split($4,ids,",");
    best=""; bestlen=0;
    for(i=1;i<=n;i++){
        split(ids[i], parts, "_length_");
        split(parts[2], lenparts, "_");
        len = lenparts[1]+0;
        if(len > bestlen){ bestlen=len; best=ids[i]; }
    }
    sub(/\.path[0-9]*$/, "", best);
    print $1, $2, $3, best
}' ../results/high_confidence_full.bed > ../results/coords_to_representative_id.tsv

# 3. join that against novel_loci.high_confidence.gtf by coordinates to get gene_id
#    (bed is 0-based start, gtf is 1-based - convert for the join)
awk -F'\t' 'BEGIN{OFS="\t"} {
    split($9, a, ";"); gid=a[1]; gsub(/gene_id "|"/, "", gid);
    print $1, $4-1, $5, gid
}' ../results/novel_loci.high_confidence.gtf > ../results/coords_to_gene_id.tsv

awk -F'\t' 'BEGIN{OFS="\t"} NR==FNR{key[$1"\t"$2"\t"$3]=$4; next}
    ($1"\t"$2"\t"$3) in key {print $4, key[$1"\t"$2"\t"$3]}' \
    ../results/coords_to_gene_id.tsv ../results/coords_to_representative_id.tsv \
    > ../results/representative_id_to_gene_id.tsv
echo "representative_id_to_gene_id.tsv:"
wc -l ../results/representative_id_to_gene_id.tsv

# 4. get the set of gene_ids whose representative transcript passed e<=1e-40
awk -F'\t' 'NR==FNR{keep[$1]=1; next} ($1 in keep){print $2}' \
    ../results/strict_e40_transcript_ids.txt ../results/representative_id_to_gene_id.tsv \
    > ../results/strict_e40_gene_ids.txt
echo "Novel genes passing strict e<=1e-40 filter:"
wc -l ../results/strict_e40_gene_ids.txt

# 5. filter novel_loci.high_confidence.gtf down to just those gene_ids
awk -F'\t' 'NR==FNR{keep[$1]=1; next} {
    split($9, a, ";"); gid=a[1]; gsub(/gene_id "|"/, "", gid);
    if (gid in keep) print
}' ../results/strict_e40_gene_ids.txt ../results/novel_loci.high_confidence.gtf \
    > ../results/novel_loci.strict_e40.gtf
echo "novel_loci.strict_e40.gtf:"
wc -l ../results/novel_loci.strict_e40.gtf

# 6. combine with the original 14720 known genes - SEPARATE file, does not touch the main one
cat ../results/basefeatures_realgenes.mtfixed.gtf ../results/novel_loci.strict_e40.gtf | \
    sort -k1,1 -k4,4n > ../results/basefeatures_strict_e40.gtf

echo ""
echo "=== FINAL: basefeatures_strict_e40.gtf ==="
grep -c $'\tgene\t' ../results/basefeatures_strict_e40.gtf
echo "(for comparison, main high-confidence file has 26713)"
