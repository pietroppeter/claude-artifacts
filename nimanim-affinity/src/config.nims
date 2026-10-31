# Dependencies from deps.sh (NIMANIM_AFFINITY_DEPS, default ./deps).
import std/os
let deps = getEnv("NIMANIM_AFFINITY_DEPS", thisDir() / "deps")
for d in ["nimanim", "cairo", "nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
# FreeType for nimanim's font loading (its .nimble hook only runs under nimble)
switch("passL", "-lfreetype")
switch("passC", "-I/usr/include/freetype2")
