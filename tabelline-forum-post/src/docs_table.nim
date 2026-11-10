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
