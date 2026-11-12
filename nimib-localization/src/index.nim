## Localizing nimib pages: how other tools do it, three API sketches, and lingua, a prototype
## that this page uses for itself (English and Italian). Writes ../index.html. See README.md.
import std/[os, strutils]
import nimib except md
import tabelline, tabelline/nimib
import lingua, page, review

const srcDir = currentSourcePath().parentDir

nbInit
nb.doc.filename = srcDir.parentDir / "index.html"
nb.usePage("Localizing nimib pages",
           "How to write a nimib page in more than one language: how other tools do it, three API sketches, and a prototype in Nim that this page uses for itself.")
nb.useLingua(["en", "it"], ["English", "Italiano"])
nbReview(tversion = 1, tpage = "nimib-localization", tsource = "nimib-localization/src/index.nim")

nbTitle "12 November 2026 · research for [nimib](https://github.com/pietroppeter/nimib)",
  "Localizing nimib pages",
  """
How could a nimib page be read in more than one language? This page looks at how gettext,
Fluent, Sphinx, mdBook, Quarto, Hugo and others do it, sketches three ways nimib could, and
tries the best two in a small library, **lingua**. The page is its own example: the switch at
the top shows it in Italian, from a catalog that lingua keeps up to date.
"""
nbVersion 1, "12 November 2026"

nbNote """
The Italian text was translated by Claude and nobody has reviewed it yet: the catalog marks
every entry `machine` until someone does. A chunk with no translation shows in English, set
apart by a dashed rule.
"""

nbToc

nbText """
## Three things to translate

A nimib page is a Nim program that writes a page. To read it in another language, three
different things change, and each asks for its own tool:

- **The text**: what `nbText` says, the largest part, written by a person.
- **The words of the page itself**: the header, the footer, a label like *output*, the buttons
  of the review mode. Few, and the same on every page of a site.
- **What the code prints**: numbers, dates and tables, which have their own conventions in each
  language (25,460 in English is 25.460 in Italian), and any text the code writes.

Then there is what the browser must be told: `<html lang="en-us">`, which nimib writes on
every page, whatever its language. Screen readers, hyphenation and search engines read it.

The words of the trade: *internationalization* (i18n) is making a program ready to be
translated; *localization* (l10n) is translating it; a *locale* is a language with its
conventions for numbers, dates and money (`it`, `de-CH`).
"""

nbText """
## How others do it

Thirteen tools, in five families. The first are libraries for messages in code; the others are
for documents and sites. Links to each are under *Sources*, at the end.
"""

type Tool = tuple[family, tool, unit, lives, reader: string]

