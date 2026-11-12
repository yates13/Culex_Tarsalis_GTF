# Culex tarsalis GTF

A high-confidence gene annotation for the mosquito *Culex tarsalis* (genome assembly **CtarK1**), built by merging novel genes discovered from a single-cell rnaSPAdes transcriptome into an existing curated MAKER annotation, then labeling genes by homology. The annotation is used for downstream RNA-seq differential expression (HISAT2, featureCounts, DESeq2).

Developed at Colorado State University; pipelines run on the Alpine HPC cluster (SLURM).

## Final annotation at a glance

| Item | Count |
|---|---|
| Total genes | 26,713 |
| Known genes (MAKER / Geneious / VectorBase) | 14,720 |
| Novel loci passing QC | 11,993 |

Novel loci must pass all of: **>= 70% coverage, >= 90% identity, <= 60 kb span, >= 3 supporting transcripts**. GMAP is the authoritative aligner for placing transcripts onto CtarK1.

### Output files

| File | Description |
|---|---|
| `basefeatures_updated_high_confidence.gtf` | Canonical annotation (26,713 genes) |
| `basefeatures_updated_high_confidence.no_mt.gtf` | Same, with the 6 mitochondrial genes removed |
| `basefeatures_updated_high_confidence.with_notes.gtf` | Adds `note` attributes to 7,437 genes (see caveat under Known issues) |
| `gene_name_lookup.tsv` | Gene-to-name lookup |
| `basefeatures_updated_high_confidence.for_excel.csv` | 13-column parsed table with a `provenance` column (known vs novel) |
| `basefeatures_realgenes.annotated.mosquito_rescue.gtf` | Known-genes-only (14,720) GTF, labeled per gene (SwissProt BLASTX + mosquito DIAMOND rescue) |

`gene_id` values are intentionally left unchanged in the annotated variants so known-vs-novel provenance is preserved.

## Repository layout

```
assembly/                    CtarK1 assembly
BaseFeatures_Differences/    comparisons between annotation versions
bin/  config/                helper binaries and configuration
data/                        shared input data
gmap_index/                  GMAP index of CtarK1
Spades_Pipeline_Organized/   main pipeline: novel genes + merge into final GTF
Novel_Genes_11993/           novel-gene set (data, logs, results, scripts)
Known_Genes_Original_14720/  known-gene annotation/labeling (data, logs, results, scripts)
pipelines/  stats/           pipeline wrappers and summary statistics
```

Each pipeline directory follows the same convention: `scripts/` (numbered), `data/`, `logs/`, `results/`.

## Script numbering

Numbered scripts run in order within a track. A different prefix means a **parallel track**, not a continuation.

| Prefix | Track |
|---|---|
| `01.x` | Main annotation pipeline (Spades_Pipeline_Organized) |
| `02.x` | *Aedes aegypti* (AaegL5, GCF_002204515.2) BLASTN conservation check |
| `03.x` | *Culex quinquefasciatus* (GCF_015732765.1) BLASTN conservation check (in progress) |
| `04.0`-`04.5` | Known genes: genomic BLASTX of each gene's own sequence |
| `05.1`, `05.1b`, `05.2` | Known genes: evidence tables and annotated GTF |
| `06.1`, `06.2` | Candidate transcripts for genes without hits |
| `06.4`-`06.7` | Mosquito (DIAMOND) rescue: evidence table and rescue GTF |
| `07.1` | Annotation transfer |

## Method summary

1. **Novel genes.** Transcripts from the single-cell rnaSPAdes assembly are aligned to CtarK1 with GMAP, grouped into loci, and filtered with the QC thresholds above.
2. **Merge.** Passing loci are merged with the 14,720 known genes (source column `maker`, `Geneious` or `VectorBase`) to produce `basefeatures_updated_high_confidence.gtf`.
3. **Naming (known genes).** Each gene's own genomic sequence (extracted from the genome with the gene BED) is searched by BLASTX against SwissProt (e-value <= 1e-5). Genes with no hit receive no `note`.
4. **Mosquito rescue.** Genes with no SwissProt label are searched by DIAMOND against *Cx. quinquefasciatus*, *Ae. aegypti*, *An. gambiae* and *D. melanogaster*; the result is a labeled rescue GTF. MAKER `Name` attributes are preserved, and labels carry `annotation_source`, `annotation_method` and `annotation_name` fields.
5. **Conservation checks.** BLASTN against *Ae. aegypti* and *Cx. quinquefasciatus* as sanity checks. Known genes show a much higher conservation rate than novel candidates (22.7% vs 5.4% with *Aedes* hits).

