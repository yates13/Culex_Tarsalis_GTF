#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=01.13_prep_blastx
#SBATCH --output=../logs/01.13_prep_blastx_%j.out
#SBATCH --error=../logs/01.13_prep_blastx_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu
#
# STEP 01.13 - extract the swissprot protein DB, and pick the longest
# supporting transcript per HIGH-CONFIDENCE novel locus (full set, not just
# needs-review) as its representative sequence for BLASTX. Scope expanded
# given the gene count (26713 total) came in well above typical mosquito
# annotations (~18883 for C. quinquefasciatus) - validating the full
# high-confidence set, not just the already-suspect large-span subset, is
# needed to actually confirm or refute that count. Depends on 01.12.

set -euo pipefail

# 1. extract the pre-built swissprot protein database
mkdir -p ../results/blastx_db
tar -xzf ../data/swissprot.tar.gz -C ../results/blastx_db/
echo "swissprot db files:"
ls -lh ../results/blastx_db/

# 2. get high-confidence locus coordinates back to 0-based BED
awk -F'\t' 'BEGIN{OFS="\t"} {print $1, $4-1, $5}' ../results/novel_loci.high_confidence.gtf \
    > ../results/high_confidence_coords.bed

# 3. pull matching full lines (with transcript id lists) from the QC-passed bed
awk -F'\t' 'BEGIN{OFS="\t"} NR==FNR{key[$1"\t"$2"\t"$3]=1; next} ($1"\t"$2"\t"$3) in key' \
    ../results/high_confidence_coords.bed ../results/novel_loci_final_QC_passed.bed \
    > ../results/high_confidence_full.bed
echo "high_confidence_full.bed:"
wc -l ../results/high_confidence_full.bed

# 4. pick the longest transcript per locus (rnaSPAdes encodes length in the NODE name)
awk -F'\t' '{
    n=split($4,ids,",");
    best=""; bestlen=0;
    for(i=1;i<=n;i++){
        split(ids[i], parts, "_length_");
        split(parts[2], lenparts, "_");
        len = lenparts[1]+0;
        if(len > bestlen){ bestlen=len; best=ids[i]; }
    }
    print best
}' ../results/high_confidence_full.bed | sed 's/\.path[0-9]*$//' > ../results/representative_transcript_ids_highconfidence.txt
echo "representative_transcript_ids_highconfidence.txt:"
wc -l ../results/representative_transcript_ids_highconfidence.txt

# 5. pull those sequences out of the transcriptome
source /scratch/alpine/c832500103@colostate.edu/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/alpine/c832500103@colostate.edu/conda_envs/cellSquito

seqkit grep -f ../results/representative_transcript_ids_highconfidence.txt ../data/transcriptome.fasta \
    > ../results/novel_highconfidence_representative.fasta
echo "sequences pulled (expect to match line count above):"
grep -c "^>" ../results/novel_highconfidence_representative.fasta

# 6. split into 20 chunks for the BLASTX array job (scaled up from 10 given ~2.5x more sequences)
mkdir -p ../results/highconfidence_chunks
seqkit split2 -p 20 -O ../results/highconfidence_chunks ../results/novel_highconfidence_representative.fasta
echo "chunk files created:"
ls ../results/highconfidence_chunks/
