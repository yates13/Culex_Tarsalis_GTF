#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.8_mrna_quality
#SBATCH --output=../logs/01.8_mrna_quality_%j.out
#SBATCH --error=../logs/01.8_mrna_quality_%j.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 01.8 - extract coverage%/identity% for every GMAP-aligned transcript
# from the mRNA-level GFF3 lines. Depends on 01.3 (gmap_results/*.gff3 exist).

set -euo pipefail

grep -h $'\tmRNA\t' ../results/gmap_results/gmap_part_*.gff3 | \
    awk -F'\t' 'BEGIN{OFS="\t"} {
        split($9, attrs, ";");
        id=""; cov=""; ident="";
        for (i=1; i<=length(attrs); i++) {
            if (attrs[i] ~ /^ID=/)       { id=attrs[i];    sub(/^ID=/,       "", id) }
            if (attrs[i] ~ /^coverage=/) { cov=attrs[i];   sub(/^coverage=/, "", cov) }
            if (attrs[i] ~ /^identity=/) { ident=attrs[i]; sub(/^identity=/, "", ident) }
        }
        print id, $1, $4, $5, $7, cov, ident
    }' > ../results/gmap_mrna_quality.tsv

echo "gmap_mrna_quality.tsv:"
wc -l ../results/gmap_mrna_quality.tsv
head -3 ../results/gmap_mrna_quality.tsv
