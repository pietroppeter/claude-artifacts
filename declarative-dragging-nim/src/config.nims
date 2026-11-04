# Dependencies from deps.sh (DECLARATIVE_DRAGGING_DEPS, default ./deps).
import std/os
let deps = getEnv("DECLARATIVE_DRAGGING_DEPS", thisDir() / "deps")
for d in ["nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("hints", "off")