nbEach:
  let tools: seq[Tool] = @[
    (tr"Messages in code", "[GNU gettext](https://www.gnu.org/software/gettext/)",
     tr"a message: a string of the program", tr"a PO file per language", tr"the program picks the language when it runs; every translation tool reads PO"),
    (tr"Messages in code", "[Fluent](https://projectfluent.org/)",
     tr"a message with an id, plurals and genders written by the translator", tr"an FTL file per language", tr"a translation can have variants the source lacks (Mozilla's Firefox)"),
    (tr"Messages in code", "[MessageFormat 2](https://unicode.org/reports/tr35/tr35-messageFormat.html)",
     tr"a message with placeholders and variants", tr"wherever the program keeps them", tr"a Unicode standard, stable since CLDR 47 (March 2025)"),
    (tr"Messages in code", "[nim-intl](https://github.com/iffy/nim-intl)",
     tr"a string marked `tr`", tr"Nim files per locale, written by the tool", tr"chosen when compiling; alpha, by its author's word"),
    (tr"Messages in code", "[nimterlingua](https://github.com/juancarlospaco/nim-nimterlingua)",
     tr"a string", tr"an INI file", tr"chosen when compiling, with `-d:`"),
    (tr"A document cut in segments", "[Sphinx](https://www.sphinx-doc.org/en/master/usage/advanced/intl.html) + [sphinx-intl](https://sphinx-intl.readthedocs.io/)",
     tr"a paragraph", tr"PO files, extracted by `make gettext`", tr"one site per language; Jupyter Book 1 builds on it"),
    (tr"A document cut in segments", "[mdbook-i18n-helpers](https://github.com/google/mdbook-i18n-helpers)",
     tr"a paragraph, a heading, an item of a list", tr"a PO file per language, extracted by `mdbook-xgettext`", tr"one book per language: Comprehensive Rust, Rust by Example"),
    (tr"A file per language", "[Quarto](https://quarto.org/) + [babelquarto](https://docs.ropensci.org/babelquarto/)",
     tr"a whole file: `index.qmd`, `index.it.qmd`", tr"side by side in the project", tr"one site with a language switch; babeldown drafts the translation with DeepL"),
    (tr"A file per language", "[Hugo](https://gohugo.io/content-management/multilingual/)",
     tr"a whole page (`post.it.md`), and the words of the theme", tr"beside the page; the theme's words in `i18n/it.toml`", tr"one site per language, each page linked to its translations"),
    (tr"A file per language", "[Jupyter Book 2](https://jupyterbook.org/)",
     tr"nothing built in", tr"a folder or a repository per language", tr"each book on its own"),
    (tr"One source, every language", "[Pandoc](https://pandoc.org/MANUAL.html#language-variables)",
     tr"a span or a div with a `lang`", tr"in the source itself", tr"a filter keeps one language"),
    (tr"One source, every language", "[action-translation](https://quantecon.github.io/action-translation)",
     tr"a MyST document", tr"a repository per language, kept in step by a GitHub Action", tr"QuantEcon's: Claude translates every change, a person reviews it"),
    (tr"Data in the reader's locale", "[tabelline](https://pietroppeter.github.io/tabelline/)",
     tr"numbers, money and dates in a table", tr"every locale of CLDR, in the library", tr("`tabella(data, locale = \"it\")`"))]
  nbTable tools, groupnameCol = "family":
    tabHeader tr"How others translate"
    colsLabel:
      tool: tr"Tool"
      unit: tr"What is translated"
      lives: tr"Where translations live"
      reader: tr"What a reader gets"
    fmtMarkdown ["tool", "unit", "lives", "reader"]
    optCssTheme()

nbText """
## Two families, and what they teach

Leaving the libraries aside, the tools for documents are of two kinds.

**A file per language** (Quarto with babelquarto, Hugo, MkDocs, Docusaurus): the Italian page
is a copy of the English one, translated. Simple to start and to understand, and the
translation can say things differently. But when the English page changes, nothing says which
part of the Italian is now out of date, and the code is copied too: in a notebook, every code
block would live, and run, twice.

**A document cut in segments** (Sphinx, mdBook with its helpers): the source stays the only
page, a tool cuts its text into paragraphs, and each paragraph is a message of a catalog, in
gettext's PO format. A paragraph that changes is a new message, so the catalog knows exactly
what to translate again; code is never copied; and any PO editor (Poedit, Weblate, Crowdin)
works on it. The translation follows the source paragraph by paragraph, which is also its
limit.

Three lessons for nimib:

- The unit that works for documents is the paragraph: small enough to see what changed, large
  enough to translate well. mdbook-i18n-helpers moved from whole pages to paragraphs for this.
- PO is the lingua franca. A new format would cut nimib off from every tool translators use.
- A machine draft and a human review is how translations are now made (babeldown with DeepL,
  QuantEcon with Claude). The catalog must say which entries a person has checked.
"""

nbText """
## What nimib has that the others lack

The tools above work on text files. A nimib page is a program, and that gives it four things:

- **Blocks are values.** nimib knows which block is text, which is code and which is output,
  so it never has to guess what to translate, as a tool that reads Markdown must.
- **The code runs when the page is built.** It can run once per language and print numbers,
  dates and tables in each language's own way. No other tool here localizes the outputs.
- **One program writes every language.** The same run can write one page with a switch, or
  one file per language, with no second build.
- **nimib owns the words of the page.** Its header, footer and the review mode can take their
  words from the same catalog as the text.
"""

