Hi, I just released tabelline 0.1, beautiful display tables for Nim:

https://pietroppeter.github.io/tabelline/

Display tables are tables designed for human consumption (on a website, in a report, on a newspaper...) and are an output of a data process and they are not intended for further consumption.

Tabelline follows R's [gt](https://gt.rstudio.com/) and Python's [Great Tables](https://posit-dev.github.io/great-tables/): the same parts of a table and the same verbs in camelCase, written in plain Nim. Tables render to HTML, text and Markdown, and go straight into a nimib page. Further releases are planned to cover more or less the complete feature set and possibly also extend it. The name comes from *le tabelline*, the times tables of Italian primary school (it also means, small tables).

On the site you find a Guide, a Book that ports the gt and Great Tables guides, stories told with tables (Milano Cortina 2026 and FOSDEM), the roadmap, a devlog and a design guide. Here they are as a table, made with tabelline and printed as Markdown, so you can put tabelline tables on the forum too:

```nim
import tabelline

const site = "https://pietroppeter.github.io/tabelline/"
func page(name, path: string): string = "[" & name & "](" & site & path & ")"

let docs: seq[tuple[group, page, inside: string]] = @[
  ("🔴 Learn tabelline", page("Guide", "explainer/"), "gt and Great Tables from zero, then tabelline step by step"),
  ("🔴 Learn tabelline", page("Book", "book/"), "the gt and Great Tables guides, page by page, in Nim"),
  ("🔴 Learn tabelline", page("Stories", "stories/"), "real subjects in tables: Milano Cortina 2026, FOSDEM"),
  ("🔵 Where it's going", page("Roadmap", "roadmap/"), "what each release adds, up to 0.5"),
  ("🔵 Where it's going", page("Feature map", "coverage/"), "every feature of gt, and whether tabelline has it"),
  ("🟡 How it's made", page("Devlog", "devlog/"), "dated posts on how tabelline is made"),
  ("🟡 How it's made", page("Specs", "specs/"), "every behaviour, with an example that runs"),
  ("🟡 How it's made", page("Design guide", "design/"), "the two looks, the shapes, the palette"),
  ("🟡 How it's made", page("For coding agents", "agents/"), "setup and working rules, for agents and people")]

let t = tabella(docs, groupnameCol = "group"):
  tabHeader "The tabelline docs"
  colsLabel {"page": "Page", "inside": "What is inside"}
  fmtMarkdown "page"
echo t.toMarkdown
```

**The tabelline docs**

| Page | What is inside |
|:--|:--|
| **🔴 Learn tabelline** |  |
| [Guide](https://pietroppeter.github.io/tabelline/explainer/) | gt and Great Tables from zero, then tabelline step by step |
| [Book](https://pietroppeter.github.io/tabelline/book/) | the gt and Great Tables guides, page by page, in Nim |
| [Stories](https://pietroppeter.github.io/tabelline/stories/) | real subjects in tables: Milano Cortina 2026, FOSDEM |
| **🔵 Where it's going** |  |
| [Roadmap](https://pietroppeter.github.io/tabelline/roadmap/) | what each release adds, up to 0.5 |
| [Feature map](https://pietroppeter.github.io/tabelline/coverage/) | every feature of gt, and whether tabelline has it |
| **🟡 How it's made** |  |
| [Devlog](https://pietroppeter.github.io/tabelline/devlog/) | dated posts on how tabelline is made |
| [Specs](https://pietroppeter.github.io/tabelline/specs/) | every behaviour, with an example that runs |
| [Design guide](https://pietroppeter.github.io/tabelline/design/) | the two looks, the shapes, the palette |
| [For coding agents](https://pietroppeter.github.io/tabelline/agents/) | setup and working rules, for agents and people |

Here is what it looks the styled documentation, with a main theme inspired by Bruno Munari and Japanese colors, you can see parts of the table which are the names used in the api.

.. image:: https://raw.githubusercontent.com/pietroppeter/claude-artifacts/7141f2a1bc354e9230287fbc35c9772bfbabc0b2/tabelline-forum-post/src/shots/tabelline-parts.png
   :width: 640px

There is also a playful theme on school (Quaderno). Theme styling is one of the new addition of tabelline which is not a direct port of gt/great tables (you can see also we have Nim sugar to create tables as we should).

.. image:: https://raw.githubusercontent.com/pietroppeter/claude-artifacts/a5fc85240f1b0b94b5da28748900996511dc990a/tabelline-forum-post/src/shots/guide-quaderno.png
   :width: 640px

As a small celebration I put every NimConf schedule, 2020 to 2026, in tabelline tables (and with a NimConf style):

https://pietroppeter.github.io/claude-artifacts/nimconf-schedules/

.. image:: https://raw.githubusercontent.com/pietroppeter/claude-artifacts/21b7dbded2ad7fea642453c413ac0e8a837ce9ab/tabelline-forum-post/src/shots/nimconf-2026.png
   :width: 640px

That page also has a review mode for nimib pages: press ✎ Review, select some text, comment, and export all the comments to paste to a coding agent. It will move to nimib, so every nimib notebook can have it.

Made with Claude and Opus 5.5, mostly from my phone, mostly over the weekend.

I really enjoyed working on this: the reference API is beautiful and I think every language deserves a port of it! The moment I had the idea of the review mode (yesterday morning) it was exciting and it was so much fun iterating on it while using it (see the devlog post: https://pietroppeter.github.io/tabelline/devlog/review-mode/).
