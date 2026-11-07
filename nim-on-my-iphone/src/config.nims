# Dependencies from deps.sh (NIM_IPHONE_DEPS, default ./deps).
import std/os
let deps = getEnv("NIM_IPHONE_DEPS", thisDir() / "deps")
for d in ["nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("hints", "off")
