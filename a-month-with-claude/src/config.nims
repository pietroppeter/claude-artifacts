# Dependencies from deps.sh (MONTH_DEPS, default ./deps).
import std/os
let deps = getEnv("MONTH_DEPS", thisDir() / "deps")
for d in ["tabelline", "nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("hints", "off")
# The review mode, shared by the pages of this repository (shared/review/README.md).
switch("path", thisDir() / ".." / ".." / "shared" / "review")
