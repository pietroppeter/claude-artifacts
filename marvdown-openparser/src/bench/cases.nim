## Small inputs where marvdown and nim-markdown differ, rendered by both: writes ../data/cases.json.
import std/[json, options, os]
import markdown, marvdown

let cases = [
  ("A list right after a paragraph", "A list:\n- one\n- two\n"),
  ("A line ending with !", "the right place!\nNote that\n"),
  ("Inline HTML in a paragraph", "Text with <span class=\"x\">red</span> words.\n"),
  ("An inline image tag, then more text", "An image <img src=\"a.png\">.\n\n**bold** after\n"),
  ("A code span with double backticks", "Draw ``` ```mermaid ``` ``` blocks.\n"),
  ("Nested block quotes", ">>> foo\n> bar\n"),
  ("A table", "| a | b |\n|---|---|\n| 1 | 2 |\n"),
  ("A heading", "# Hello *world*\n"),
]
let opts = MarkdownOptions(allowTagsByType: some(tagAll), enableAnchors: false, parseYaml: false)
var res = newJArray()
for (name, src) in cases:
  var m = newMarkdown(src, opts)
  res.add %*{"name": name, "md": src,
    "nimMarkdown": markdown(src, config = initGfmConfig()),
    "marvdown": m.toHtml(),
    "marvdownDefault": marvdown.toHtml(src)}
writeFile(currentSourcePath().parentDir.parentDir / "data" / "cases.json", res.pretty)
