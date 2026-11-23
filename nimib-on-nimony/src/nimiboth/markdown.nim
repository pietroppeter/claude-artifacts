## A small Markdown renderer that Nim 2 and Nimony both compile. nimib uses nim-markdown,
## which needs `re` (PCRE), `htmlparser` and `strformat`: Nimony has none of the three.
## Covers what a page needs: headings, paragraphs, lists, quotes, fenced code, and inline
## code, bold, italic and links. Not CommonMark.
import std/strutils
import highlight

proc esc*(s: string): string =
  result = ""
  for c in s:
    case c
    of '&': result.add "&amp;"
    of '<': result.add "&lt;"
    of '>': result.add "&gt;"
    of '"': result.add "&quot;"
    else: result.add c

proc findFrom(s, sub: string; start: int): int =
  ## the index of `sub` in `s` at or after `start`, or -1
  result = -1
  var i = start
  while i + sub.len <= s.len:
    if s.continuesWith(sub, i): return i
    inc i

proc inline*(s: string): string =
  ## inline Markdown: `code`, **bold**, *italic*, [links](url), \escapes
  result = ""
  var i = 0
  while i < s.len:
    let c = s[i]
    if c == '\\' and i + 1 < s.len and s[i+1] in {'*', '`', '[', ']', '\\', '_', '#'}:
      result.add s[i+1]
      i += 2
    elif c == '`':
      let e = findFrom(s, "`", i + 1)
      if e < 0:
        result.add "`"
        inc i
      else:
        result.add "<code>" & esc(s.substr(i + 1, e - 1)) & "</code>"
        i = e + 1
    elif c == '*' and i + 1 < s.len and s[i+1] == '*':
      let e = findFrom(s, "**", i + 2)
      if e < 0:
        result.add "**"
        i += 2
      else:
        result.add "<strong>" & inline(s.substr(i + 2, e - 1)) & "</strong>"
        i = e + 2
    elif c == '*' and i + 1 < s.len and s[i+1] != ' ':
      let e = findFrom(s, "*", i + 1)
      if e < 0:
        result.add "*"
        inc i
      else:
        result.add "<em>" & inline(s.substr(i + 1, e - 1)) & "</em>"
        i = e + 1
    elif c == '[':
      let close = findFrom(s, "](", i + 1)
      let paren = if close < 0: -1 else: findFrom(s, ")", close + 2)
      if close < 0 or paren < 0:
        result.add "["
        inc i
      else:
        let url = s.substr(close + 2, paren - 1)
        result.add "<a href=\"" & esc(url) & "\">" & inline(s.substr(i + 1, close - 1)) & "</a>"
        i = paren + 1
    else:
      case c
      of '&': result.add "&amp;"
      of '<': result.add "&lt;"
      of '>': result.add "&gt;"
      else: result.add c
      inc i

proc listMarker(line: string): int =
  ## the length of a list marker (`- `, `* `, `12. `) at the start of `line`, or 0
  let t = line.strip(trailing = false)
  if t.startsWith("- ") or t.startsWith("* "): return line.len - t.len + 2
  var k = 0
  while k < t.len and t[k] in {'0'..'9'}: inc k
  if k > 0 and k + 1 < t.len and t[k] == '.' and t[k+1] == ' ': return line.len - t.len + k + 2
  result = 0

proc headingLevel(line: string): int =
  var k = 0
  while k < line.len and line[k] == '#': inc k
  if k >= 1 and k <= 6 and k < line.len and line[k] == ' ': k else: 0

proc markdown*(md: string): string =
  ## Markdown to HTML
  result = ""
  let lines = md.splitLines
  var i = 0
  var para: seq[string] = @[]
  proc flush(para: var seq[string]; result: var string) =
    if para.len > 0:
      result.add "<p>" & inline(para.join(" ")) & "</p>\n"
      para.setLen 0
  while i < lines.len:
    let line = lines[i]
    let t = line.strip
    if t.startsWith("```"):
      flush(para, result)
      let lang = t.substr(3).strip
      var code: seq[string] = @[]
      inc i
      while i < lines.len and not lines[i].strip.startsWith("```"):
        code.add lines[i]
        inc i
      inc i
      result.add "<pre><code>" & highlightCode(code.join("\n"), lang) & "</code></pre>\n"
    elif t.len == 0:
      flush(para, result)
      inc i
    elif headingLevel(t) > 0:
      flush(para, result)
      let n = headingLevel(t)
      result.add "<h" & $n & ">" & inline(t.substr(n + 1)) & "</h" & $n & ">\n"
      inc i
    elif t.startsWith(">"):
      flush(para, result)
      var quoted: seq[string] = @[]
      while i < lines.len and lines[i].strip.startsWith(">"):
        quoted.add lines[i].strip.substr(1).strip(trailing = false)
        inc i
      result.add "<blockquote>" & markdown(quoted.join("\n")) & "</blockquote>\n"
    elif listMarker(line) > 0:
      flush(para, result)
      let ordered = t[0] in {'0'..'9'}
      result.add(if ordered: "<ol>\n" else: "<ul>\n")
      while i < lines.len and listMarker(lines[i]) > 0:
        var item = lines[i].substr(listMarker(lines[i]))
        inc i
        # continuation lines: indented, not a new item, not blank
        while i < lines.len and lines[i].strip.len > 0 and listMarker(lines[i]) == 0 and
            lines[i].startsWith("  "):
          item.add " " & lines[i].strip
          inc i
        result.add "<li>" & inline(item) & "</li>\n"
      result.add(if ordered: "</ol>\n" else: "</ul>\n")
    else:
      para.add t
      inc i
  flush(para, result)
