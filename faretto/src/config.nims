# Dependencies from deps.sh (FARETTO_DEPS, default ./deps).
import std/os
let deps = getEnv("FARETTO_DEPS", thisDir() / "deps")
for d in ["tabelline", "nanuq", "nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("hints", "off")
switch("warnings", "off")
# The review mode, shared by the pages of this repository (shared/review/README.md).
switch("path", thisDir() / ".." / ".." / "shared" / "review")
