## Page style: an old survey atlas. Parchment, sepia ink, sea blue, contour lines, a neatline round each sheet.
const contours = "data:image/svg+xml;utf8," &
  "<svg xmlns='http://www.w3.org/2000/svg' width='600' height='260' viewBox='0 0 600 260'>" &
  "<g fill='none' stroke='%23a0784a' stroke-opacity='.22' stroke-width='1'>" &
  "<path d='M-20 200 C 80 150, 160 230, 260 180 S 420 120, 620 170'/>" &
  "<path d='M-20 170 C 90 120, 170 200, 270 150 S 430 90, 620 140'/>" &
  "<path d='M-20 140 C 100 90, 180 170, 280 120 S 440 60, 620 110'/>" &
  "<path d='M-20 110 C 110 60, 190 140, 290 90 S 450 30, 620 80'/>" &
  "<path d='M140 60 C 180 20, 260 30, 280 60 S 220 110, 170 95 S 120 80, 140 60 Z'/>" &
  "<path d='M170 62 C 195 40, 245 45, 255 62 S 215 90, 185 82 S 160 72, 170 62 Z'/>" &
  "<path d='M430 220 C 470 190, 540 200, 550 225 S 500 260, 460 250 S 410 240, 430 220 Z'/>" &
  "</g></svg>"

