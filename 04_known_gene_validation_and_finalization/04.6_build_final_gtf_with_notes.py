#!/usr/bin/env python3
"""
STEP 04.6 - combine every name source into one gene_id -> note lookup, then
write a new copy of basefeatures_updated_high_confidence.gtf with a `note`
attribute appended to every gene line that has a resolved name. gene_id is
NEVER touched. Genes with no resolved name are left completely unchanged.

Name sources, in priority order (first match wins per gene_id):
  1. Geneious / VectorBase raw-GTF "Name" attribute
     (real names for the 6 Geneious Mt genes + the 1 VectorBase gene -
      MAKER's "Name" is just a pipeline/method label and is NOT used)
  2. Known-gene blastx hit (known_gene_blastx_best_hits_parsed.tsv),
     via gene_to_representative_transcript.tsv
  3. Novel-gene blastx hit (novel_gene_blastx_best_hits_parsed.tsv),
     via novel_gene_to_representative_transcript.tsv

Output: basefeatures_updated_high_confidence.with_notes.gtf
        gene_name_lookup.tsv   (gene_id, note, source - for your own review)
"""

import re
import sys

RAW_GTF = "../data/basefeatures_raw.gtf"
IN_GTF = "../results/basefeatures_updated_high_confidence.gtf"
OUT_GTF = "../results/basefeatures_updated_high_confidence.with_notes.gtf"
OUT_LOOKUP = "../results/gene_name_lookup.tsv"

KNOWN_MAP = "../results/gene_to_representative_transcript.tsv"
NOVEL_MAP = "../results/novel_gene_to_representative_transcript.tsv"
KNOWN_HITS = "../results/known_gene_blastx_best_hits_parsed.tsv"
NOVEL_HITS = "../results/novel_gene_blastx_best_hits_parsed.tsv"

# Include the tier in the note so you can filter by confidence later.
# Set to False if you'd rather have just the plain name with no tier tag.
INCLUDE_TIER_IN_NOTE = True

GENE_ID_RE = re.compile(r'gene_id "([^"]+)"')
NAME_RE = re.compile(r'Name "([^"]+)"')


def escape_for_gtf(value: str) -> str:
    # GTF attribute values are double-quoted; escape any embedded quotes
    # and strip newlines/tabs so we never emit a malformed line.
    return value.replace('"', "'").replace("\n", " ").replace("\t", " ").strip()


def load_geneious_vectorbase_names():
    """Pull real names from raw GTF gene-level lines sourced from Geneious or
    VectorBase only (source = column 2). MAKER source is deliberately excluded."""
    names = {}
    with open(RAW_GTF) as f:
        for line in f:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 9:
                continue
            source, feature = cols[1], cols[2]
            if feature != "gene":
                continue
            if source not in ("Geneious", "VectorBase"):
                continue
            attrs = cols[8]
            gid_m = GENE_ID_RE.search(attrs)
            name_m = NAME_RE.search(attrs)
            if gid_m and name_m:
                names[gid_m.group(1)] = (name_m.group(1), source)
    print(f"Geneious/VectorBase names loaded: {len(names)}", file=sys.stderr)
    return names


def load_gene_to_transcript(path):
    mapping = {}
    with open(path) as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 2:
                continue
            gene_id, transcript_id = parts
            mapping[gene_id] = transcript_id
    return mapping


def load_transcript_hits(path):
    """Returns transcript_id -> (parsed_name, tier)"""
    hits = {}
    with open(path) as f:
        header = f.readline()  # skip header row
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 6:
                continue
            qseqid, evalue, bitscore, tier, parsed_name, raw_stitle = parts[:6]
            hits[qseqid] = (parsed_name, tier)
    return hits


def build_note(name: str, source: str, tier: str = None) -> str:
    if INCLUDE_TIER_IN_NOTE and tier:
        return f"{name} [{source}: {tier}]"
    return f"{name} [{source}]"


def main():
    geneious_vectorbase = load_geneious_vectorbase_names()
    known_gene_to_transcript = load_gene_to_transcript(KNOWN_MAP)
    novel_gene_to_transcript = load_gene_to_transcript(NOVEL_MAP)
    known_hits = load_transcript_hits(KNOWN_HITS)
    novel_hits = load_transcript_hits(NOVEL_HITS)

    # gene_id -> (note_text, source_label)   built once, used both for the
    # lookup TSV and for writing the GTF
    gene_notes = {}
    source_counts = {"geneious_vectorbase": 0, "known_blastx": 0, "novel_blastx": 0}

    # Priority 1: Geneious/VectorBase real names
    for gene_id, (name, source) in geneious_vectorbase.items():
        gene_notes[gene_id] = build_note(name, source)
        source_counts["geneious_vectorbase"] += 1

    # Priority 2: known-gene blastx hits (only if not already named above)
    for gene_id, transcript_id in known_gene_to_transcript.items():
        if gene_id in gene_notes:
            continue
        hit = known_hits.get(transcript_id)
        if hit:
            name, tier = hit
            gene_notes[gene_id] = build_note(name, "blastx_swissprot", tier)
            source_counts["known_blastx"] += 1

    # Priority 3: novel-gene blastx hits
    for gene_id, transcript_id in novel_gene_to_transcript.items():
        if gene_id in gene_notes:
            continue
        hit = novel_hits.get(transcript_id)
        if hit:
            name, tier = hit
            gene_notes[gene_id] = build_note(name, "blastx_swissprot", tier)
            source_counts["novel_blastx"] += 1

    print(f"Source breakdown: {source_counts}", file=sys.stderr)
    print(f"Total genes with a note: {len(gene_notes)}", file=sys.stderr)

    # write the lookup table for manual review
    with open(OUT_LOOKUP, "w") as f:
        f.write("gene_id\tnote\n")
        for gene_id in sorted(gene_notes.keys()):
            f.write(f"{gene_id}\t{gene_notes[gene_id]}\n")

    # write the updated GTF - gene_id untouched, note appended only where resolved
    written = 0
    annotated = 0
    with open(IN_GTF) as fin, open(OUT_GTF, "w") as fout:
        for line in fin:
            raw = line.rstrip("\n")
            cols = raw.split("\t")
            if len(cols) < 9:
                fout.write(line)
                written += 1
                continue

            gid_m = GENE_ID_RE.search(cols[8])
            gene_id = gid_m.group(1) if gid_m else None

            if gene_id and gene_id in gene_notes:
                note_val = escape_for_gtf(gene_notes[gene_id])
                attrs = cols[8].rstrip()
                if not attrs.endswith(";"):
                    attrs += ";"
                attrs += f' note "{note_val}";'
                cols[8] = attrs
                fout.write("\t".join(cols) + "\n")
                annotated += 1
            else:
                fout.write(line)
            written += 1

    print(f"GTF lines written: {written}, lines with a note added: {annotated}", file=sys.stderr)
    print(f"Wrote {OUT_GTF}", file=sys.stderr)
    print(f"Wrote {OUT_LOOKUP}", file=sys.stderr)


if __name__ == "__main__":
    main()
