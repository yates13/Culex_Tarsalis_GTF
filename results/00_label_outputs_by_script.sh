#!/bin/bash
#SBATCH --partition=acpu
#SBATCH --job-name=00_label_outputs_by_script
#SBATCH --output=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/00_label_outputs_by_script_%j.out
#SBATCH --error=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/logs/00_label_outputs_by_script_%j.err
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --qos=cpu-normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=c832500103@colostate.edu

# UTILITY - not part of the numbered pipeline, run directly (no sbatch needed).
#
# Creates results/labeled/ containing symlinks to every pipeline output file,
# each renamed with a prefix showing which script produced it. Originals in
# results/ are left completely untouched, so nothing downstream breaks -
# every existing script still finds its inputs under their original names.
#
# Re-run any time after adding new output files; existing correct symlinks
# are left alone (ln -sf overwrites cleanly, -n prevents recursing into
# an existing directory symlink).

set -euo pipefail

RESULTS=/scratch/alpine/c832500103@colostate.edu/culex_tarsalis_assembly/Spades_Pipeline_Organized/results
LABELED=$RESULTS/labeled

mkdir -p $LABELED

# filename -> label prefix
declare -A FILEMAP=(
  ["basefeatures_raw.mtfixed.gtf"]="01.05"
  ["real_contigs.txt"]="01.05"
  ["basefeatures_clean.gtf"]="01.05"
  ["basefeatures_realgenes.gtf"]="01.05"
  ["gmap_genes.sorted.bed"]="01.04-06"
  ["basefeatures_genes.sorted.fixed.bed"]="01.06"
  ["transcript_vs_basefeatures.tsv"]="01.07"
  ["transcripts_confirmed_genes.tsv"]="01.07"
  ["transcripts_novel_loci.tsv"]="01.07"
  ["novel_transcripts_only.sorted.bed"]="01.07"
  ["gmap_mrna_quality.tsv"]="01.08"
  ["passing_transcripts.txt"]="01.09"
  ["novel_transcripts_only.with_base_id.bed"]="01.09"
  ["novel_transcripts_passing.sorted.bed"]="01.09"
  ["filtered_plus.bed"]="01.09"
  ["filtered_minus.bed"]="01.09"
  ["filtered_loci_plus.bed"]="01.09"
  ["filtered_loci_minus.bed"]="01.09"
  ["filtered_loci_merged.bed"]="01.09"
  ["novel_loci_final_accepted.bed"]="01.10"
  ["novel_loci_flagged_large.bed"]="01.10"
  ["novel_loci_final_QC_passed.bed"]="01.10"
  ["basefeatures_realgenes.mtfixed.gtf"]="01.11"
  ["novel_loci.formatted.gtf"]="01.11"
  ["novel_loci.high_confidence.gtf"]="01.11"
  ["novel_loci.needs_review.gtf"]="01.11"
  ["basefeatures_updated_high_confidence.gtf"]="01.12_FINAL"
  ["basefeatures_updated_all.gtf"]="01.12_FINAL"
  ["basefeatures_needs_review_candidates.gtf"]="01.12"
  ["high_confidence_coords.bed"]="01.13"
  ["high_confidence_full.bed"]="01.13"
  ["representative_transcript_ids_highconfidence.txt"]="01.13"
  ["novel_highconfidence_representative.fasta"]="01.13"
  ["blastx_highconfidence_all_hits.tsv"]="01.15"
  ["highconfidence_strong_hit_ids.txt"]="01.15"
  ["highconfidence_any_hit_ids.txt"]="01.15"
  ["highconfidence_no_hit_ids.txt"]="01.15"
  ["highconfidence_e20_hit_ids.txt"]="01.16"
  ["geneid_to_repid_map.tsv"]="01.16"
  ["confirmed_gene_ids_e20.txt"]="01.16"
  ["novel_loci.e20_confirmed.gtf"]="01.16"
  ["basefeatures_updated_e20_confirmed.gtf"]="01.16_FINAL"
  ["hc_full_with_repid.tsv"]="01.16"
)

# filename -> label prefix, for directories
declare -A DIRMAP=(
  ["gmap_index"]="01.01"
  ["chunks"]="01.02"
  ["gmap_results"]="01.03"
  ["highconfidence_chunks"]="01.13"
  ["blastx_db"]="01.13"
  ["blastx_results"]="01.14"
)

echo "Linking files..."
for fname in "${!FILEMAP[@]}"; do
  if [ -e "$RESULTS/$fname" ]; then
    ln -sf "$RESULTS/$fname" "$LABELED/${FILEMAP[$fname]}_${fname}"
    echo "  linked: ${FILEMAP[$fname]}_${fname}"
  else
    echo "  SKIP (not found): $fname"
  fi
done

echo ""
echo "Linking directories..."
for dname in "${!DIRMAP[@]}"; do
  if [ -d "$RESULTS/$dname" ]; then
    ln -sfn "$RESULTS/$dname" "$LABELED/${DIRMAP[$dname]}_${dname}"
    echo "  linked: ${DIRMAP[$dname]}_${dname}"
  else
    echo "  SKIP (not found): $dname"
  fi
done

echo ""
echo "Note: 02.2_aedes_blastn/, 02.3_comparison/, and 01.16 outputs already"
echo "  live in clearly-numbered subfolders and are not duplicated here."
echo ""
echo "Done. Browse: ls -la $LABELED"
