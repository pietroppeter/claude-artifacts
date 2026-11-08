#!/usr/bin/env python3
"""Make every code block on a page highlighted and scroll inside its own box.

Run it on a built page (after nimib / build.py, together with backlink.py):

    pip install pygments                 # only needed to highlight, not for --check
    python3 tools/codeblocks.py          # fix every <slug>/index.html
    python3 tools/codeblocks.py a.html   # fix the given pages (works outside this repo too)
    python3 tools/codeblocks.py --check  # exit 1 if a code block is left unhighlighted (CI)

What it does, all at build time (no CDN: claude.ai artifacts block it, and the CDN
highlight.js has no Nim grammar anyway):

- Every <pre><code> with no markup inside is highlighted with Pygments, emitting the same
  `hljs-*` classes nimib's highlightNim uses, so the page's highlight theme colours it.
  The language comes from a `language-X` / `lang-X` class, else from a file name in the
  first comment line (`# capi.nim: ...`), else from the content.
- Blocks that are output, not code, are left alone: `pre.nb-output`, `pre.out`, `pre.plain`,
  or a code class `language-text` / `language-plaintext`. Mark yours that way.
- A small style block (between marker comments, replaced on re-run) makes `pre` and
  `pre > code` scroll sideways inside their box, and adds a neutral light highlight theme
  if the page has none (no `.hljs-keyword` rule).
"""
import html, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
BEGIN, END = "<!-- claude-artifacts:codeblocks -->", "<!-- /claude-artifacts:codeblocks -->"
BLOCK = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?", re.S)

GUARD = "pre{overflow-x:auto}pre>code{overflow-x:auto}"
THEME = (
    ".hljs-comment,.hljs-quote{color:#7a7f87;font-style:italic}"
    ".hljs-keyword,.hljs-selector-tag,.hljs-meta .hljs-keyword{color:#a626a4}"
    ".hljs-string,.hljs-regexp,.hljs-addition{color:#50a14f}"
    ".hljs-number,.hljs-literal,.hljs-symbol{color:#b76b01}"
    ".hljs-built_in,.hljs-type,.hljs-class .hljs-title,.hljs-title.class_{color:#c18401}"
    ".hljs-title,.hljs-section{color:#4078f2}"
    ".hljs-meta,.hljs-attr,.hljs-attribute,.hljs-variable{color:#986801}"
    ".hljs-tag,.hljs-name{color:#e45649}.hljs-deletion{color:#e45649}"
)

PRE = re.compile(r"(<pre\b[^>]*>)(\s*)(<code\b[^>]*>)(.*?)(</code>\s*</pre>)", re.S | re.I)
SKIP_PRE = re.compile(r'class="[^"]*\b(nb-output|out|plain)\b', re.I)
SKIP_CODE = re.compile(r'class="[^"]*\blanguage-(text|plaintext|none|output)\b', re.I)
LANG_CLASS = re.compile(r'class="[^"]*\b(?:language|lang)-([\w+#-]+)', re.I)
EXT = {"nim": "nim", "nims": "nim", "nimble": "nim", "py": "python", "c": "c", "h": "c",
       "js": "javascript", "mjs": "javascript", "ts": "typescript", "toml": "toml",
       "sh": "bash", "json": "json", "swift": "swift", "yaml": "yaml", "yml": "yaml",
       "html": "html", "css": "css"}


def guess(text):
    lines = [l for l in text.splitlines() if l.strip()]
    if not lines:
        return None
    first = lines[0].strip()
    m = re.match(r"^(?:#|//|/\*|--)\s*(?:[\w./-]*/)?[\w.-]+\.(\w+)\b", first)
    if m and m.group(1).lower() in EXT:
        return EXT[m.group(1).lower()]
    if first.startswith("$ "):
        return "console"
    if first.startswith(">>> "):
        return "pycon"
    if re.match(r"^(GET|POST|PUT|DELETE|HTTP/\d)", first):
        return "http"
    if re.match(r"^\[[\w.-]+\]$", first):
        return "toml"
    if re.match(r'^\{\s*"', first):
        return "json"
    score = {"nim": 0, "python": 0, "javascript": 0, "c": 0, "swift": 0}
    for l in lines:
        s = l.strip()
        score["nim"] += 3 * bool(re.match(r"(proc|func|iterator|template|macro|method)\s+[`\w]", s))
        score["nim"] += 2 * bool(re.search(r"\{\.|import std/|\becho\b|\bdiscard\b|: (string|int|float|cstring|seq\[)", s))
        score["nim"] += bool(re.match(r"(let|var|const)\s+\w+.*[^;{]$", s))
        score["python"] += 3 * bool(re.match(r"(def|class)\s+\w+.*:$|from [\w.]+ import |@\w+", s))
        score["python"] += 2 * bool(re.match(r"import [\w.]+(\s*,\s*[\w.]+)*$|print\(|\{'", s))
        score["python"] += bool(re.search(r"\bNone\b|\bTrue\b|\bself\.", s))
        score["javascript"] += 3 * bool(re.search(r"=>|\bdocument\.|\bwindow\.|\bfunction\b", s))
        score["javascript"] += bool(re.search(r";$", s) and re.match(r"(const|let|var)\s", s))
        score["c"] += 3 * bool(re.match(r"#(include|pragma|define)|/\*", s))
        score["c"] += bool(re.match(r"(static\s+)?(int|void|char|JSValue|size_t)\b.*[;{)]$", s))
        score["swift"] += 3 * bool(re.match(r"import (SwiftUI|UIKit|Foundation)|struct \w+: \w+|@main", s))
    best = max(score, key=score.get)
    return best if score[best] > 0 else None