const pageStyle* = """
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,600;0,700;1,600&family=Source+Serif+4:opsz,wght@8..60,400;8..60,600&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>
:root{
  --paper:#f3ecdc; --sheet:#faf5e9; --ink:#2a2118; --muted:#6e6150; --line:#d9cdb4; --rule:#2a2118;
  --sea:#2f6f8f; --contour:#a0784a; --pin:#b8432f; --land:#6b8f5a; --code:#ece3cf;
  --out-bg:#1e2a33; --out-fg:#e9e2d0; --hl:#e8c872;
}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){
  --paper:#0f1a22; --sheet:#14222c; --ink:#e9e2d0; --muted:#a3a08f; --line:#2b3b47; --rule:#c9b98e;
  --sea:#7fb6d1; --contour:#c9a46e; --pin:#e2826f; --land:#9cbf86; --code:#1c2c38;
  --out-bg:#0a1218; --out-fg:#e9e2d0; --hl:#6e5a2a; color-scheme:dark}}
:root[data-theme="dark"]{
  --paper:#0f1a22; --sheet:#14222c; --ink:#e9e2d0; --muted:#a3a08f; --line:#2b3b47; --rule:#c9b98e;
  --sea:#7fb6d1; --contour:#c9a46e; --pin:#e2826f; --land:#9cbf86; --code:#1c2c38;
  --out-bg:#0a1218; --out-fg:#e9e2d0; --hl:#6e5a2a; color-scheme:dark}
*{box-sizing:border-box}
[hidden]{display:none!important}
html{background:var(--paper);-webkit-text-size-adjust:100%;text-size-adjust:100%}
:root{padding:env(safe-area-inset-top,0) env(safe-area-inset-right,0) env(safe-area-inset-bottom,0) env(safe-area-inset-left,0)}
body{margin:0 auto;max-width:860px;padding:0 16px 60px;color:var(--ink);background:var(--paper);
  font:17px/1.62 "Source Serif 4",Georgia,serif}
header,footer .nb-box{display:flex;justify-content:space-between;align-items:center;gap:10px;
  font:12px "JetBrains Mono",monospace;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);padding:14px 0}
header{border-bottom:3px double var(--rule)} footer .nb-box{border-top:3px double var(--rule);margin-top:40px}
header a, footer a{color:var(--muted)}
h1,h2,h3{font-family:"Cormorant Garamond",Georgia,serif;line-height:1.08;letter-spacing:.005em}
.hero{position:relative;margin:0 -16px;padding:30px 16px 8px;
  background:url("""" & contours & """") center/cover no-repeat}
.hero-top{display:flex;gap:18px;align-items:center;justify-content:space-between}
.compass{flex:none;width:clamp(70px,16vw,120px);height:auto;color:var(--ink)}
.compass .n{fill:var(--pin)} .compass .s{fill:var(--ink)} .compass circle{fill:none;stroke:var(--ink)}
.compass text{font:600 13px "Cormorant Garamond",serif;fill:var(--ink)}
h1{font-size:clamp(40px,9vw,68px);font-weight:700;margin:0 0 6px}
h1 em{font-style:italic;font-weight:600;color:var(--sea)}
.kicker{font:12px "JetBrains Mono",monospace;letter-spacing:.14em;text-transform:uppercase;color:var(--contour);margin:0 0 6px}
h2{font-size:32px;font-weight:700;margin:56px 0 10px;padding-top:16px;border-top:3px double var(--rule)}
h2 .num{font:500 12px "JetBrains Mono",monospace;color:var(--contour);display:block;margin-bottom:6px;letter-spacing:.14em;text-transform:uppercase}
h3{font-size:24px;margin:30px 0 6px}
a{color:var(--sea);text-decoration-thickness:1px;text-underline-offset:3px}
p code, li code, td code{font:13px "JetBrains Mono",monospace;background:var(--code);padding:1px 5px;border-radius:3px}
.lede{font-size:20px;line-height:1.5;font-style:italic}
blockquote{margin:18px 0;padding:6px 16px;border-left:3px solid var(--contour);background:var(--sheet)}
pre{margin:14px 0;overflow-x:auto;border-radius:4px}
body pre > code{display:block;padding:14px 16px;font:12.5px/1.55 "JetBrains Mono",monospace;font-variant-ligatures:none;
  background:var(--sheet);border:1px solid var(--line);border-radius:4px;color:var(--ink)}
pre.nb-output, pre samp{display:block;padding:12px 16px;font:12px/1.5 "JetBrains Mono",monospace;font-variant-ligatures:none;
  background:var(--out-bg);color:var(--out-fg);border-radius:4px;white-space:pre-wrap;overflow-wrap:anywhere}
@media (max-width:520px){body pre > code{font-size:11.5px} pre.nb-output, pre samp{font-size:11px} p code, li code, td code{font-size:12px}}
.hljs-keyword{color:#8a3b6b;font-weight:600}.hljs-type,.hljs-built_in{color:#8a5a12}.hljs-string{color:#4f7a3e}
.hljs-number,.hljs-literal{color:#9a5a1e}.hljs-comment{color:#8f8571;font-style:italic}.hljs-meta{color:#2f6f8f}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]) .hljs-keyword{color:#e09ac4} :root:not([data-theme="light"]) .hljs-type{color:#e0b36a}
  :root:not([data-theme="light"]) .hljs-string{color:#a9d08e} :root:not([data-theme="light"]) .hljs-number{color:#e0a56a}}
details{margin:14px 0;border:1px dashed var(--line);border-radius:4px;padding:4px 12px;background:var(--sheet)}
details summary{cursor:pointer;font-family:"JetBrains Mono",monospace;font-size:12px;color:var(--muted);padding:6px 0}
.table-wrap{overflow-x:auto;margin:16px 0;border:1.5px solid var(--rule);outline:1px solid var(--rule);outline-offset:3px;background:var(--sheet)}
table{border-collapse:collapse;width:100%;font-size:14.5px;line-height:1.45}
th,td{text-align:left;vertical-align:top;padding:8px 10px;border-bottom:1px solid var(--line)}
th{font:600 11px "JetBrains Mono",monospace;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);background:var(--paper)}
tr:last-child td{border-bottom:none}
td[colspan]{font-family:"Cormorant Garamond",serif;font-size:18px;background:var(--paper)}
.verdict{background:var(--sheet);border:1.5px solid var(--rule);outline:1px solid var(--rule);outline-offset:4px;padding:6px 20px;margin:26px 4px}
.verdict h3{margin-top:14px;font-size:22px;letter-spacing:.12em;text-transform:uppercase;font-size:16px;font-family:"JetBrains Mono",monospace;color:var(--contour)}
.flow{display:block;width:100%;height:auto;margin:16px 0}
.flow text{font-family:"Source Serif 4",serif;fill:var(--ink)}
.flow .mono{font-family:"JetBrains Mono",monospace;font-size:12px}
.flow .box{fill:var(--sheet);stroke:var(--ink);stroke-width:1.2}
.flow .srv{fill:var(--hl);stroke:var(--ink);stroke-width:1.8}
.flow .srv-t{fill:var(--ink)}
.flow .arrow{stroke:var(--ink);stroke-width:1.3;fill:none;marker-end:url(#ah)}
.flow .ah{fill:var(--ink)}
.flow .no{stroke:var(--pin);stroke-width:1.8;stroke-dasharray:5 4;fill:none}
.flow .no-t{fill:var(--pin);font-size:13px}
.flow .muted{fill:var(--muted)}
#source{display:none}
footer button{font:600 12px "JetBrains Mono",monospace;border:1.5px solid var(--ink);background:var(--sheet);color:var(--ink);border-radius:2px;padding:4px 12px;cursor:pointer}
footer hr{display:none}
</style>
"""
