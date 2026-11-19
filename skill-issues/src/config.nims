# Dependencies from deps.sh (SKILL_ISSUES_DEPS, default ./deps).
import std/os
let deps = getEnv("SKILL_ISSUES_DEPS", thisDir() / "deps")
for d in ["nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("hints", "off")
# The review mode, shared by the pages of this repository (shared/review/README.md).
switch("path", thisDir() / ".." / ".." / "shared" / "review")
