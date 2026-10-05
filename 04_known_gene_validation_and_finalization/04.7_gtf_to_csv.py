#!/usr/bin/env python3
"""
STEP 04.7 - convert basefeatures_updated_high_confidence.with_notes.gtf into
a clean CSV for viewing in Excel. Splits the packed attribute column into
proper fields instead of leaving one long GTF-style string.

Output columns:
    gene_id, contig, start, end, strand, source, provenance,
    support_transcripts, span_flag, note_full, note_name, note_source, note_tier

provenance = "known" (maker/Geneious/VectorBase) or "novel" (gmap_rnaspades),
             derived from the source column - lets you filter/sort in Excel
             without parsing gene_id naming conventions yourself.

note_name / note_source / note_tier = the note field split apart, e.g.
    note "Vitellogenin-A1 [blastx_swissprot: strong]"
    -> note_name = "Vitellogenin-A1"
       note_source = "blastx_swissprot"
       note_tier = "strong"
(Geneious/VectorBase notes have no tier - that field is left blank.)
"""

import csv
import re
import sys

IN_GTF = "../results/basefeatures_updated_high_confidence.with_notes.gtf"
OUT_CSV = "../results/basefeatures_updated_high_confidence.for_excel.csv"

GENE_ID_RE = re.compile(r'gene_id "([^"]+)"')
SUPPORT_RE = re.compile(r'support_transcripts "([^"]+)"')
SPAN_RE = re.compile(r'span_flag "([^"]+)"')
NOTE_RE = re.compile(r'note "([^"]+)"')
NOTE_SPLIT_RE = re.compile(r'^(.*)\s\[([^:\]]+)(?::\s*([^\]]+))?\]$')

def provenance_for_source(source: str) -> str:
    return "novel" if source == "gmap_rnaspades" else "known"

def split_note(note_full: str):
    """'Name [source: tier]' or 'Name [source]' -> (name, source, tier)"""
    m = NOTE_SPLIT_RE.match(note_full)
    if not m:
        return note_full, "", ""
    name = m.group(1).strip()
    src = m.group(2).strip()
    tier = (m.group(3) or "").strip()
    return name, src, tier

def main():
    rows_written = 0
    with open(IN_GTF) as fin, open(OUT_CSV, "w", newline="") as fout:
        writer = csv.writer(fout)
        writer.writerow([
            "gene_id", "contig", "start", "end", "strand", "source", "provenance",
            "support_transcripts", "span_flag",
            "note_full", "note_name", "note_source", "note_tier",
        ])

        for line in fin:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 9:
                continue
            contig, source, feature, start, end, score, strand, frame, attrs = cols[:9]

            gid_m = GENE_ID_RE.search(attrs)
            gene_id = gid_m.group(1) if gid_m else ""

            support_m = SUPPORT_RE.search(attrs)
            support = support_m.group(1) if support_m else ""

            span_m = SPAN_RE.search(attrs)
            span = span_m.group(1) if span_m else ""

            note_m = NOTE_RE.search(attrs)
            note_full = note_m.group(1) if note_m else ""
            note_name, note_source, note_tier = split_note(note_full) if note_full else ("", "", "")

            writer.writerow([
                gene_id, contig, start, end, strand, source, provenance_for_source(source),
                support, span,
                note_full, note_name, note_source, note_tier,
            ])
            rows_written += 1

    print(f"Wrote {rows_written} rows to {OUT_CSV}", file=sys.stderr)

if __name__ == "__main__":
    main()
