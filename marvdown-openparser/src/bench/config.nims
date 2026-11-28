# The libraries from deps.sh (MO_BENCH_DEPS, default ./deps).
import std/os
let deps = getEnv("MO_BENCH_DEPS", thisDir() / "deps")
for d in ["marvdown", "openparser", "nimsimd", "nimcypher", "dynasm", "markdown", "jsony", "parsetoml"]:
  switch("path", deps / d / "src")
switch("hints", "off")
