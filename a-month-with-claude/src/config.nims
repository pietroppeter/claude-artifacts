# Dependencies from deps.sh (MONTH_DEPS, default ./deps).
import std/os
let deps = getEnv("MONTH_DEPS", thisDir() / "deps")
for d in ["tabelline", "nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("hints", "off")
