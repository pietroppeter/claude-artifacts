# Dependencies from deps.sh (LINGUA_DEPS, default ./deps); the Munari stylesheet of
# nimconf-schedules (style.nim, fonts inlined); the review mode shared by the pages of this repository.
import std/os
let deps = getEnv("LINGUA_DEPS", thisDir() / "deps")
for d in ["tabelline", "nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("path", thisDir() / ".." / ".." / "nimconf-schedules" / "src")
switch("path", thisDir() / ".." / ".." / "shared" / "review")
switch("hints", "off")
