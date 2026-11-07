"""Builds ../index.html from template.html and the evidence files (real outputs, 7 Nov 2026).

    python3 diagrammari-python/src/build.py
"""
import html
from pathlib import Path

here = Path(__file__).parent
ev = here / "evidence"
page = (here / "template.html").read_text(encoding="utf-8")


def text(name):
    return html.escape((ev / name).read_text(encoding="utf-8").rstrip())


def code(name):
    return html.escape(Path(name).read_text(encoding="utf-8").rstrip())


repl = {
    "{{build}}": text("build_qjs.txt"),
    "{{wheel}}": text("wheel.txt"),
    "{{add}}": text("add.txt"),
    "{{run}}": text("run.txt"),
    "{{qjs}}": text("qjs.txt"),
    "{{demo_py}}": text("demo.py"),
    "{{add_qjs}}": text("add_qjs.txt"),
    "{{run_qjs}}": text("run_qjs.txt"),
    "{{qjs_nim}}": text("qjs_nim.txt"),
    "{{pipeline}}": (ev / "pipeline.svg").read_text(encoding="utf-8"),
    "{{pipeline_narrow}}": (ev / "pipeline_narrow.svg").read_text(encoding="utf-8"),
    "{{plain}}": (ev / "plain.svg").read_text(encoding="utf-8").replace('"mari-', '"plain-'),
    "{{personal}}": (ev / "personal.svg").read_text(encoding="utf-8"),
}
for k, v in repl.items():
    assert k in page, k
    page = page.replace(k, v)
(here.parent / "index.html").write_text(page, encoding="utf-8")
print("wrote", here.parent / "index.html", len(page), "bytes")
