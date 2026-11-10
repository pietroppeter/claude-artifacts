#!/usr/bin/env python3
"""Add (or refresh) the small "← Claude artifacts" link on every page.

The snippet also sets text-size-adjust on <html>, so iOS Safari does not inflate the text
in code blocks that scroll sideways (every page gets it, whoever built it).

Inserts a self-contained snippet before </body> in each <slug>/index.html,
between marker comments, so re-running replaces it instead of duplicating it.

    python3 tools/backlink.py          # add/refresh on every page
    python3 tools/backlink.py --check  # exit 1 if a page lacks the current snippet (CI)
"""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
INDEX_URL = "https://pietroppeter.github.io/claude-artifacts/"
BEGIN, END = "<!-- claude-artifacts:backlink -->", "<!-- /claude-artifacts:backlink -->"

SNIPPET = f"""{BEGIN}
<style>
html{{-webkit-text-size-adjust:100%;text-size-adjust:100%}}
#ca-backlink{{all:initial;position:fixed;z-index:2147483647;left:max(10px,env(safe-area-inset-left,0px));bottom:max(10px,env(safe-area-inset-bottom,0px));
font:500 12px/1 system-ui,-apple-system,"Segoe UI",sans-serif;color:#1f1a22;background:rgba(251,250,252,.96);
border:1px solid rgba(0,0,0,.14);border-radius:999px;padding:6px 10px;text-decoration:none;box-shadow:0 1px 3px rgba(0,0,0,.12);
-webkit-backdrop-filter:blur(4px);backdrop-filter:blur(4px);cursor:pointer}}
#ca-backlink:hover,#ca-backlink:focus-visible{{text-decoration:underline}}
@media (prefers-color-scheme:dark){{#ca-backlink{{color:#ece6ef;background:rgba(23,19,26,.94);border-color:rgba(255,255,255,.18)}}}}
@media print{{#ca-backlink{{display:none}}}}
body.rv-on #ca-backlink{{display:none}}
</style>
<a id="ca-backlink" href="{INDEX_URL}" title="All Claude artifacts">&larr; Claude artifacts</a>
{END}"""

BLOCK = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?", re.S)


def pages():
    return sorted(p for p in ROOT.glob("*/index.html"))


def apply(text):
    text = BLOCK.sub("", text)
    i = text.lower().rfind("</body>")
    if i < 0:
        raise ValueError("no </body>")
    return text[:i] + SNIPPET + "\n" + text[i:]


def main():
    check = "--check" in sys.argv
    bad = []
    for p in pages():
        text = p.read_text(encoding="utf-8")
        new = apply(text)
        if new != text:
            bad.append(p.relative_to(ROOT))
            if not check:
                p.write_text(new, encoding="utf-8")
    if check and bad:
        print("missing or stale back-link (run python3 tools/backlink.py):")
        print("\n".join(f"  {b}" for b in bad))
        sys.exit(1)
    print(("ok" if check else f"updated {len(bad)} page(s)"))


if __name__ == "__main__":
    main()
