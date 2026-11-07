import sys, time
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, sys.argv[2])
which = sys.argv[1]
if which == "ctypes":
    import mari; f = lambda s: mari.draw(s)["svg"]
else:
    sys.path.insert(0, sys.argv[3]); import marinp; f = marinp.svg
srcs = [f"flowchart LR\n  a{i}[Node {i}] --> b{i}[Next]" for i in range(400)]
ref = [f(s) for s in srcs]
t=time.perf_counter()
with ThreadPoolExecutor(8) as ex: out = list(ex.map(f, srcs))
print(which, "8 threads:", sum(a==b for a,b in zip(ref,out)), "of", len(srcs), "right, %.0f ms" % ((time.perf_counter()-t)*1000))
