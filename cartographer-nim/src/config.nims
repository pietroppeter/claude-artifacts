# Dependencies from deps.sh (CARTO_DEPS, default ./deps).
import std/os
let deps = getEnv("CARTO_DEPS", thisDir() / "deps")
for d in ["nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("hints", "off")
