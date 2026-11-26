import std/os
import ../lib/nanoarrow
var schema: ArrowSchema
var rows = 0
for batch in ipcBatches(paramStr(1), schema):
  echo schema.addr
  let words = utf8Values(schema.children[0], batch.children[0])
  rows += words.len
  echo words[0..min(5, words.high)]
echo rows, " rows, nanoarrow ", ArrowNanoarrowVersion()
