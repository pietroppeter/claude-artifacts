---
name: nimib-blocks
description: Use when writing or changing a nimib page and about to put HTML, CSS or a colour in it, so repeated HTML becomes a custom block and every style and colour lives in a style module.
metadata:
  status: draft
---

# nimib: blocks, not HTML

nimib exists so that a page says *what* it shows, with blocks made for it, and not *how* it is
drawn. An agent reaches for HTML because it knows HTML better than nimib's block API, and a
project drifts: `<div>` in `nbText`, `nbRawHtml` everywhere, a `<style>` and hex colours in every
page. This skill keeps the default the other way.

## The decision, in order

Before you write a tag, a `style=` or a colour in a page:

1. **Is it Markdown?** Headings, lists, links, emphasis, tables of text, code fences: write them
   in `nbText` as Markdown.
2. **Is there a nimib block?** `nbText`, `nbCode`, `nbCodeSkip`, `nbImage`, `nbFile`, `nbCapture`,
   `nbJsFromCode`, `nbShow`, … (and the project's table or plot blocks, such as `nbTable`).
3. **Is there one in the project's blocks module?** Look for it (often `blocks.nim`; search for `newNbBlock`). Use it.
4. **Will it be needed again?** Then make a block now, the second time it is needed, not the
   third: see [references/making-blocks.md](references/making-blocks.md).
5. **Only then `nbRawHtml`**, for a true one-off, with a comment that says why it is not a block.
   The common legitimate case: the empty elements an `nbJsFromCode` widget fills in (a `<canvas>`,
   a `<div id="out">`), when the widget is used once.

## Where things live

- **The style module** (`style.nim`): every styling decision. Colours as
  named tokens (constants or CSS variables such as `--primary`, `--warning`), the CSS of the
  theme generated from them, the fonts. No CSS and no colour anywhere else.
- **The blocks module** (`blocks.nim`): every custom block, each with a doc
  comment. Its `toHtml` writes classes, never inline styles; the classes are styled in the style
  module.
- **Pages**: Markdown, nimib's blocks and the project's blocks. Data a page shows goes in data
  modules, apart from how it is shown.

A block that needs a new look gets a class and its CSS goes in the style module, using tokens.
A page that needs a new colour needs a new token, not a hex value.

## Kinds, not strings

When a block comes in kinds (a note that is info, done or a warning), make the kind an `enum`,
not a string: a typo then fails to compile, and the CSS class is derived from it in one place.

```nim
type NoteKind* = enum nkPlain = "", nkInfo = "info", nkWarning = "warning"
# a field `level: NoteKind`; in toHtml: &"""<div class="note {blk.level}">"""  ($ of the enum is the class)
```

## Check your own drift

Run the drift counter on the pages you touched, allowing the style and blocks modules:

```sh
# from the project's root
nim r <this skill's folder>/scripts/drift.nim --allow:docs/style.nim --allow:docs/blocks.nim docs/
```

It lists, per file, `nbRawHtml` calls, `nbText` blocks holding HTML tags, `<style>`, `<script>`,
inline `style="` and distinct `#RRGGBB` colours. The number outside the allowed files must not
go up in your change. `--fail` makes it exit with 1 on any drift, for CI once a project is
migrated.

## Before you finish

- No new HTML tag in `nbText`, no new `nbRawHtml` without a comment, no `<style>`, no hex colour
  in a page.
- Every new block is in the blocks module, documented, and used at least once.
- Its CSS is in the style module and uses tokens; check it in every look the project has (light
  and dark, or the project's themes).
- Build the page and look at it (a phone-width screenshot if the project has a rule for it).
