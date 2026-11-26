## Kosovel's poems, read from an Arrow IPC stream with nanoarrow, and split into words.
import std/[unicode, strutils]
import nanoarrow

type Poem* = object
  title*, collection*, kind*, text*: string

proc column(s: ptr ArrowSchema; name: string): int =
  for i in 0 ..< int(s.nChildren):
    if $s.children[i].name == name: return i
  raise newException(KeyError, "no column " & name)

proc loadPoems*(path: string): seq[Poem] =
  ## Every record batch of the file, column by column, straight out of nanoarrow's buffers.
  var schema: ArrowSchema
  for batch in ipcBatches(path, schema):
    let s = schema.addr
    var cols: array[4, seq[string]]
    for k, name in ["title", "collection", "kind", "text"]:
      let i = column(s, name)
      cols[k] = utf8Values(s.children[i], batch.children[i])
    for r in 0 ..< int(batch.length):
      result.add Poem(title: cols[0][r], collection: cols[1][r], kind: cols[2][r], text: cols[3][r])
  schema.release(schema.addr)

proc words*(s: string): seq[string] =
  ## Lowercase words: runs of letters (č, š and ž are letters too).
  var cur = ""
  for r in s.runes:
    if r.isAlpha: cur.add $r.toLower
    elif cur.len > 0:
      result.add cur
      cur = ""
  if cur.len > 0: result.add cur

proc lines*(p: Poem): seq[string] = p.text.splitLines