def hl_class(tok):
    from pygments import token as T
    table = [
        (T.Comment.Preproc, "meta"), (T.Comment, "comment"),
        (T.Keyword.Type, "type"), (T.Keyword.Constant, "literal"), (T.Keyword, "keyword"),
        (T.Operator.Word, "keyword"),
        (T.Name.Builtin.Pseudo, "literal"), (T.Name.Builtin, "built_in"),
        (T.Name.Function, "title function_"), (T.Name.Class, "title class_"),
        (T.Name.Decorator, "meta"), (T.Name.Tag, "tag"), (T.Name.Attribute, "attr"),
        (T.Name.Variable, "variable"), (T.Name.Constant, "literal"),
        (T.String.Escape, "char escape_"), (T.String, "string"), (T.Number, "number"),
        (T.Literal, "literal"), (T.Generic.Prompt, "meta"), (T.Generic.Heading, "section"),
        (T.Generic.Inserted, "addition"), (T.Generic.Deleted, "deletion"),
    ]
    for t, c in table:
        if tok in t:
            return c
    return None


def highlight(text, lang):
    from pygments.lexers import get_lexer_by_name
    from pygments.util import ClassNotFound
    try:
        lexer = get_lexer_by_name(lang, stripnl=False, ensurenl=False)
    except ClassNotFound:
        return None
    out = []
    for tok, val in lexer.get_tokens(text):
        c, v = hl_class(tok), html.escape(val, quote=False)
        out.append(f'<span class="hljs-{c}">{v}</span>' if c and val.strip() else v)
    return "".join(out)


def unhighlighted(text):
    """Yield (match, reason) for code blocks still lacking markup."""
    for m in PRE.finditer(text):
        pre, _, code, body, _ = m.groups()
        if SKIP_PRE.search(pre) or SKIP_CODE.search(code) or not body.strip():
            continue
        if "<" in body:  # already has markup (highlighted, or links/marks we must not touch)
            continue
        yield m


def fix(text):
    todo = {m.span() for m in unhighlighted(text)}

    def repl(m):
        if m.span() not in todo:
            return m.group(0)
        pre, ws, code, body, close = m.groups()
        src = html.unescape(body)
        lc = LANG_CLASS.search(code)
        lang = lc.group(1).lower() if lc else guess(src)
        if not lang:
            print(f"    left as text, mark it language-text: {src.strip().splitlines()[0][:60]!r}")
            return m.group(0)
        print(f"    {lang:<11} {src.strip().splitlines()[0][:55]!r}")
        out = highlight(src, lang)
        if out is None:
            print(f"    no lexer for {lang!r}")
            return m.group(0)
        if not lc:
            code = re.sub(r"^<code\b", f'<code data-lang="{lang}"', code, flags=re.I)
        return pre + ws + code + out + close

    text = BLOCK.sub("", PRE.sub(repl, text))
    style = GUARD + ("" if re.search(r"\.hljs-keyword\b", text) else THEME)
    snippet = f"{BEGIN}\n<style>{style}</style>\n{END}\n"
    i = text.lower().find("</head>")
    return text[:i] + snippet + text[i:] if i >= 0 else snippet + text


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    check = "--check" in sys.argv
    files = [pathlib.Path(a) for a in args] or sorted(ROOT.glob("*/index.html"))
    bad = 0
    for p in files:
        text = p.read_text(encoding="utf-8")
        if check:
            left = list(unhighlighted(text))
            if left or BEGIN not in text:
                bad += 1
                print(f"{p}: {len(left)} unhighlighted code block(s)"
                      + ("" if BEGIN in text else ", no codeblocks style"))
                for m in left[:3]:
                    print("    " + html.unescape(m.group(4)).strip().splitlines()[0][:70])
            continue
        print(p)
        new = fix(text)
        if new != text:
            p.write_text(new, encoding="utf-8")
    if check and bad:
        print("run: pip install pygments && python3 tools/codeblocks.py"
              " (or mark output blocks pre.out / pre.nb-output / code.language-text)")
        sys.exit(1)


if __name__ == "__main__":
    main()