nbText """
## Three ways to write it

**A. Every language in the source.** Each text block carries its translations, as Pandoc's
`lang` divs do:

```nim
nbText:
  en: "The islands of the Mediterranean"
  it: "Le isole del Mediterraneo"
```

Everything is in one place, and a short page is easy to keep in step. But the source becomes
twice as long for each language, a translator must edit Nim, and nothing says when the English
changed and the Italian did not.

**B. The source stays as it is; a catalog beside it.** `nbText` does not change. The page's
text is cut into chunks, and each chunk is an entry of `it.po`:

```po
msgid "## Three things to translate"
msgstr "## Tre cose da tradurre"
```

A translator never sees Nim; a chunk that changes loses its translation and shows in English
until someone translates it again; and every PO tool works.

**C. Code that runs once per language.** For what the code computes, `nbEach` runs a part of
the page once per language, with `lang` set to it, and `tr` translates a message from the
code:

```nim
nbEach:
  nbTable tabella(islands, locale = lang):
    tabHeader tr"The largest islands"
```

These are not rivals: **B for the text, C for the outputs**, and A for nothing, or for a
note that only one language needs. Then, two ways to deliver the result: one page with a
switch (an artifact, a post, a page shared by link), or one file per language, with the links
between them that search engines read (a site, a book).
"""

nbText """
## lingua, a prototype

lingua is B and C in about 300 lines of Nim, with no dependency but nimib. It changes nothing
in nimib: it replaces how text blocks are drawn, which nimib allows. This page uses it; its
first lines are:

```nim
nbInit
nb.usePage("Localizing nimib pages", "...")
nb.useLingua(["en", "it"], ["English", "Italiano"])
```

and it ends with `nbSaveLingua` where a page ends with `nbSave`. In between it is a plain
nimib page. Here is how lingua cuts a text into chunks:
"""

nbCode:
  for c in chunks("## A heading\n\nA paragraph,\non two lines.\n\n- a list\n- of two items"):
    echo "· ", c.replace("\n", " ⏎ ")

nbText """
A heading, a paragraph and a list: three messages. A block of code is a chunk of its own,
and is not translated. Each chunk is a `msgid` of the catalog. When the page is built, lingua
meets every chunk, adds the new ones to `it.po` with an empty translation, and moves those no
longer used to the end, as gettext's `msgmerge` does. This is the catalog now:
"""

nbCode:
  let catalog = readPo(srcDir / "it.po")
  echo catalog.entries.len, " entries, ", catalog.obsolete.len, " obsolete"
  for e in catalog.entries.values:
    if e.msgid.startsWith("## "):
      echo e.msgid, "  →  ", e.msgstr
      break

nbText """
When the page is drawn, every chunk is written in every language, each in an element with its
`lang`; the switch in the header shows one and hides the others, remembers the choice, and
reads `?lang=it` in the address. Without JavaScript the page is in English. A heading takes
its id from the English, so a link to a section works in both languages.

The table below is counted when the page is built: every message of the page (the chunks of
its text, and the words of its blocks and tables), and how many have a translation.
"""

nbStatus

nbText """
## Outputs in the reader's language

Here is C at work. The code below runs twice, once in English and once in Italian, and the
switch at the top shows one run or the other. The table is tabelline's, given the language as
its locale; the names of the islands and the title come from the catalog through `tr`.
"""

type Island = tuple[island: string, area: int, people: float]

nbEach:
  nbCode:
    let islands: seq[Island] = @[(tr"Sicily", 25_460, 4.8), (tr"Sardinia", 23_813, 1.6),
      (tr"Cyprus", 9_251, 1.3), (tr"Corsica", 8_680, 0.35), (tr"Crete", 8_336, 0.62)]
    nbTable tabella(islands, locale = lang):
      tabHeader tr"The largest islands of the Mediterranean", tr"Area in km², people in millions, rounded"
      colsLabel:
        island: tr"Island"
        area: tr"Area"
        people: tr"People"
      fmtNumber "area", decimals = 0
      fmtNumber "people", decimals = 2, dropTrailingZeros = true
      optCssTheme()
    echo formatDate("2026-11-12", "yMMMEd", lang)

