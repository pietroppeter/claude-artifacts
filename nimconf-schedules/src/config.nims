# Dependencies from deps.sh (NIMCONF_DEPS, default ./deps).
import std/os
let deps = getEnv("NIMCONF_DEPS", thisDir() / "deps")
for d in ["tabelline", "nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("hints", "off")
