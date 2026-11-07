# capi.nim: the Nim side, before any plug
proc draw(req: JsonNode): JsonNode
  ## req:    {"source": "<Mermaid text>", "layer": {...}, "options": {...}}
  ## answer: {"ok": true, "svg": "<svg ...>", "type": "flowchart",
  ##          "ids": {"nodes": [...], "edges": [...]}}
  ##   or:   {"ok": false, "code": "syntax", "message": "...",
  ##          "line": 2, "column": 9, "snippet": "..."}
