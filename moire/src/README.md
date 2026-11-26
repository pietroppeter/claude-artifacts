# moire page sources

The moiré effect with things to drag, in a [nimib](https://github.com/pietroppeter/nimib) page.
Inspired by a [notebook about the Mer de Glace](https://notebook.link/@arjxn-py/mer-de-glace-story).

- `index.nim`: the page, writes `../index.html`. Build: `sh deps.sh && nim r index.nim` (Nim 2.2, `libpcre3`).
- `lib/moiremath.nim`: the formulas (fringe periods, the lever, a grating, the toy glacier flow), used both by
  the code blocks at build time and by the widgets in the browser.
- `lib/widgets.nim`: the seven canvases, Nim compiled with `nim js` while the page is built and inlined
  (`compileWidgets` in `lib/blocks.nim`).
- `lib/blocks.nim` (widget, note, formula blocks), `lib/style.nim` (every colour and rule; the canvases read
  their colours from its CSS variables).
- The review mode is tabelline's, from `shared/review/` at the root of the repository (`config.nims`).
