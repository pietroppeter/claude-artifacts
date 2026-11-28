"""Renders each Markdown file of a list with two programs and counts the files whose HTML is the same
after CommonMark's normalize_html and lenient fixes (class="", heading ids, the newline before
</code>, &quot;). Prints one TSV line: files, same."""
import subprocess, sys, os, re
sys.path.insert(0, os.path.join(os.environ.get('MO_BENCH_DEPS', 'deps'), 'commonmark-spec', 'test'))
from normalize import normalize_html
def fix(h):
    h = h.replace(' class=""', '').replace('\n</code>', '</code>').replace('&quot;', '"')
    return re.sub(r'<(h[1-6]) id="[^"]*"', r'<\1', h)
files = [l.strip() for l in open(sys.argv[1]) if l.strip()]
a, b = sys.argv[2], sys.argv[3]
same = 0
for f in files:
    src = open(f, encoding='utf8', errors='replace').read().encode()
    ha = subprocess.run([a], input=src, capture_output=True, timeout=60).stdout.decode('utf8', 'replace')
    hb = subprocess.run([b], input=src, capture_output=True, timeout=60).stdout.decode('utf8', 'replace')
    same += normalize_html(fix(ha)) == normalize_html(fix(hb))
print("files\tsame"); print(f"{len(files)}\t{same}")
