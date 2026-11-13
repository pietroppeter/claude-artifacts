## Copied by sync.sh from pietroppeter/tabelline docs/theme.nim at b7607193eb05ca0f7a18c0195e14c834b17ec684: the one
## function review.nim imports from it. Do not edit; run sync.sh.
import std/strutils

func scoped*(rules, scope: string): string =
  ## Puts `scope` before every selector of `rules`; `html` itself becomes `scope`. Rules inside
  ## `@media` are scoped too; comments are kept.
  var i = 0
  while i < rules.len:
    if rules.continuesWith("/*", i):
      let e = rules.find("*/", i) + 2
      result.add rules[i ..< e]; i = e
    elif rules[i] in {'}', '\n', ' '}:
      result.add rules[i]; inc i
    elif rules.continuesWith("@media", i):
      let e = rules.find('{', i) + 1
      result.add rules[i ..< e]; i = e
    else:
      let e = rules.find('{', i)
      var sels: seq[string]
      for s in rules[i ..< e].split(','):
        let s = s.strip
        sels.add(if s == "html": scope else: scope & " " & s)
      let close = rules.find('}', e)
      result.add sels.join(", ") & " " & rules[e .. close]; i = close + 1

