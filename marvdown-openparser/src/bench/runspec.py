"""Runs spec examples (a --dump-tests JSON) through programs that read Markdown on stdin and write
HTML; prints passed examples per section as TSV. Compared with CommonMark's own normalize_html, after
two lenient fixes: `class=""` dropped and the newline before `</code></pre>` ignored."""
import json, subprocess, sys, os, collections
sys.path.insert(0, os.path.join(os.environ.get('MO_BENCH_DEPS', 'deps'), 'commonmark-spec', 'test'))
from normalize import normalize_html
fix = lambda h: h.replace(' class=""', '').replace('\n</code></pre>', '</code></pre>')
tests = json.load(open(sys.argv[1])); progs = sys.argv[2:]
res = {p: collections.Counter() for p in progs}; tot = collections.Counter()
for t in tests:
    tot[t['section']] += 1
    for p in progs:
        try: out = subprocess.run([p], input=t['markdown'].encode(), capture_output=True, timeout=5).stdout.decode('utf8', 'replace')
        except Exception: out = ''
        if normalize_html(fix(out)) == normalize_html(fix(t['html'])): res[p][t['section']] += 1
print('section\texamples\t' + '\t'.join(os.path.basename(p) for p in progs))
for s in tot: print(f"{s}\t{tot[s]}\t" + '\t'.join(str(res[p][s]) for p in progs))
