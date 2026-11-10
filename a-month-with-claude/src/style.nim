## The page's look: a theatre programme (*programma di sala*). Ivory paper, ink, the red of the
## curtain and a little gold; one serif from the system for everything, small capitals for the
## labels. No remote fonts, nothing loaded.

const
  rosso* = "#8E1B24"     # the curtain red
  velluto* = "#F1E3DA"   # the velvet of the seats
  ## the two ends of `dataColor`'s palette: it mixes colours in Nim, so it needs them as values

const pageStyle* = """
<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2280%22>🎭</text></svg>">
<style>
:root {
  --carta: #F7F2E8; --inchiostro: #221C1A; --rosso: """ & rosso & """; --oro: #A9843A;
  --grigio: #6E625A; --filetto: #D9CDB8; --velluto: """ & velluto & """;
  --serif: "Iowan Old Style", "Palatino Linotype", Palatino, "Book Antiqua", Georgia, serif;
  --mono: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
  /* the names the review mode (shared/review) reads, from the programme's own */
  --paper: var(--carta); --ink: var(--inchiostro); --line: var(--filetto); --shade: var(--velluto);
  --surface: #FFFDF8; --muted: var(--grigio); --primary-text: var(--rosso); --font: var(--serif);
  padding: env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left);
}
html { -webkit-text-size-adjust: 100%; }
body { margin: 0; background: var(--carta); color: var(--inchiostro); font: 18px/1.6 var(--serif); }
[hidden] { display: none !important; }
main { max-width: 46rem; margin: 0 auto; padding: 0 1.1rem 4rem; }
a { color: var(--rosso); text-decoration-thickness: 1px; text-underline-offset: 2px; }
header.sala { max-width: 46rem; margin: 0 auto; padding: 1rem 1.1rem 0; display: flex; justify-content: space-between;
  font: .72rem/1 var(--serif); letter-spacing: .18em; text-transform: uppercase; color: var(--grigio); }
header.sala a { color: var(--grigio); text-decoration: none; }

/* the cover */
.copertina { text-align: center; border-top: 3px double var(--inchiostro); border-bottom: 3px double var(--inchiostro);
  margin: 1.4rem 0 2rem; padding: 1.6rem 0 1.4rem; }
.copertina .sopra { font-size: .78rem; letter-spacing: .3em; text-transform: uppercase; color: var(--rosso); margin: 0; }
.copertina h1 { font-weight: 400; font-size: 2.6rem; line-height: 1.08; margin: .5rem 0 .4rem; letter-spacing: -.01em; }
.copertina h1 em { color: var(--rosso); }
.copertina .lede { font-size: 1.15rem; font-style: italic; color: var(--grigio); margin: .6rem auto 0; max-width: 34rem; }
.copertina .data { font-size: .78rem; letter-spacing: .2em; text-transform: uppercase; color: var(--grigio); margin-top: 1rem; }

/* the playbill: the three parts */
.programma { list-style: none; padding: 0; margin: 0 0 2.4rem; border: 1px solid var(--filetto); background: #FFFDF8; }
.programma li { display: grid; grid-template-columns: 6.6rem 1fr; gap: .8rem; padding: .8rem 1rem; border-top: 1px solid var(--filetto); }
.programma li:first-child { border-top: 0; }
.programma .atto { font-size: .72rem; letter-spacing: .18em; text-transform: uppercase; color: var(--rosso); padding-top: .3rem; }
.programma a { font-size: 1.15rem; color: var(--inchiostro); text-decoration: none; border-bottom: 1px solid var(--rosso); }
.programma p { margin: .2rem 0 0; font-size: .92rem; color: var(--grigio); line-height: 1.45; }
@media (max-width: 520px) { .programma li { grid-template-columns: 1fr; gap: .1rem; } }

/* part headings: a curtain-red label over a big title */
h2.parte { text-align: center; font-weight: 400; font-size: 2rem; line-height: 1.15; margin: 4rem 0 1.6rem;
  padding-top: 1.6rem; border-top: 1px solid var(--inchiostro); scroll-margin-top: 1rem; }
h2.parte small { display: block; font-size: .78rem; letter-spacing: .3em; text-transform: uppercase; color: var(--rosso); margin-bottom: .5rem; }
h2.parte + .lede { text-align: center; font-style: italic; color: var(--grigio); margin: -.8rem auto 1.8rem; max-width: 34rem; }
h3 { font-weight: 400; font-size: 1.45rem; margin: 2.4rem 0 .6rem; }
h3::before { content: "❦ "; color: var(--oro); font-size: .9em; }
blockquote { margin: 1.2rem 0; padding: .2rem 1.2rem; border-left: 3px solid var(--oro); font-style: italic; }

/* code: small, on a slightly warmer sheet */
body pre > code { display: block; font: 12.5px/1.5 var(--mono); background: #FFFDF8; border: 1px solid var(--filetto);
  padding: .8rem .9rem; overflow-x: auto; }
:not(pre) > code { font: .84em var(--mono); background: var(--velluto); padding: .05em .3em; }
pre { margin: 1rem 0; }
.hljs-keyword { color: var(--rosso); } .hljs-string { color: #2F5D50; } .hljs-comment { color: var(--grigio); font-style: italic; }

/* tabs: 👑 Nim, 🐍 Python, 🏴‍☠️ R */
.lingue { margin: 1.2rem 0; }
.lingue-tab { display: flex; flex-wrap: wrap; }
.lingue-tab button { font: .78rem var(--serif); letter-spacing: .12em; text-transform: uppercase; color: var(--inchiostro);
  background: transparent; border: 1px solid var(--inchiostro); padding: .3rem .8rem; cursor: pointer; margin-right: -1px; }
.lingue-tab button[aria-selected="true"] { background: var(--inchiostro); color: var(--carta); }
.lingue-pannello { border-top: 1px solid var(--inchiostro); }

/* tabelline's tables in the programme's look */
.tabella { margin: 1.4rem 0; }
.tabella .tb_table { font-family: var(--serif) !important; background: #FFFDF8 !important; color: var(--inchiostro) !important;
  border-top: 2px solid var(--inchiostro) !important; border-bottom: 2px solid var(--inchiostro) !important; }
.tabella .tb_title { font-weight: 400 !important; font-size: 1.25rem !important; }
.tabella .tb_subtitle { font-style: italic; color: var(--grigio) !important; }
.tabella .tb_heading_last { border-bottom: 1px solid var(--rosso) !important; }
.tabella .tb_col_heading { color: var(--grigio) !important; font-size: .85rem !important; letter-spacing: .04em; }
.tabella .tb_row { border-top-color: var(--filetto) !important; }
.tabella .tb_stub { border-right-color: var(--filetto) !important; }
.tabella .tb_group_heading { background: var(--velluto) !important; color: var(--rosso) !important; font-size: .8rem !important;
  letter-spacing: .12em; text-transform: uppercase; border-color: var(--inchiostro) !important; }
.tabella .tb_footnote, .tabella .tb_sourcenote { color: var(--grigio) !important; font-size: .8rem !important; }

footer.sala { max-width: 46rem; margin: 0 auto; padding: 1.4rem 1.1rem 3rem; border-top: 3px double var(--inchiostro);
  font-size: .85rem; color: var(--grigio); text-align: center; }
</style>"""

const tabsScript* = """<script>
(function () {
  function pick(lang) {
    document.querySelectorAll('.lingue').forEach(function (box) {
      box.querySelectorAll('.lingue-tab button').forEach(function (b) { b.setAttribute('aria-selected', b.dataset.lingua === lang ? 'true' : 'false'); });
      box.querySelectorAll('.lingue-pannello').forEach(function (p) { p.hidden = p.dataset.lingua !== lang; });
    });
  }
  document.querySelectorAll('.lingue-tab button').forEach(function (b) {
    b.addEventListener('click', function () { pick(b.dataset.lingua); });
  });
})();
</script>"""
