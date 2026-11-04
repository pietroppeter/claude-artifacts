const pageStyle* = """
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,700;9..144,900&family=IBM+Plex+Sans:wght@400;600&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>
:root{
  --paper:#f6f3ea; --card:#fffdf7; --ink:#1b2027; --muted:#5f6670; --line:#e0dccf;
  --nim:#ffe953; --sea:#2b6f8f; --land:#c9b98a; --pin:#d1495b; --ok:#3f8f5a; --code:#efeadb;
  --out-bg:#1b2027; --out-fg:#ecebe4; --hl:#ffe953;
}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){
  --paper:#14181d; --card:#1b2027; --ink:#e8e6df; --muted:#9aa3ad; --line:#2c333c;
  --sea:#79b8d6; --land:#8f8160; --pin:#ef7d8b; --ok:#7cc896; --code:#232a33; --out-bg:#0d1014; --out-fg:#e8e6df; --hl:#7a6a12; color-scheme:dark}}
:root[data-theme="dark"]{
  --paper:#14181d; --card:#1b2027; --ink:#e8e6df; --muted:#9aa3ad; --line:#2c333c;
  --sea:#79b8d6; --land:#8f8160; --pin:#ef7d8b; --ok:#7cc896; --code:#232a33; --out-bg:#0d1014; --out-fg:#e8e6df; --hl:#7a6a12; color-scheme:dark}
*{box-sizing:border-box}
[hidden]{display:none!important}
:root{padding:env(safe-area-inset-top,0) env(safe-area-inset-right,0) env(safe-area-inset-bottom,0) env(safe-area-inset-left,0)}
html{background:var(--paper)}
body{margin:0 auto;max-width:860px;padding:0 16px 60px;color:var(--ink);
  font:17px/1.6 "IBM Plex Sans",system-ui,sans-serif;background:var(--paper)}
header,footer .nb-box{display:flex;justify-content:space-between;align-items:center;gap:10px;font-size:13px;color:var(--muted);padding:14px 0}
header{border-bottom:1px solid var(--line)} footer .nb-box{border-top:1px solid var(--line);margin-top:40px}
header a, footer a{color:var(--muted)}
h1,h2,h3{font-family:Fraunces,Georgia,serif;line-height:1.12;letter-spacing:-.01em}
h1{font-size:clamp(36px,8vw,60px);font-weight:900;margin:34px 0 8px}
h1 em{font-style:normal;background:linear-gradient(transparent 62%,var(--hl) 62%);padding:0 .08em}
h2{font-size:28px;font-weight:700;margin:54px 0 10px;padding-top:18px;border-top:2px solid var(--ink)}
h2 .num{font-family:"JetBrains Mono",monospace;font-size:13px;color:var(--muted);display:block;margin-bottom:6px;letter-spacing:.08em}
h3{font-size:21px;margin:30px 0 6px}
a{color:var(--sea);text-decoration-thickness:1px;text-underline-offset:3px}
p code, li code, td code{font:14px "JetBrains Mono",monospace;background:var(--code);padding:1px 5px;border-radius:4px}
.lede{font-size:20px;font-family:Fraunces,Georgia,serif;font-weight:400}
blockquote{margin:18px 0;padding:6px 16px;border-left:4px solid var(--sea);background:var(--card)}
pre{margin:14px 0;overflow-x:auto;border-radius:10px}
pre code{display:block;padding:14px 16px;font:12.5px/1.55 "JetBrains Mono",monospace;font-variant-ligatures:none;background:var(--card);border:1px solid var(--line);border-radius:10px;color:var(--ink)}
pre.nb-output, pre samp{display:block;padding:12px 16px;font:12.5px/1.5 "JetBrains Mono",monospace;background:var(--out-bg);color:var(--out-fg);border-radius:10px;white-space:pre-wrap;overflow-wrap:anywhere;font-variant-ligatures:none}
.hljs-keyword{color:#a626a4;font-weight:600}.hljs-type,.hljs-built_in{color:#b76b01}.hljs-string{color:#3f8f5a}
.hljs-number,.hljs-literal{color:#986801}.hljs-comment{color:#8a8f96;font-style:italic}.hljs-meta{color:#4078f2}
details{margin:14px 0;border:1px dashed var(--line);border-radius:10px;padding:4px 12px;background:var(--card)}
details summary{cursor:pointer;font-family:"JetBrains Mono",monospace;font-size:13px;color:var(--muted);padding:6px 0}
.table-wrap{overflow-x:auto;margin:16px 0;border:1px solid var(--line);border-radius:10px;background:var(--card)}
table{border-collapse:collapse;width:100%;font-size:14.5px;line-height:1.45}
th,td{text-align:left;vertical-align:top;padding:8px 10px;border-bottom:1px solid var(--line)}
th{font:600 12px "JetBrains Mono",monospace;letter-spacing:.04em;text-transform:uppercase;color:var(--muted);background:var(--paper)}
tr:last-child td{border-bottom:none}
.verdict{background:var(--card);border:2px solid var(--ink);border-radius:14px;box-shadow:5px 5px 0 var(--ink);padding:6px 20px;margin:22px 0}
.verdict h3{margin-top:14px}
.flow{display:block;width:100%;height:auto;margin:16px 0}
.flow text{font-family:"IBM Plex Sans",sans-serif;fill:var(--ink)}
.flow .mono{font-family:"JetBrains Mono",monospace;font-size:12px}
.flow .box{fill:var(--card);stroke:var(--ink);stroke-width:1.5}
.flow .srv{fill:var(--nim);stroke:#1b2027;stroke-width:2}
.flow .srv-t{fill:#1b2027}
.flow .arrow{stroke:var(--ink);stroke-width:1.5;fill:none;marker-end:url(#ah)}
.flow .no{stroke:var(--pin);stroke-width:2;stroke-dasharray:5 4;fill:none}
.flow .no-t{fill:var(--pin);font-size:13px}
.flow .ah{fill:var(--ink)}
.flow .muted{fill:var(--muted)}
.tag{font:600 11px "JetBrains Mono",monospace;background:var(--nim);color:#1b2027;border:1.5px solid #1b2027;border-radius:4px;padding:0 5px}
#source{display:none}
footer button{font:600 12px "JetBrains Mono",monospace;border:1.5px solid var(--ink);background:var(--card);color:var(--ink);border-radius:999px;padding:4px 12px;cursor:pointer}
footer hr{display:none}
</style>
"""
