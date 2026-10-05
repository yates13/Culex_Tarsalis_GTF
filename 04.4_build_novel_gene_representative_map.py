#!/usr/bin/env python3
"""
Step: build novel_gene_id -> representative_transcript_id mapping.

We do NOT trust that basefeatures_updated_high_confidence.gtf's novel_gene_NNNNN
lines are in the same row order as high_confidence_full.bed / 
representative_transcript_ids_highconfidence.txt (they came from different
upstream sorts/filters, even though all three happen to total 11,993).
Instead we join by genomic coordinates, which is unambiguous.

Inputs:
  basefeatures_updated_high_confidence.gtf
      -> filter to gene_id starting with "novel_gene_", get seqname/start/end (1-based)
  high_confidence_full.bed
      -> chrom, start(0-based), end, comma-separated transcript_id list (.pathN suffixed), strand
  representative_transcript_ids_highconfidence.txt
      -> the 11,993 IDs already chosen as "longest transcript" per locus (no .pathN suffix)

Output:
  novel_gene_to_representative_transcript.tsv
      gene_id <tab> representative_transcript_id
"""

import re
import sys

GTF = "../results/basefeatures_updated_high_confidence.gtf"
BED = "../results/high_confidence_full.bed"
REP_IDS = "../results/representative_transcript_ids_highconfidence.txt"
OUT = "../results/novel_gene_to_representative_transcript.tsv"

GENE_ID_RE = re.compile(r'gene_id "([^"]+)"')
PATH_SUFFIX_RE = re.compile(r"\.path\d+$")

def strip_path(tid):
    return PATH_SUFFIX_RE.sub("", tid)

def main():
    # load the set of known representative IDs for fast lookup
    with open(REP_IDS) as f:
        rep_set = set(line.strip() for line in f if line.strip())

    # index bed lines by (chrom, start_1based, end)
    bed_by_coord = {}
    with open(BED) as f:
        for line in f:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 4:
                continue
            chrom, start0, end, transcripts = cols[0], int(cols[1]), int(cols[2]), cols[3]
            start1 = start0 + 1  # convert BED 0-based to GTF 1-based
            bed_by_coord[(chrom, start1, end)] = transcripts

    matched = 0
    unmatched = 0
    ambiguous = 0

    with open(GTF) as fin, open(OUT, "w") as fout:
        for line in fin:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 9:
                continue
            attrs = cols[8]
            m = GENE_ID_RE.search(attrs)
            if not m:
                continue
            gene_id = m.group(1)
            if not gene_id.startswith("novel_gene_"):
                continue

            chrom, start, end = cols[0], int(cols[3]), int(cols[4])
            transcripts_field = bed_by_coord.get((chrom, start, end))

            if transcripts_field is None:
                unmatched += 1
                print(f"WARNING: no coordinate match for {gene_id} at {chrom}:{start}-{end}", file=sys.stderr)
                continue

            candidate_ids = [strip_path(t) for t in transcripts_field.split(",")]
            reps_found = [t for t in candidate_ids if t in rep_set]

            if len(reps_found) == 0:
                unmatched += 1
                print(f"WARNING: no representative transcript found among candidates for {gene_id}", file=sys.stderr)
                continue
            if len(reps_found) > 1:
                ambiguous += 1
                print(f"WARNING: multiple representative matches for {gene_id}, using first: {reps_found}", file=sys.stderr)

            fout.write(f"{gene_id}\t{reps_found[0]}\n")
            matched += 1

    print(f"Matched: {matched}, unmatched: {unmatched}, ambiguous (used first): {ambiguous}", file=sys.stderr)
    print(f"Wrote {OUT}", file=sys.stderr)

if __name__ == "__main__":
    main()
