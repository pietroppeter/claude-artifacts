"""Builds ../index.html from template.html, the excerpts and the evidence (real outputs, 7 Nov 2026).

    python3 nim-python-bridges/src/build.py
"""
import html
from pathlib import Path

here = Path(__file__).parent
ev, ex = here / "evidence", here / "excerpts"
page = (here / "template.html").read_text(encoding="utf-8")
esc = lambda p: html.escape(p.read_text(encoding="utf-8").rstrip())

times = dict(l.split() for l in (ev / "wheel_times.txt").read_text().split("\n") if l.strip())
order = [("manylinux_2_17_x86_64", "native", "installed and run on Python 3.10 and 3.14; auditwheel: manylinux_2_17"),
         ("manylinux_2_17_aarch64", "aarch64-linux-gnu.2.17", "built; library is an ARM aarch64 ELF; not run"),
         ("macosx_11_0_arm64", "aarch64-macos", "built; library is an arm64 Mach-O; not run"),
         ("macosx_10_13_x86_64", "x86_64-macos", "built; library is an x86-64 Mach-O; not run"),
         ("win_amd64", "x86_64-windows", "built; not run")]
sizes = {l.split()[1]: int(l.split()[0]) for l in (ev / "wheels.txt").read_text().split("\n") if l.strip()}
rows = []
for tag, t, checked in order:
    name = f"diagrammari-0.0.1-py3-none-{tag}.whl"
    rows.append(f'<tr><td><code>{tag}</code></td><td class="num">{sizes[name]/1e6:.2f} MB</td>'
                f'<td class="num">{times[t]}</td><td>{checked}</td></tr>')

repl = {"{{stack}}": (ev / "stack.svg").read_text(), "{{stack_narrow}}": (ev / "stack_narrow.svg").read_text(),
        "{{wheel_rows}}": "\n".join(rows)}
for k, f in {"bench": "bench.txt", "versions": "versions.txt", "gil": "gil.txt", "mistake": "mistake.txt",
             "threads_before": "threads_before.txt", "threads_after": "threads_after.txt", "wheel_run": "wheel_run.txt"}.items():
    repl["{{%s}}" % k] = esc(ev / f)
for k, f in {"shim_c": "shim.c", "shim_nim": "shim.nim", "cabi_nim": "cabi.nim", "cabi_py": "cabi.py",
             "nimpy_nim": "nimpy.nim", "nimpy_py": "nimpy.py", "pyproject": "pyproject.toml", "native": "native.nim",
             "build_sh": "build.sh", "threadfix_c": "threadfix.c", "threadfix_nim": "threadfix.nim", "pathfix": "pathfix.nim"}.items():
    repl["{{%s}}" % k] = esc(ex / f)
for k, v in repl.items():
    assert k in page, k
    page = page.replace(k, v)
assert "{{" not in page
(here.parent / "index.html").write_text(page, encoding="utf-8")
print("wrote", here.parent / "index.html", len(page), "bytes")
