"""Kosovel's poems from the Slovenian Wikisource dump, as Arrow tables.

Input: slwikisource-latest-pages-articles.xml.bz2 (https://dumps.wikimedia.org/slwikisource/latest/).
Output, next to this script:
  kosovel.parquet   one row per poem: title, collection, kind, text, lines, words (storage)
  kosovel.arrows    the same table as an Arrow IPC stream (what Nim reads, with nanoarrow)
  kosovel.json      the same, small, for the page's widgets
Every page kept is marked "javna last" (public domain) on Wikisource; Kosovel died in 1926.
Usage: python3 make_dataset.py path/to/slwikisource-latest-pages-articles.xml.bz2
"""
import bz2, json, re, sys, os
import xml.etree.ElementTree as ET
import pyarrow as pa, pyarrow.parquet as pq

here = os.path.dirname(os.path.abspath(__file__))

def field(tpl, name):
    m = re.search(r"\|\s*" + name + r"\s*=\s*([^\n]*)", tpl)
    if not m:
        return ""
    v, depth = m.group(1), 0
    for i, c in enumerate(v):       # stop at a "|" outside [[...]]: the next field
        depth += (c == "[") - (c == "]")
        if c == "|" and depth == 0:
            return v[:i].strip()
    return v.strip().removesuffix("}}")

def clean(s):
    s = re.sub(r"\[\[(?:[^\]|]*\|)?([^\]]*)\]\]", r"\1", s)     # [[a|b]] -> b
    s = re.sub(r"'''?", "", s)
    s = re.sub(r"<[^>]+>", "", s)
    s = re.sub(r"\{\{[^}]*\}\}", "", s)
    return s.replace("&nbsp;", " ")

rows = []
for _, el in ET.iterparse(bz2.open(sys.argv[1]), events=("end",)):
    if not el.tag.endswith("}page"):
        continue
    q = el.tag.split("}")[0] + "}"
    title, ns = el.findtext(q + "title"), el.findtext(q + "ns")
    text = el.findtext(".//" + q + "text") or ""
    el.clear()
    if ns != "0" or "{{naslov" not in text:
        continue
    tpl = text[text.index("{{naslov"):]
    tpl = tpl[:tpl.index("}}") + 2] if "}}" in tpl else tpl
    if "Kosovel" not in field(tpl, "avtor"):
        continue
    if "javna last" not in tpl:
        continue
    cats = re.findall(r"\[\[Kategorija:\s*([^\]|]+)", text)
    body = text[text.index(tpl) + len(tpl):]
    m = re.search(r"<poem>(.*?)</poem>", body, re.S)
    if m:
        lines = m.group(1).strip("\n").split("\n")
        kind = "kons" if re.search(r"Kons|Integrali", title + " ".join(cats)) else "pesem"
    else:
        body = re.sub(r"\[\[(Kategorija|Slika|File|Datoteka):[^\]]*\]\]", "", body)
        lines = [l for l in body.strip().split("\n")]
        kind = "proza" if any("Proza" in c for c in cats) else "pesem"
    lines = [clean(l).lstrip(":").rstrip() for l in lines]
    while lines and not lines[-1].strip(): lines.pop()
    while lines and not lines[0].strip(): lines.pop(0)
    poem = "\n".join(lines)
    if len(poem) < 20:
        continue
    coll = clean(field(tpl, "poglavje")).strip("() ,")
    coll = re.sub(r"\s*\((Srečko )?Kosovel[^)]*\)", "", coll).split(",")[-1].strip() or "Pesmi"
    rows.append(dict(title=clean(field(tpl, "naslov")) or title, page=title, collection=coll,
                     kind=kind, text=poem, lines=sum(1 for l in lines if l.strip()),
                     words=len(re.findall(r"\w+", poem))))

# one page per poem: drop exact duplicate texts (some poems are on two pages)
seen, uniq = set(), []
for r in sorted(rows, key=lambda r: r["page"]):
    if r["text"] not in seen:
        seen.add(r["text"]); uniq.append(r)
t = pa.Table.from_pylist(uniq)
pq.write_table(t, os.path.join(here, "kosovel.parquet"), compression="zstd")
with pa.ipc.new_stream(os.path.join(here, "kosovel.arrows"), t.schema) as w:
    w.write_table(t, max_chunksize=256)
json.dump(uniq, open(os.path.join(here, "kosovel.json"), "w"), ensure_ascii=False)
print(t.num_rows, "texts;", t.group_by("kind").aggregate([("words", "sum"), ("title", "count")]).to_pylist())
