## Build-time highlighting for Nim, shell and CSS code, with highlight.js class names so a theme can
## colour it. nimib uses `packages/docutils/highlite` from Nim's own sources, which Nimony
## does not ship. This one knows comments, strings, numbers and keywords: enough to read.
import std/strutils

const nimKeywords = ["addr", "and", "as", "asm", "bind", "block", "break", "case", "cast",
  "concept", "const", "continue", "converter", "defer", "discard", "distinct", "div", "do",
  "elif", "else", "end", "enum", "except", "export", "finally", "for", "from", "func", "if",
  "import", "in", "include", "interface", "is", "isnot", "iterator", "let", "macro", "method",
  "mixin", "mod", "nil", "not", "notin", "object", "of", "or", "out", "proc", "ptr", "raise",
  "ref", "return", "shl", "shr", "static", "template", "try", "tuple", "type", "using", "var",
  "when", "while", "xor", "yield", "true", "false"]

const shKeywords = ["if", "then", "else", "fi", "for", "do", "done", "while", "case", "esac",
  "in", "set", "cd", "echo", "export", "local", "return"]

proc escChar(result: var string; c: char) =
  case c
  of '&': result.add "&amp;"
  of '<': result.add "&lt;"
  of '>': result.add "&gt;"
  else: result.add c

proc span(result: var string; cls, text: string) =
  result.add "<span class=\"hljs-" & cls & "\">"
  for c in text: escChar(result, c)
  result.add "</span>"

proc isKeyword(word, lang: string): bool =
  result = false
  if lang == "sh":
    for k in shKeywords:
      if k == word: return true
  else:
    for k in nimKeywords:
      if k == word: return true

proc highlightCode*(code, lang: string): string =
  ## `code` as HTML with spans; `lang` is "nim" (also ""), "sh", "css", or anything else for none
  result = ""
  if lang == "css":   # comments, strings and properties
    var i = 0
    while i < code.len:
      if code.continuesWith("/*", i):
        var e = i + 2
        while e < code.len and not code.continuesWith("*/", e): inc e
        e = min(e + 2, code.len)
        span(result, "comment", code.substr(i, e - 1))
        i = e
      elif code[i] == '"':
        var e = i + 1
        while e < code.len and code[e] != '"': inc e
        e = min(e + 1, code.len)
        span(result, "string", code.substr(i, e - 1))
        i = e
      elif code[i] in {'a'..'z', '-'} and (i == 0 or code[i-1] in {'{', ';', ' ', '\n'}):
        var e = i
        while e < code.len and code[e] in {'a'..'z', '0'..'9', '-'}: inc e
        if e < code.len and code[e] == ':' and (e + 1 >= code.len or code[e+1] != ':'):
          span(result, "keyword", code.substr(i, e - 1))
        else:
          for k in i ..< e: escChar(result, code[k])
        i = e
      else:
        escChar(result, code[i])
        inc i
    return
  if lang != "" and lang != "nim" and lang != "sh":
    for c in code: escChar(result, c)
    return
  var i = 0
  while i < code.len:
    let c = code[i]
    if c == '#':
      var e = i
      while e < code.len and code[e] != '\n': inc e
      span(result, "comment", code.substr(i, e - 1))
      i = e
    elif c == '"' and code.continuesWith("\"\"\"", i):
      var e = i + 3
      while e < code.len and not code.continuesWith("\"\"\"", e): inc e
      e = min(e + 3, code.len)
      span(result, "string", code.substr(i, e - 1))
      i = e
    elif c == '"' or (c == '\'' and lang == "sh"):
      var e = i + 1
      while e < code.len and code[e] != c and code[e] != '\n':
        if code[e] == '\\': inc e
        inc e
      e = min(e + 1, code.len)
      span(result, "string", code.substr(i, e - 1))
      i = e
    elif c == '\'' and i + 2 < code.len and (code[i+2] == '\'' or code[i+1] == '\\'):
      var e = i + 1
      if code[e] == '\\': inc e
      e = min(e + 2, code.len)
      span(result, "string", code.substr(i, e - 1))
      i = e
    elif c in {'0'..'9'} and (i == 0 or code[i-1] notin {'a'..'z', 'A'..'Z', '_'}):
      var e = i
      while e < code.len and code[e] in {'0'..'9', '.', 'x', 'o', 'b', '_', 'a'..'f', '\''}: inc e
      span(result, "number", code.substr(i, e - 1))
      i = e
    elif c in {'a'..'z', 'A'..'Z', '_'}:
      var e = i
      while e < code.len and code[e] in {'a'..'z', 'A'..'Z', '0'..'9', '_'}: inc e
      let word = code.substr(i, e - 1)
      if isKeyword(word, lang): span(result, "keyword", word)
      else: result.add word
      i = e
    else:
      escChar(result, c)
      inc i