nbText """
The digits are grouped and the decimals marked as each language does (25,460 and 4.8 in
English; 25.460 and 4,8 in Italian), and the date is written in each language's order and
words, from the CLDR data that tabelline carries. Nim's own `std/times` can do part of it:
`format` takes a `DateTimeLocale` with the names of months and days, but no data for any
language but English.
"""

nbNote("""
`nbEach` runs its body once per language, so what it defines lives inside it: here `islands`
is not seen after the block. `lang` is the language of the run (`en`, then `it`), and `tr`
gives a message in it. The code shown is the same in both runs; only its output changes.
""", nkCode)

nbText """
## A real case: the islands story

While this page was being written, tabelline's story of the Mediterranean islands got its
Italian version, built the simplest way. It is worth comparing, because it chose
differently at almost every step:

- **One build per language.** `isole.nim` is the one source; `isole_it.nim` is two lines,
  `const lang = "it"` and `include isole`. Two pages, two runs, and every output is in its
  language without `nbEach`.
- **`tr` for everything.** Every text a reader sees, text blocks included, goes through
  `tr"..."`, which looks the English up in a plain text file of `en:` and `it:` pairs. An empty
  `it:` keeps the English.
- **A missing key fails the build.** It is written to a file of what is missing, so the two
  languages cannot drift apart; lingua shows the English instead and counts it.
- **Data translated at the source.** Values are translated where the data is read, and the
  names of the islands come from Wikidata's Italian labels: no catalog needed for them.

Both work. Building once per language is simpler for a site, where each language has its own
address anyway; one page with a switch suits a page shared by link. Failing the build is a
choice a project should be able to make: lingua could take a `strict` flag.

What it found missing is more useful than how it was done. Besides `<html lang>`, which it
sets from JavaScript, and the English words of the review mode, the look switch, the footer
and *Show code*:

- **tabelline has no locale for the whole page.** Every `tabella()` takes `locale = lang`, and
  `initTabellaPreview` takes none at all, so the locale is set on the table afterwards.
- **`fmtInteger` in a `summaryRows` block ignores the table's locale.**
- **The labels of summary rows come from identifiers** (`total: agg.sum`), so they need
  `textTransform tr` to be translated; and **`fmtCountry` gives only English names**, fixed
  the same way.
- **Heading anchors drop accented letters** when a heading is turned into an id. lingua avoids
  it by taking ids from the English, but a page written in Italian would hit it.
- **Pictures**: the maps (SVG) and the photos have English words in them, which no catalog of
  text reaches.
"""

nbText """
## What nimib would need

lingua works without changing nimib, but it had to work around five things, and the islands
story adds a sixth. Each is a small change, and most would help any page, translated or not:

- **The language of the page.** nimib writes `<html lang="en-us">` on every page. A `lang`
  in `nimib.toml` (or `nb.lang`) would fix it; lingua replaces the whole page to write it.
- **State while drawing.** nimib draws with functions that cannot change anything
  (`noSideEffect`), so lingua keeps its catalog in a global and says
  `{.cast(noSideEffect).}` to read it. A place for a block's helpers in the document would do.
- **Saving more than once.** `nbSave` writes one file; lingua's `nbSaveEach` calls it once per
  language. A nimibook would need it per chapter, with a switch in its menu.
- **nimib's own words.** The default theme and the review mode have English words in their
  HTML and their scripts; they could take them from a small catalog that nimib ships.
- **The review mode.** Its export should say which language was read, so a comment on the
  Italian becomes a change to `it.po`, and marking a reviewed entry would clear `machine`.
- **Heading ids for every language.** The slug of a heading should keep accented letters
  (`perché` as `perche`, not `perch`), or be taken from the source language as lingua does.

For tabelline, the islands story asks for a locale for the whole page (an option that every
`tabella` and `initTabellaPreview` follows), for every format to follow the table's locale
(`fmtInteger` in summary rows), and for country names in every language of CLDR.
"""

