# zlib comes from conda-forge, not from apt/brew: headers + .so in $CONDA_PREFIX
import std/strutils
{.passL: "-lz".}
proc crc32(crc: culong, buf: cstring, len: cuint): culong {.importc, header: "<zlib.h>".}
proc zlibVersion(): cstring {.importc, header: "<zlib.h>".}

let msg = "Nim go wild"
echo "zlib ", zlibVersion(), ": crc32(\"", msg, "\") = ", crc32(0, msg, msg.len.cuint).uint32.toHex