A low BLASTX hit rate for novel loci (about 6.5% have any SwissProt hit) is expected for a non-model organism and is **not** treated as evidence against gene validity. The full 26,713-gene set is retained as canonical.

## Requirements

- SLURM cluster (scripts use `--partition=acpu`, `--qos=cpu-normal`, `--mail-type=END,FAIL`)
- GMAP, HISAT2, featureCounts, DESeq2
- BLAST+ (dedicated conda env), DIAMOND
- bedtools, samtools
- awk, sed, Python 3
- Reference data: CtarK1 assembly, SwissProt (downloaded July 2026), AaegL5, GCF_015732765.1

Scripts use explicit full conda paths rather than environment names. Edit paths for your own system before running.

## Running

Run scripts in numeric order within a track, checking the output of each step before moving on. Example:

`sbatch scripts/01.1_example.sh`

(Replace with the actual script names in each `scripts/` directory.)

## Pitfalls we hit (and fixed)

- Filter the GTF by **source column**, not feature type: `$2=="maker" || $2=="Geneious" || $2=="VectorBase"`. Filtering on `$3=="gene"` pulls in about 1.97M junk rows.
- Rename the `Mt` / `Mt_CtarK1_noOVERLAP_RC.1` contig **before** filtering to real contigs, or the 6 mitochondrial genes are silently dropped.
- bedtools needs sorted input. Sort to a temp file and `mv`; in-place `sort -o` on the same file intermittently corrupted output.
- GMAP IDs: mRNA-level IDs end in `.mrna1`, gene-level IDs end in `.path1`. Strip both before joining, otherwise the join silently matches nothing. Transcript IDs in `transcripts_confirmed_genes.tsv` also carry `.path1` and must be stripped to match `NODE_xxx` FASTA headers.
- BED is 0-based, GTF is 1-based (`bed_start + 1 == gtf_start`).
- A chromosome-name mismatch between BAM and GTF produces all-zero featureCounts; make contig names match.
- Under `set -euo pipefail`, `wc -l` on a missing file kills the script; check the file exists first.
- BLAST best-hit extraction: use a single-pass awk, not `sort -k1,1 -k12,12 -rn`.
- SwissProt `stitle` parsing must strip trailing `[Organism]` tags; strip `OS=/OX=/GN=/PE=/SV=` and use a lambda in `re.sub` when names contain backslashes.

## Known issues and open questions

- **Copied notes in the older `with_notes` GTF.** The original annotation copied one representative transcript's BLASTX hit onto every gene sharing it (for example, one note spread across gene1-gene21; gene5024-gene5028 all labeled Axin when gene5028 is RPL32). The per-gene genomic BLASTX approach in the known-genes track fixes this.
- **Transcript-derived labels.** About 1,027 of 10,799 SwissProt labels in the rescue GTF come from a `NODE_` transcript fallback rather than the gene's own sequence, and 47 have a bitscore larger than the gene length. Genomic-derived labels pass this check. Triage with `results/candidate_transcripts_nohit_genes.tsv`.
- **Weak DIAMOND hits.** The documented 1e-10 cutoff in `06.6` is not enforced; raw files contain 1,155 hits weaker than 1e-10, and 73 rescued labels have an alignment under 40 aa.
- **Planned v3 (`06.8`).** Attribute-only tags (transposable-element class, family-level labels for accessions on 10 or more genes, curated rRNA); no coordinate changes.
- *Cx. quinquefasciatus* conservation check (`03.x`) is not yet complete.
- Tiered BLASTX thresholds (1e-5, 1e-20, 1e-40) are not yet wired into downstream filtering or reporting.

## Citation / contact

Add citation, license and contact information here.