nbText """
## Open questions

- **Code.** Comments and strings in code blocks stay in English here. mdbook-i18n-helpers
  translates a block of code as a whole message; for a nimib page that would mean running
  translated code, so it is probably better left alone.
- **A chunk that changes.** A typo fixed in English makes its chunk a new message, and the
  Italian is lost until it is translated again. `msgmerge` keeps the old translation as
  *fuzzy* when the new text is close; lingua could do the same.
- **Plurals and genders.** `tr` with `%` is enough for a page. Messages with plurals need
  MessageFormat 2 or Fluent, and I found no Nim library for either.
- **How large a site.** A catalog per page is right for a page; a book or a site might want
  one per chapter, or one for all, as mdBook has.
- **Right to left.** Arabic or Hebrew would need `dir="rtl"` and a theme that follows it.
"""

nbText """
## How it is built

lingua is one file, `lingua.nim`, in five parts, each built on the one before. Every piece is
shown here as it is in the file; the whole file is folded at the end.

**Chunks.** A text is cut at its blank lines, except inside a fence of code. A heading's id
comes from its English text.
"""

nbProc "lingua.nim", "chunks", "translatable", "slug"

nbText """
**The catalog.** A PO file is a list of entries: comments, then `msgid` and `msgstr`, each a
quoted string that may go on over several lines. lingua reads only what it writes: no plural
forms and no contexts. A translation is looked up by its whole English text, which is what
gettext does.
"""

nbProc "lingua.nim", "readPo", "lookup", "tr"

nbText """
**Drawing.** `useLingua` reads the catalogs and puts its own function where nimib draws a
text block (`partials["nbText"]`). That function cuts the text into chunks and writes each
in every language, or only in the one being written when there is one file per language.
"""

nbProc "lingua.nim", "useLingua", "localizedChunk", "localized"

nbText """
**Once per language.** `nbEach` makes a container with one part per language and runs its
body inside each part, with `l10n.current` set; when drawn, each part is shown in its
language.
"""

nbProc "lingua.nim", "nbEach"

nbText """
**Saving.** The page is drawn once to meet every message; then the catalogs are updated, the
messages counted, and the page drawn again and written.
"""

nbProc "lingua.nim", "updateCatalogs", "nbSaveLingua", "nbSaveEach"

nbText """
## The files

Everything that makes this page, as it is in its folder.
"""

nbFoldCode "lingua.nim"
nbFoldCode "page.nim"
nbFoldCode "index.nim"
nbFoldCode "it.po", "text"

nbText """
## Sources

- gettext: [the GNU gettext manual](https://www.gnu.org/software/gettext/manual/gettext.html),
  PO files and `msgmerge`.
- Fluent: [projectfluent.org](https://projectfluent.org/). MessageFormat 2:
  [stable in CLDR 47](https://blog.unicode.org/2025/03/unicode-cldr-47-release-messageformat-2.html).
- Sphinx: [Internationalization](https://www.sphinx-doc.org/en/master/usage/advanced/intl.html)
  and [sphinx-intl](https://sphinx-intl.readthedocs.io/). Jupyter Book: the discussion
  [*multi language site in one repo*](https://github.com/orgs/executablebooks/discussions/220).
- mdBook: [mdbook-i18n-helpers](https://github.com/google/mdbook-i18n-helpers) and its
  [usage guide](https://github.com/google/mdbook-i18n-helpers/blob/main/i18n-helpers/USAGE.md).
- Quarto: [babelquarto](https://docs.ropensci.org/babelquarto/) and
  [babeldown](https://docs.ropensci.org/babeldown/), from rOpenSci.
- Hugo: [Multilingual mode](https://gohugo.io/content-management/multilingual/).
- Pandoc: [language variables](https://pandoc.org/MANUAL.html#language-variables).
- QuantEcon: [action-translation](https://quantecon.github.io/action-translation).
- Nim: [nim-intl](https://github.com/iffy/nim-intl),
  [nimterlingua](https://github.com/juancarlospaco/nim-nimterlingua),
  [std/times](https://nim-lang.org/docs/times.html#DateTimeLocale) and
  [tabelline's locales](https://pietroppeter.github.io/tabelline/).
"""

nbSaveLingua
