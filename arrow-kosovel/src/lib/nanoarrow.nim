## Just enough nanoarrow (https://arrow.apache.org/nanoarrow/) to read an Arrow IPC stream from Nim.
## nanoarrow is Arrow's small C library: a few C files, no dependencies, bundled with
## `ci/scripts/bundle.py --with-ipc --with-flatcc` (deps.sh does it) and compiled right into
## the Nim program. What it hands back are plain C Data Interface structs, the same ones
## cdata.nim builds, so the two meet without any glue.
import std/os
import cdata
export cdata

const puscicaDeps {.strdefine.} = currentSourcePath().parentDir.parentDir / "deps"   # config.nims sets it
const na = puscicaDeps / "nanoarrow-bundle"
{.passC: "-I" & na / "include".}
{.compile: na / "src" / "nanoarrow.c".}
{.compile: na / "src" / "nanoarrow_ipc.c".}
{.compile: na / "src" / "flatcc.c".}

const hNa = "nanoarrow/nanoarrow.h"
const hIpc = "nanoarrow/nanoarrow_ipc.h"

type
  ArrowArrayStream* {.importc: "struct ArrowArrayStream", header: hNa, bycopy.} = object
    get_schema*: proc (s: ptr ArrowArrayStream; o: ptr ArrowSchema): cint {.cdecl.}
    get_next*: proc (s: ptr ArrowArrayStream; o: ptr ArrowArray): cint {.cdecl.}
    get_last_error*: proc (s: ptr ArrowArrayStream): cstring {.cdecl.}
    release*: proc (s: ptr ArrowArrayStream) {.cdecl.}
  ArrowIpcInputStream* {.importc: "struct ArrowIpcInputStream", header: hIpc, bycopy.} = object
  CFile {.importc: "FILE", header: "<stdio.h>".} = object

proc fopen(p, m: cstring): ptr CFile {.importc, header: "<stdio.h>".}
proc ArrowIpcInputStreamInitFile(s: ptr ArrowIpcInputStream; f: pointer; closeOnRelease: cint): cint {.importc, header: hIpc.}
proc ArrowIpcArrayStreamReaderInit(o: ptr ArrowArrayStream; i: ptr ArrowIpcInputStream; opts: pointer): cint {.importc, header: hIpc.}
proc ArrowSchemaToString(s: ptr ArrowSchema; o: cstring; n: int64; recursive: char): int64 {.importc, header: hNa.}
proc ArrowNanoarrowVersion*(): cstring {.importc, header: hNa.}

proc `$`*(s: ptr ArrowSchema): string =
  ## nanoarrow's own one-line description of a schema.
  result = newString(512)
  let n = ArrowSchemaToString(s, cstring(result), 512, '\1')
  result.setLen min(n, 511)

iterator ipcBatches*(path: string; schema: var ArrowSchema): ptr ArrowArray =
  ## Every record batch of an Arrow IPC stream file, as a C Data Interface ArrowArray.
  var input: ArrowIpcInputStream
  var stream: ArrowArrayStream
  let f = fopen(cstring(path), "rb")
  doAssert f != nil, "cannot open " & path
  doAssert ArrowIpcInputStreamInitFile(input.addr, f, 1) == 0
  doAssert ArrowIpcArrayStreamReaderInit(stream.addr, input.addr, nil) == 0
  doAssert stream.get_schema(stream.addr, schema.addr) == 0, $stream.get_last_error(stream.addr)
  var batch: ArrowArray
  while true:
    doAssert stream.get_next(stream.addr, batch.addr) == 0, $stream.get_last_error(stream.addr)
    if batch.release == nil: break     # end of stream
    yield batch.addr
    batch.release(batch.addr)
  stream.release(stream.addr)
