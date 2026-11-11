# The page reuses nimconf-schedules' dependencies (nimib and its own) and the shared review mode.
import std/os
let deps = getEnv("NIMCONF_DEPS", thisDir() / ".." / ".." / "nimconf-schedules" / "src" / "deps")
for d in ["nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("path", thisDir() / ".." / ".." / "shared" / "review")
switch("hints", "off")
