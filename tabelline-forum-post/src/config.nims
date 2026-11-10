# The page reuses the dependencies, the style and the review mode of nimconf-schedules.
import std/os
let deps = getEnv("NIMCONF_DEPS", thisDir() / ".." / ".." / "nimconf-schedules" / "src" / "deps")
for d in ["tabelline", "nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("path", thisDir() / ".." / ".." / "nimconf-schedules" / "src")
switch("hints", "off")
