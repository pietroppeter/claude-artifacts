# Dependencies from deps.sh (APPALETTE_DEPS, default ./deps).
import std/os
let deps = getEnv("APPALETTE_DEPS", thisDir() / "deps")
switch("path", thisDir() / "src")
switch("path", deps / "chroma" / "src")
switch("path", deps / "naffprop" / "src" / "naffprop")
