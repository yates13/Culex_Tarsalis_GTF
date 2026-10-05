#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.15_classify_blastx
#SBATCH --output=../logs/01.15_classify_blastx_%j.out
#SBATCH --error=../logs/01.15_classify_blastx_%j.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu

# STEP 01.15 - combine BLASTX array results and classify each high-confidence
# novel locus as strong-hit / any-hit / no-hit. Depends on 01.14 (all 20 array
# tasks complete).

set -euo pipefail

NPARTS=$(ls ../results/blastx_results/blastx_part_*.tsv 2>/dev/null | wc -l)
if [ "$NPARTS" -ne 20 ]; then
    echo "ERROR: expected 20 result files, found $NPARTS. Check 01.14 completed fully." >&2
    exit 1
fi

cat ../results/blastx_results/blastx_part_*.tsv > ../results/blastx_highconfidence_all_hits.tsv
echo "Total hit rows:"
wc -l ../results/blastx_highconfidence_all_hits.tsv

awk -F'\t' '$5 < 1e-10 {print $1}' ../results/blastx_highconfidence_all_hits.tsv | sort -u \
    > ../results/highconfidence_strong_hit_ids.txt
echo "Strong hits:"
wc -l ../results/highconfidence_strong_hit_ids.txt

awk -F'\t' '$5 < 1e-20 {print $1}' ../results/blastx_highconfidence_all_hits.tsv | sort -u \
    > ../results/highconfidence_verystrong_hit_ids.txt
echo "Very strong hits (e<1e-20):"
wc -l ../results/highconfidence_verystrong_hit_ids.txt

awk -F'\t' '$5 < 1e-40 {print $1}' ../results/blastx_highconfidence_all_hits.tsv | sort -u \
    > ../results/highconfidence_extremestrong_hit_ids.txt
echo "Extremely strong hits (e<1e-40):"
wc -l ../results/highconfidence_extremestrong_hit_ids.txt

cut -f1 ../results/blastx_highconfidence_all_hits.tsv | sort -u > ../results/highconfidence_any_hit_ids.txt
echo "Any hit:"
wc -l ../results/highconfidence_any_hit_ids.txt

comm -23 <(sort ../results/representative_transcript_ids_highconfidence.txt) \
         <(sort ../results/highconfidence_any_hit_ids.txt) \
         > ../results/highconfidence_no_hit_ids.txt
echo "No hit:"
wc -l ../results/highconfidence_no_hit_ids.txt

echo ""
echo "=== Summary as percentage of total high-confidence novel loci ==="
TOTAL=$(wc -l < ../results/representative_transcript_ids_highconfidence.txt)
STRONG=$(wc -l < ../results/highconfidence_strong_hit_ids.txt)
VERYSTRONG=$(wc -l < ../results/highconfidence_verystrong_hit_ids.txt)
EXTREME=$(wc -l < ../results/highconfidence_extremestrong_hit_ids.txt)
ANY=$(wc -l < ../results/highconfidence_any_hit_ids.txt)
NOHIT=$(wc -l < ../results/highconfidence_no_hit_ids.txt)
echo "Total: $TOTAL"
echo "Any hit (e<1e-5): $ANY ($(awk "BEGIN{printf \"%.1f\", $ANY/$TOTAL*100}")%)"
echo "Strong hit (e<1e-10): $STRONG ($(awk "BEGIN{printf \"%.1f\", $STRONG/$TOTAL*100}")%)"
echo "Very strong hit (e<1e-20): $VERYSTRONG ($(awk "BEGIN{printf \"%.1f\", $VERYSTRONG/$TOTAL*100}")%)"
echo "Extremely strong hit (e<1e-40): $EXTREME ($(awk "BEGIN{printf \"%.1f\", $EXTREME/$TOTAL*100}")%)"
echo "No hit: $NOHIT ($(awk "BEGIN{printf \"%.1f\", $NOHIT/$TOTAL*100}")%)"


