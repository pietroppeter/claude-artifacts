import shutil, time, mari

print("node on PATH:", shutil.which("node"), "| engine:", mari.engine())
src = """flowchart LR
  idea[Idea] --> draft(Draft)
  draft --> review{Review?}
  review -->|yes| ship((Ship))
  review -.->|no| draft"""
d = mari.Diagram(src)
t = time.perf_counter(); plain = d.svg; t1 = time.perf_counter() - t
print("Pele", mari.pele_version(), "drew", len(plain), "bytes of SVG in", f"{t1*1000:.0f} ms (first call loads Pele)")
print("ids:", d.ids())
d.layer = {"theme": "isotype", "arrows": "curve",
           "nodes": {"ship": {"dy": 120, "fill": "#c8402b"}},
           "edges": {"L_review_draft_0": {"route": "bezier", "c1": [-30, -80], "c2": [30, -80]}}}
t = time.perf_counter(); d.save("personal.svg"); t2 = time.perf_counter() - t
open("plain.svg", "w").write(plain)
print("with the layer:", f"{t2*1000:.1f} ms")
try:
    mari.Diagram("flowchart LR\n  a --> [").svg
except mari.DiagramError as e:
    print("DiagramError:", e.code, "at", f"{e.line}:{e.column}")
