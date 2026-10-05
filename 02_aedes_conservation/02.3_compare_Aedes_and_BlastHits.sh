#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=02.3_compare_aedes_blastx
#SBATCH --output=../logs/02.3_compare_aedes_blastx_%j.out
#SBATCH --error=../logs/02.3_compare_aedes_blastx_%j.err
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 02.3 - cross-reference the two independent confirmation methods for
# the 11,993 novel candidates: BLASTX vs SwissProt (protein similarity) and
# BLASTN vs Aedes aegypti genome (cross-species conservation). Also computes
# a known-gene baseline conservation rate for comparison.
#
# ID FORMAT NOTE: transcripts_confirmed_genes.tsv (known-gene transcripts)
# carries a ".pathN" suffix (from GMAP path output) that representative
# transcript IDs and best_hits.tsv do NOT have. This suffix is stripped
# before comparison - without this, the known-gene baseline would silently
# show 0% Aedes conservation (a false negative from ID mismatch, not biology).
#
# Depends on: 02.2 (best_hits.tsv), 01.15 (BLASTX tier files),
# 01.13 (representative_transcript_ids_highconfidence.txt),
# 01.7 (transcripts_confirmed_genes.tsv)

set -euo pipefail

RESULTS=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/results
AEDES=$RESULTS/02.2_aedes_blastn

mkdir -p $RESULTS/02.3_comparison

# ---------------------------------------------------------------
# 1. Restrict Aedes best-hits to just the 11,993 candidates
# ---------------------------------------------------------------
awk -F'\t' 'NR==FNR{ids[$1]; next} $1 in ids' \
    $RESULTS/representative_transcript_ids_highconfidence.txt \
    $AEDES/best_hits.tsv \
    > $RESULTS/02.3_comparison/aedes_hits_candidates.tsv

cut -f1 $RESULTS/02.3_comparison/aedes_hits_candidates.tsv | sort -u \
    > $RESULTS/02.3_comparison/ids_with_aedes_hit.txt

echo "Candidates (of 11,993) with an Aedes hit:"
wc -l $RESULTS/02.3_comparison/ids_with_aedes_hit.txt

# ---------------------------------------------------------------
# 2. Four-way comparison: BLASTX (any hit, e<1e-5) vs Aedes hit
# ---------------------------------------------------------------
sort $RESULTS/highconfidence_any_hit_ids.txt > $RESULTS/02.3_comparison/blastx_any_hit.sorted.txt
sort $RESULTS/02.3_comparison/ids_with_aedes_hit.txt > $RESULTS/02.3_comparison/aedes_hit.sorted.txt

comm -12 $RESULTS/02.3_comparison/blastx_any_hit.sorted.txt \
         $RESULTS/02.3_comparison/aedes_hit.sorted.txt \
         > $RESULTS/02.3_comparison/both_blastx_and_aedes.txt

comm -23 $RESULTS/02.3_comparison/blastx_any_hit.sorted.txt \
         $RESULTS/02.3_comparison/aedes_hit.sorted.txt \
         > $RESULTS/02.3_comparison/blastx_only.txt

comm -13 $RESULTS/02.3_comparison/blastx_any_hit.sorted.txt \
         $RESULTS/02.3_comparison/aedes_hit.sorted.txt \
         > $RESULTS/02.3_comparison/aedes_only.txt

BOTH=$(wc -l < $RESULTS/02.3_comparison/both_blastx_and_aedes.txt)
BLASTX_ONLY=$(wc -l < $RESULTS/02.3_comparison/blastx_only.txt)
AEDES_ONLY=$(wc -l < $RESULTS/02.3_comparison/aedes_only.txt)
TOTAL_CANDIDATES=$(wc -l < $RESULTS/representative_transcript_ids_highconfidence.txt)
NEITHER=$((TOTAL_CANDIDATES - BOTH - BLASTX_ONLY - AEDES_ONLY))

echo ""
echo "=== Four-way breakdown of 11,993 candidates ==="
echo "Both BLASTX and Aedes hit: $BOTH"
echo "BLASTX only:                $BLASTX_ONLY"
echo "Aedes only:                  $AEDES_ONLY"
echo "Neither:                     $NEITHER"

# ---------------------------------------------------------------
# 3. Known-gene baseline: what fraction of ALREADY-CONFIRMED known
#    gene transcripts show Aedes conservation? This should be much
#    higher than the candidate rate above, as a sanity check.
# ---------------------------------------------------------------
cut -f4 $RESULTS/transcripts_confirmed_genes.tsv \
    | sed 's/\.path[0-9]*$//' \
    | sort -u \
    > $RESULTS/02.3_comparison/known_gene_transcript_ids.txt

echo ""
echo "Unique known-gene transcript IDs (suffix-stripped):"
wc -l $RESULTS/02.3_comparison/known_gene_transcript_ids.txt

cut -f1 $AEDES/best_hits.tsv | sort -u > $RESULTS/02.3_comparison/all_aedes_hit_ids.sorted.txt

comm -12 $RESULTS/02.3_comparison/known_gene_transcript_ids.txt \
         $RESULTS/02.3_comparison/all_aedes_hit_ids.sorted.txt 

         > $RESULTS/02.3_comparison/known_genes_with_aedes_hit.txt

KNOWN_TOTAL=$(wc -l < $RESULTS/02.3_comparison/known_gene_transcript_ids.txt)
KNOWN_WITH_HIT=$(wc -l < $RESULTS/02.3_comparison/known_genes_with_aedes_hit.txt)

echo ""
echo "=== Known-gene baseline ==="
echo "Known-gene transcripts: $KNOWN_TOTAL"
echo "...with an Aedes hit: $KNOWN_WITH_HIT ($(awk "BEGIN{printf \"%.1f\", $KNOWN_WITH_HIT/$KNOWN_TOTAL*100}")%)"
echo ""
echo "Compare this rate to the candidate rate above ($(wc -l < $RESULTS/02.3_comparison/ids_with_aedes_hit.txt)/$TOTAL_CANDIDATES) -"
echo "known genes should conserve at a notably higher rate if the pipeline is behaving as expected."
