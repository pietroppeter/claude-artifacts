const pageStyle* = """
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,700;9..144,900&family=IBM+Plex+Sans:wght@400;600&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>
:root{
  --paper:#fbf7ee; --card:#fffdf8; --ink:#1d1b16; --muted:#6b6457; --line:#e6dfcf;
  --nim:#ffe953; --gold:#f3c623; --teal:#1f7a8c; --coral:#e4572e; --plum:#7b4b94; --leaf:#4e9a4e;
}
*{box-sizing:border-box}
[hidden]{display:none!important}
:root{padding:env(safe-area-inset-top,0) env(safe-area-inset-right,0) env(safe-area-inset-bottom,0) env(safe-area-inset-left,0)}
html{background:var(--paper)}
body{margin:0 auto;max-width:760px;padding:0 18px 60px;color:var(--ink);
  font:17px/1.6 "IBM Plex Sans",system-ui,sans-serif;background:var(--paper)}
header,footer .nb-box{display:flex;justify-content:space-between;align-items:center;font-size:13px;color:var(--muted);padding:14px 0}
header{border-bottom:1px solid var(--line)} footer .nb-box{border-top:1px solid var(--line);margin-top:40px}
header a, footer a{color:var(--muted)}
#nimib-head-title, header > div:nth-child(2){font-family:"JetBrains Mono",monospace}
h1,h2,h3{font-family:Fraunces,Georgia,serif;line-height:1.1;letter-spacing:-.01em}
h1{font-size:clamp(38px,8vw,64px);font-weight:900;margin:36px 0 6px}
h1 em{font-style:normal;background:linear-gradient(transparent 58%,var(--nim) 58%);padding:0 .08em}
h2{font-size:30px;font-weight:700;margin:52px 0 10px;padding-top:18px;border-top:2px solid var(--ink)}
h2 .num{font-family:"JetBrains Mono",monospace;font-size:14px;color:var(--muted);display:block;margin-bottom:6px;letter-spacing:.08em}
a{color:var(--teal);text-decoration-thickness:1px;text-underline-offset:3px}
p code, li code{font:14.5px "JetBrains Mono",monospace;background:#f1ead7;padding:1px 5px;border-radius:4px}
.lede{font-size:20px;color:#3b372f;font-family:Fraunces,Georgia,serif;font-weight:400}
blockquote{margin:18px 0;padding:6px 16px;border-left:4px solid var(--nim);background:var(--card);color:#3b372f}
pre{margin:14px 0;overflow-x:auto;border-radius:10px}
pre code{display:block;padding:14px 16px;font:13.2px/1.55 "JetBrains Mono",monospace;background:#fffdf8;border:1px solid var(--line);border-radius:10px;color:#2b2a26}
pre.nb-output, pre samp{display:block;padding:12px 16px;font:13px/1.5 "JetBrains Mono",monospace;background:#1d1b16;color:#f3eedf;border-radius:10px;white-space:pre}
.hljs-keyword{color:#a626a4;font-weight:600}.hljs-type,.hljs-built_in{color:#b76b01}.hljs-string{color:#50a14f}
.hljs-number,.hljs-literal{color:#986801}.hljs-comment{color:#9a9483;font-style:italic}.hljs-meta{color:#4078f2}
details{margin:14px 0;border:1px dashed #cfc5ad;border-radius:10px;padding:4px 12px;background:#fffdf8}
details summary{cursor:pointer;font-family:"JetBrains Mono",monospace;font-size:13px;color:var(--muted);padding:6px 0}
/* stages */
.stage{position:relative;margin:18px 0 6px;background:var(--card);border:2px solid var(--ink);border-radius:16px;
  box-shadow:5px 5px 0 var(--ink);padding:6px}
.stage svg.d2{display:block;overflow:visible;width:100%;height:auto;touch-action:none;user-select:none;-webkit-user-select:none}
.stage svg text{font-family:"IBM Plex Sans",sans-serif}
.stage svg .mono{font-family:"JetBrains Mono",monospace}
.item{transition:transform .32s cubic-bezier(.2,.9,.25,1)}
.item.grab{cursor:grab}
.item.lifted{transition:none;cursor:grabbing;filter:drop-shadow(0 9px 8px rgba(29,27,22,.28))}
.ghosts{pointer-events:none}
.ghosts .land{fill:var(--coral);opacity:.55}
.ghosts .best{fill:none;stroke:var(--coral);stroke-width:3}
.ghosts .tether{stroke:var(--coral);stroke-width:2;stroke-dasharray:4 4}
.ghosts .path{fill:var(--coral);opacity:.35}
.ghost-toggle{position:absolute;right:12px;bottom:8px;font:12px "JetBrains Mono",monospace;color:var(--muted);cursor:pointer;user-select:none}
.ghost-toggle input{accent-color:var(--coral);vertical-align:-2px}
.controls{display:flex;flex-wrap:wrap;gap:8px;margin:14px 0}
.controls button,.btn{font:600 13px "JetBrains Mono",monospace;border:2px solid var(--ink);background:var(--card);color:var(--ink);
  border-radius:999px;padding:6px 14px;cursor:pointer;box-shadow:2px 2px 0 var(--ink)}
.controls button.on{background:var(--nim)}
.controls button:active,.btn:active{transform:translate(2px,2px);box-shadow:none}
/* hero */
.hero-wrap{display:grid;grid-template-columns:1.25fr 1fr;gap:16px;align-items:start}
@media (max-width:640px){.hero-wrap{grid-template-columns:1fr}}
.caption{min-height:78px;margin:10px 2px 0;font-size:15px;line-height:1.45}
.caption b{font-family:"JetBrains Mono",monospace;font-size:12px;letter-spacing:.06em;display:inline-block;background:var(--ink);color:var(--nim);
  padding:1px 7px;border-radius:4px;margin-right:6px}
.panel{background:var(--ink);color:#f3eedf;border-radius:14px;padding:12px 14px;font:13px/1.35 "JetBrains Mono",monospace;margin-top:18px}
.panel .hd{color:#a39c8a;font-size:11px;letter-spacing:.08em;margin-bottom:8px;text-transform:uppercase}
.panel .row{display:grid;grid-template-columns:auto 1fr 44px;gap:8px;align-items:center;padding:3px 4px;border-radius:6px}
.panel .row.best{background:#3a362c;outline:1px solid var(--nim)}
.panel .w span{display:inline-block;width:1.15em;text-align:center}
.panel .w span.k{background:var(--nim);color:var(--ink);border-radius:3px}
.panel .bar{height:6px;background:var(--coral);border-radius:3px;min-width:2px}
.panel .d{text-align:right;color:#cfc8b5}
.panel .idle{color:#a39c8a}
.filmstrip{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin:14px 0}
.filmstrip figure{margin:0;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:6px;text-align:center}
.filmstrip figure.best{border:2px solid var(--coral)}
.filmstrip svg{width:100%;height:auto;display:block}
.filmstrip figcaption{font:12px "JetBrains Mono",monospace;color:var(--muted)}
.refs li{margin:6px 0}
.tag{font:600 11px "JetBrains Mono",monospace;background:var(--nim);border:1.5px solid var(--ink);border-radius:4px;padding:0 5px;margin-left:4px}
#source{display:none}
footer button{font:600 12px "JetBrains Mono",monospace;border:1.5px solid var(--ink);background:var(--card);border-radius:999px;padding:4px 12px;cursor:pointer}
footer hr{display:none}
</style>
"""
