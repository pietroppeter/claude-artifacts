# Dependencies from deps.sh (FV_DEPS, default ./deps).
import std/os
let deps = getEnv("FV_DEPS", thisDir() / "deps")
for d in ["tabelline", "nanuq", "nimib", "fusion", "markdown", "parsetoml", "jsony", "malebolgia"]:
  switch("path", deps / d / "src")
switch("path", deps / "taskpools")
switch("hints", "off")
switch("warnings", "off")
# The review mode, shared by the pages of this repository (shared/review/README.md).
switch("path", thisDir() / ".." / ".." / "shared" / "review")
