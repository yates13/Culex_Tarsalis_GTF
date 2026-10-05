#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.4_gmap_to_bed
#SBATCH --output=../logs/01.4_gmap_to_bed_%j.out
#SBATCH --error=../logs/01.4_gmap_to_bed_%j.err
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu

# STEP 01.4 - collapse all 100 GMAP array output GFF3 files into a single
# sorted BED of gene-level alignments. Depends on 01.3 (all 100 array tasks
# must be complete). Submit from inside scripts/.

set -euo pipefail

# sanity check before doing any real work - fail loudly if chunks are missing
NCHUNKS=$(ls ../results/gmap_results/*.gff3 2>/dev/null | wc -l)
if [ "$NCHUNKS" -ne 100 ]; then
    echo "ERROR: expected 100 GFF3 files, found $NCHUNKS. Check 01.3 completed fully before running this." >&2
    exit 1
fi

grep -h $'\tgene\t' ../results/gmap_results/gmap_part_*.gff3 | \
    awk -F'\t' 'BEGIN{OFS="\t"} {
        split($9, a, ";");
        id = a[1]; sub(/^ID=/, "", id);
        print $1, $4-1, $5, id, ".", $7
    }' | sort -k1,1 -k2,2n > ../results/gmap_genes.sorted.bed

echo "=== gmap_genes.sorted.bed line count: ==="
wc -l ../results/gmap_genes.sorted.bed
echo "=== sample rows: ==="
head -5 ../results/gmap_genes.sorted.bed
