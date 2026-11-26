## A tiny shared library: Nim hands Arrow columns to anyone who speaks the C Data Interface,
## and reads theirs. Build: nim c --app:lib -d:release -o:libkosovel.so libkosovel.nim
import std/[unicode, strutils]
import ../lib/cdata

var words*: seq[string] = @["Kras", "je", "srce", "čez", "Srečko", "kraška", "burja", "je"]

proc kosovel_set_words(text: cstring) {.exportc, dynlib, cdecl.} =
  ## Give the library its words (one per line).
  words = ($text).splitLines

proc kosovel_export_batch(s: ptr ArrowSchema; a: ptr ArrowArray) {.exportc, dynlib, cdecl.} =
  ## A record batch with four columns of the same words, in four encodings.
  var lens: seq[int32]
  for w in words: lens.add int32(w.runeLen)
  structColumn("", [utf8Column("word", words), dictColumn("word_dict", words),
                    stringViewColumn("word_view", words), runEndColumn("word_runs", words),
                    int32Column("letters", lens)]).exportTo(s, a)

proc kosovel_count_diacritics(s: ptr ArrowSchema; a: ptr ArrowArray): int64 {.exportc, dynlib, cdecl.} =
  ## Read a utf8 column made by someone else, in place, and count č, š, ž (any case).
  for w in utf8Values(s, a):
    for r in w.runes:
      if r.toLower in [Rune(0x10D), Rune(0x161), Rune(0x17E)]: inc result
