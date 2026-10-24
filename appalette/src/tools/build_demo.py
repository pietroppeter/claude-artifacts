"""Builds the demo page into demo/site/ (not committed):
    python tools/build_demo.py
Compiles demo/demo.nim to JS (nim on PATH, deps from deps.sh), then inlines
the script and the example images (images/*.jpg, from
tools/prepare_images.py) into demo/page.html:
  - demo/site/index.html: a complete page (e.g. for GitHub Pages);
  - demo/site/fragment.html: the same without doctype/head/body, for hosts
    that add their own (a claude.ai artifact).
Standard library only.
"""
import base64
import html
import json
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
site = root / "demo" / "site"
site.mkdir(parents=True, exist_ok=True)
js = site / "demo.js"
subprocess.run(["nim", "js", "-d:danger", "--hints:off", f"-o:{js}",
                str(root / "demo" / "demo.nim")], check=True, cwd=root)

examples = []
credits = []
for src in json.loads((root / "images" / "sources.json").read_text()):
    data = base64.b64encode((root / "images" / f"{src['name']}.jpg").read_bytes()).decode()
    examples.append({"name": src["name"], "title": src["title"], "author": src["author"],
                     "license": src["license"], "keep": src.get("keep", ""), "src": f"data:image/jpeg;base64,{data}"})
    via = src["via"]
    via_html = (f'<a href="{html.escape(via)}">{html.escape(via.split("/blob/")[0].replace("https://github.com/", ""))}</a>'
                if via.startswith("http") else html.escape(via))
    credits.append(f"<i>{html.escape(src['title'])}</i>, {html.escape(src['author'])} ({html.escape(src['license'])}, via {via_html})")

page = (root / "demo" / "page.html").read_text()
page = page.replace('<footer id="sources"></footer>',
                    '<footer id="sources">Example images: ' + "; ".join(credits) + ".</footer>")
page = page.replace("<!--EXAMPLES-->",
                    "<script>window.EXAMPLES = " + json.dumps(examples) + ";</script>")
page = page.replace("<!--SCRIPT-->", "<script>\n" + js.read_text() + "\n</script>")
(site / "fragment.html").write_text(page)
(site / "index.html").write_text(
    '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
    '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
    + page.replace("<style>", "<style>\nimg { max-width: 100%; }\n[hidden] { display: none !important; }\n", 1)
    .replace('<div class="wrap">', '</head>\n<body>\n<div class="wrap">', 1)
    + "\n</body>\n</html>\n")
print(f"wrote {site / 'index.html'} ({(site / 'index.html').stat().st_size // 1024} KB)", file=sys.stderr)
