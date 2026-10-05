#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=02.4_known_gene_representative_aedes
#SBATCH --output=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/02.4_known_gene_representative_aedes_%j.out
#SBATCH --error=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/02.4_known_gene_representative_aedes_%j.err
#SBATCH --time=00:15:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 02.4 - the 02.3 known-gene baseline (7.2%) was computed on ALL
# 161,890 supporting transcripts per known gene, unfiltered - many of which
# are short fragments/partial exons/redundant isoforms. The 11,993 candidate
# rate, by contrast, used ONE representative (longest) transcript per locus
# (chosen in 01.13). Comparing "every transcript" against "one best
# transcript" is not apples-to-apples - short fragments align worse
# regardless of whether the underlying gene is real.
#
# This step picks ONE representative (longest) transcript per known gene,
# the same way 01.13 did for candidates, then recomputes the Aedes hit rate
# on that equal footing.
#
# Depends on: 01.7 (transcripts_confirmed_genes.tsv),
# 02.3 (all_aedes_hit_ids.sorted.txt)

set -euo pipefail

RESULTS=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/results

# ---------------------------------------------------------------
# 1. Pick one representative (longest) transcript per known gene_id.
#    transcripts_confirmed_genes.tsv columns (bedtools intersect -wao):
#    1-6 = transcript bed (chrom,start,end,transcript_id,score,strand)
#    7-12 = known gene bed (chrom,start,end,gene_id,score,strand)
#    13 = overlap bp
#    transcript_id carries a ".pathN" suffix (stripped) and a
#    "..._length_<N>_cov_..." token we parse for sequence length.
# ---------------------------------------------------------------
awk -F'\t' '
{
  tid = $4
  sub(/\.path[0-9]+$/, "", tid)
  gid = $10

  n = split(tid, p, "_length_")
  if (n >= 2) {
    split(p[2], p2, "_cov_")
    len = p2[1] + 0
  } else {
    len = 0
  }

  if (!(gid in best_len) || len > best_len[gid]) {
    best_len[gid] = len
    best_id[gid] = tid
  }
}
END {
  for (g in best_id) print best_id[g]
}
' $RESULTS/transcripts_confirmed_genes.tsv | sort -u \
  > $RESULTS/02.3_comparison/known_gene_representative_transcript_ids.txt

echo "Known genes with a representative transcript chosen:"
wc -l $RESULTS/02.3_comparison/known_gene_representative_transcript_ids.txt

# ---------------------------------------------------------------
# 2. Intersect representative known-gene transcripts against the Aedes
#    hit list (already built in 02.3).
# ---------------------------------------------------------------
comm -12 $RESULTS/02.3_comparison/known_gene_representative_transcript_ids.txt \
         $RESULTS/02.3_comparison/all_aedes_hit_ids.sorted.txt \
         > $RESULTS/02.3_comparison/known_gene_representatives_with_aedes_hit.txt

KNOWN_REP_TOTAL=$(wc -l < $RESULTS/02.3_comparison/known_gene_representative_transcript_ids.txt)
KNOWN_REP_HIT=$(wc -l < $RESULTS/02.3_comparison/known_gene_representatives_with_aedes_hit.txt)

echo ""
echo "=== Apples-to-apples baseline (one representative transcript per known gene) ==="
echo "Known genes represented: $KNOWN_REP_TOTAL"
echo "...with an Aedes hit: $KNOWN_REP_HIT ($(awk "BEGIN{printf \"%.1f\", $KNOWN_REP_HIT/$KNOWN_REP_TOTAL*100}")%)"
echo ""
echo "Compare to candidate rate: 648/11993 (5.4%)"
