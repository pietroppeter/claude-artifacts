import sys, time, hashlib
sys.path.insert(0, sys.argv[1])
import mari
srcs = ["flowchart LR\n  a[Start] --> b{Ok?}\n  b -->|yes| c[End]\n  b -->|no| a",
        "sequenceDiagram\n  Alice->>Bob: hi\n  Bob-->>Alice: hello",
        "pie title Pets\n  \"Dogs\" : 3\n  \"Cats\" : 2",
        "classDiagram\n  Animal <|-- Duck\n  class Duck{\n    +swim()\n  }"]
t=time.perf_counter(); mari.Diagram(srcs[0]).svg; t0=time.perf_counter()-t
for s in srcs: print(hashlib.sha1(mari.Diagram(s, {"nodes":{"a":{"dy":20}}} if s.startswith("flow") else None).svg.encode()).hexdigest()[:12], end=" ")
t=time.perf_counter()
for i in range(200): mari.Diagram(srcs[0]).svg
print("\nengine", mari.engine(), "first %.0f ms, then %.2f ms" % (t0*1000, (time.perf_counter()-t)/200*1000))
