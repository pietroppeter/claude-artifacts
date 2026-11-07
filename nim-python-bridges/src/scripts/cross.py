import subprocess, sys, time
from pathlib import Path
from nimlang._build import nim_compile_command
from nimlang.hatch_hook import pin_target, platform_tag
S = Path(sys.argv[1]); src = Path("nim/capi.nim").resolve()
for t, name in [("x86_64-linux-gnu.2.17","libmari.so"),("aarch64-linux-gnu.2.17","libmari.so"),
                ("aarch64-macos","libmari.dylib"),("x86_64-macos","libmari.dylib"),("x86_64-windows","mari.dll")]:
    t = pin_target(t); out = S/"cross"/platform_tag(t)/name
    cmd = nim_compile_command(["--app:lib","-d:release","--hints:off","--passL:-s",f"--nimcache:{S}/nc-{t}",f"--out:{out}",str(src)], target=t)
    t0=time.time(); r = subprocess.run(cmd, capture_output=True, text=True)
    print(platform_tag(t), "ok" if r.returncode==0 else "FAIL", "%.0fs"%(time.time()-t0), out.stat().st_size if out.exists() else "", r.stderr[-600:] if r.returncode else "")
