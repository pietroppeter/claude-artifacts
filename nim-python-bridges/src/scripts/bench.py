import sys, time, json, ctypes, timeit
sys.path.insert(0, sys.argv[1]); sys.path.insert(0, sys.argv[2])
import mari, marinp
src = "flowchart LR\n  a[Start] --> b{Ok?}\n  b -->|yes| c[End]\n  b -->|no| a"
lib = mari._lib
lib.mari_pele_version.restype = ctypes.c_char_p
print("python", sys.version.split()[0])
print("same svg:", mari.Diagram(src).svg == marinp.svg(src))
n=200000
print("tiny call, ctypes: %.2f us" % (timeit.timeit(lambda: lib.mari_pele_version(), number=n)/n*1e6))
print("tiny call, nimpy:  %.2f us" % (timeit.timeit(lambda: marinp.pele(), number=n)/n*1e6))
big = "x"*1_000_000
print("1 MB string round trip, nimpy: %.0f us" % (timeit.timeit(lambda: marinp.echo_str(big), number=200)/200*1e6))
n=300
print("draw, ctypes+json: %.3f ms" % (timeit.timeit(lambda: mari.draw(src), number=n)/n*1e3))
print("draw, nimpy:       %.3f ms" % (timeit.timeit(lambda: marinp.svg(src), number=n)/n*1e3))
try: marinp.svg("flowchart LR\n  a --> [")
except Exception as e: print("nimpy error:", type(e).__name__, str(e)[:80])
try: mari.Diagram("flowchart LR\n  a --> [").svg
except Exception as e: print("ctypes error:", type(e).__name__, e.code, e.line, e.column)
