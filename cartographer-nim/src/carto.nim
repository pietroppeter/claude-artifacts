## carto: a minimal Cartographer-style agentic wiki, in Nim.
##
## The core idea (after https://github.com/BeppeTemp/cartographer): agents never touch the
## knowledge base's files. They call tools on a small server, and the server owns every write:
## it validates the page, checks the agent read the latest version, and makes one git commit
## per write with the reason and the agent's name as trailers. Pages are Open Knowledge Format
## (OKF) concepts: Markdown with YAML frontmatter, where only `type` is required.
##
## Library use: `openKb`, `read`, `write`, `search`, `neighbors`, `history`, `lint`.
## Command line: `carto init <dir>` and `carto serve --kb <dir> [--repo name=path ...]`,
## which speaks MCP (JSON-RPC 2.0, one message per line) on stdin/stdout.

import std/[os, osproc, strutils, strformat, tables, json, sets, algorithm, sequtils, times, streams]

type
  Meta* = OrderedTable[string, string]
  Concept* = object
    id*: string        ## path under data/, without .md: the page's stable identity
    meta*: Meta        ## flat frontmatter: `key: value`, lists written as `[a, b]`
    body*: string
  Kb* = object
    root*: string
    repos*: Table[string, string]  ## code repos the pages cite: name -> local checkout
  KbError* = object of CatchableError
    code*: string

const reserved = ["index", "log", "_map", "agents"]

proc refuse(code, msg: string) {.noreturn.} =
  var e = newException(KbError, msg)
  e.code = code
  raise e

# ---------------------------------------------------------------- pages

proc parseConcept*(id, text: string): Concept =
  result.id = id
  let t = text.replace("\r\n", "\n")
  if not t.startsWith("---\n"):
    result.body = t
    return
  let close = t.find("\n---\n", 3)
  if close < 0: refuse("bad_frontmatter", &"{id}: frontmatter is not closed")
  for line in t[4 ..< close].splitLines:
    if line.strip.len == 0 or line.strip.startsWith("#"): continue
    if line[0] in {' ', '\t', '-'}:
      refuse("nested_frontmatter", &"{id}: only flat `key: value` frontmatter is accepted")
    let i = line.find(':')
    if i <= 0: refuse("bad_frontmatter", &"{id}: cannot parse `{line}`")
    result.meta[line[0 ..< i].strip] = line[i+1 .. ^1].strip
  result.body = t[close + 5 .. ^1]

proc render*(c: Concept): string =
  result = "---\n"
  for k, v in c.meta: result.add &"{k}: {v}\n"
  result.add "---\n" & c.body

proc list*(v: string): seq[string] =
  ## `[a, b]` -> @["a", "b"]; `a` -> @["a"]
  let v = v.strip
  if v.len == 0: return
  if v.startsWith("[") and v.endsWith("]"):
    for x in v[1 .. ^2].split(','):
      if x.strip.len > 0: result.add x.strip
  else: result.add v

proc links*(body: string): seq[string] =
  ## Outgoing links: wiki links `[[id]]` and bundle-relative Markdown links `[text](/id)`.
  var i = 0
  while (let a = body.find("[[", i); a >= 0):
    let b = body.find("]]", a)
    if b < 0: break
    result.add body[a+2 ..< b].split('|')[0].strip
    i = b + 2
  i = 0
  while (let a = body.find("](/", i); a >= 0):
    let b = body.find(')', a)
    if b < 0: break
    var t = body[a+3 ..< b].split('#')[0]
    if t.endsWith(".md"): t.setLen(t.len - 3)
    result.add t
    i = b + 1
  result = result.deduplicate

# ---------------------------------------------------------------- the store

proc dataDir(kb: Kb): string = kb.root / "data"
proc pathOf(kb: Kb, id: string): string = kb.dataDir / id & ".md"
proc exists*(kb: Kb, id: string): bool = fileExists(kb.pathOf(id))

proc run(dir: string, args: openArray[string], allowFail = false): string =
  let p = startProcess("git", workingDir = dir, args = @args,
                       options = {poUsePath, poStdErrToStdOut})
  result = p.outputStream.readAll
  let code = p.waitForExit
  p.close
  if code != 0 and not allowFail:
    refuse("git_error", "git " & args.join(" ") & ": " & result.strip)

proc git(kb: Kb, args: varargs[string]): string = run(kb.root, args)

proc etag*(kb: Kb, id: string): string =
  ## The page's git blob id. An agent must send back the etag it read to write a page.
  if kb.exists(id): kb.git("hash-object", kb.pathOf(id)).strip else: ""

proc ids*(kb: Kb): seq[string] =
  for f in walkDirRec(kb.dataDir, relative = true):
    let (dir, name, ext) = f.splitFile
    if ext == ".md" and name notin ["index", "log", "_map"]:
      result.add (if dir.len > 0: dir & "/" & name else: name)
  result.sort

proc read*(kb: Kb, id: string): Concept =
  if not kb.exists(id): refuse("not_found", &"no page `{id}`")
  parseConcept(id, readFile(kb.pathOf(id)))

proc mapFor*(kb: Kb, id: string): Concept =
  ## The nearest enclosing `_map.md`: a folder's contract (allowed types, required fields).
  var dir = id.parentDir
  while dir.len > 0 and dir != ".":
    let p = kb.dataDir / dir / "_map.md"
    if fileExists(p): return parseConcept(dir & "/_map", readFile(p))
    dir = dir.parentDir

proc now(): string = getEnv("CARTO_NOW", $times.now().utc.format("yyyy-MM-dd'T'HH:mm:ss'Z'"))

proc regenIndex(kb: Kb) =
  ## OKF reserves index.md for a listing of the bundle. Here it is a projection, rebuilt on every write.
  var groups = initOrderedTable[string, seq[string]]()
  for id in kb.ids:
    let c = kb.read(id)
    let g = if '/' in id: id.split('/')[0] else: "(top)"
    let (title, typ, desc) = (c.meta.getOrDefault("title", id), c.meta.getOrDefault("type"),
                              c.meta.getOrDefault("description"))
    groups.mgetOrPut(g, @[]).add strip(&"- [{title}](/{id}) · `{typ}` {desc}")
  var s = "# Index\n\nGenerated by the server on every write. Do not edit.\n"
  for g, lines in groups: s.add &"\n## {g}\n\n" & lines.join("\n") & "\n"
  writeFile(kb.dataDir / "index.md", s)

proc logEntry(kb: Kb, line: string) =
  ## OKF's log.md: date headings (YYYY-MM-DD), newest first. Entries are only ever added.
  let p = kb.dataDir / "log.md"
  let day = now()[0 ..< 10]
  var t = if fileExists(p): readFile(p) else: "# Log\n"
  let head = &"\n## {day}\n\n"
  let at = t.find(head)
  if at >= 0: t.insert("- " & line & "\n", at + head.len)
  else: t.insert(head & "- " & line & "\n", t.find('\n') + 1)
  writeFile(p, t)

proc commit(kb: Kb, subject, reason, agent: string) =
  discard kb.git("add", "-A", "data")
  discard kb.git("-c", "user.name=carto", "-c", "user.email=carto@localhost", "commit", "-q",
                 "-m", subject, "-m", &"Reason: {reason}\nAgent: {agent}")

proc initKb*(root: string): Kb =
  result = Kb(root: root)
  createDir(root / "data")
  if not dirExists(root / ".git"): discard run(root, ["init", "-q", "-b", "main"])
  result.logEntry("kb_create")
  result.regenIndex
  result.commit("kb_create", "new knowledge base", "carto")

proc openKb*(root: string, repos = initTable[string, string]()): Kb =
  if not dirExists(root / "data"): refuse("not_a_kb", &"{root} has no data/ folder")
  Kb(root: root, repos: repos)

# ---------------------------------------------------------------- validation

proc validId(id: string): bool =
  let segs = id.split('/')
  if segs.len notin 1..3: return false
  for s in segs:
    if s.len == 0 or s[0] == '-' or s[^1] == '-' or "--" in s: return false
    if not s.allIt(it in {'a'..'z', '0'..'9', '-'}): return false
  segs[^1] notin reserved

proc problems*(kb: Kb, c: Concept, pending = initHashSet[string]()): seq[string] =
  ## Everything wrong with a page, as `code: message` lines. Empty means it may be written.
  if not validId(c.id):
    result.add &"invalid_id: `{c.id}` must be 1-3 kebab-case segments and not a reserved name"
  for k, v in c.meta:
    if not k.allIt(it in {'a'..'z', '0'..'9', '_'}): result.add &"bad_key: `{k}`"
    if '\n' in v: result.add &"nested_frontmatter: `{k}` spans lines"
  let typ = c.meta.getOrDefault("type")
  if typ.len == 0: result.add "missing_type: OKF requires a `type` in the frontmatter"
  let m = kb.mapFor(c.id)
  if m.meta.len > 0:
    let allowed = m.meta.getOrDefault("concept_types").list
    if allowed.len > 0 and typ.len > 0 and typ notin allowed:
      let names = allowed.join(", ")
      result.add &"type_not_allowed: `{m.id}` takes {names}, not {typ}"
    for f in m.meta.getOrDefault("required_fields").list:
      if c.meta.getOrDefault(f).len == 0: result.add &"missing_field: `{m.id}` requires `{f}`"
    if m.meta.getOrDefault("kind") == "journal":
      let n = c.id.split('/')[^1]
      if n.len < 11 or n[4] != '-' or n[7] != '-' or n[10] != '-':
        result.add &"journal_name: pages in `{m.id}` are named YYYY-MM-DD-slug"
  for l in c.body.links:
    if not kb.exists(l) and l notin pending: result.add &"broken_link: `{l}` does not exist"

# ---------------------------------------------------------------- provenance across repos

proc pin(kb: Kb, src: string): string =
  ## `repo:path` -> `repo:path@<blob>`: the version of the code file this page was written from.
  if '@' in src or ':' notin src: return src
  let (repo, path) = (src.split(':', 1)[0], src.split(':', 1)[1])
  if repo notin kb.repos: refuse("unknown_repo", &"`{repo}` is not a registered repo")
  let blob = run(kb.repos[repo], ["rev-parse", "HEAD:" & path], allowFail = true).strip
  if blob.len != 40: refuse("unknown_source", &"`{path}` is not committed in `{repo}`")
  &"{src}@{blob[0 ..< 7]}"

# ---------------------------------------------------------------- writing

proc write*(kb: Kb, c: Concept, ifMatch = "", reason = "", agent = "unknown"): string =
  ## The only way a page changes. Refuses with a code, or commits and returns the new etag.
  let cur = kb.etag(c.id)
  if cur != ifMatch:
    if ifMatch.len == 0:
      refuse("stale_write", &"`{c.id}` already exists (etag {cur[0 ..< 7]}); read it and pass its etag as if_match")
    if cur.len == 0: refuse("stale_write", &"`{c.id}` does not exist; create it with an empty if_match")
    refuse("stale_write", &"`{c.id}` changed since you read it (now {cur[0 ..< 7]}); read it again and merge")
  let ps = kb.problems(c)
  if ps.len > 0: refuse(ps[0].split(':')[0], ps.join("\n"))
  var c = c
  if "sources" in c.meta:
    c.meta["sources"] = "[" & c.meta["sources"].list.mapIt(kb.pin(it)).join(", ") & "]"
  let text = c.render
  let back = parseConcept(c.id, text)   # what we write must read back identically
  if back.meta != c.meta or back.body != c.body: refuse("round_trip", &"`{c.id}` does not survive a re-read")
  createDir(kb.pathOf(c.id).parentDir)
  writeFile(kb.pathOf(c.id), text)
  let verb = if cur.len == 0: "concept_new" else: "concept_write"
  kb.logEntry(&"{verb} [{c.id}](/{c.id}) by {agent}: {reason}")
  kb.regenIndex
  kb.commit(&"{verb}: {c.id}", reason, agent)
  kb.etag(c.id)

proc mapCreate*(kb: Kb, dir: string, meta: Meta, reason = "", agent = "operator") =
  ## Folder contracts are set by people, not agents: there is deliberately no MCP tool for this.
  if not validId(dir): refuse("invalid_id", &"`{dir}` is not a valid folder name")
  createDir(kb.dataDir / dir)
  writeFile(kb.dataDir / dir / "_map.md", Concept(id: dir & "/_map", meta: meta, body: "").render)
  kb.logEntry(&"map_create {dir} by {agent}: {reason}")
  kb.regenIndex
  kb.commit(&"map_create: {dir}", reason, agent)

# ---------------------------------------------------------------- reading

proc search*(kb: Kb, q: string, n = 5): seq[(int, string)] =
  ## Keyword search. Like Cartographer, no embeddings: the index is a disposable projection.
  let words = q.toLowerAscii.splitWhitespace
  for id in kb.ids:
    let c = kb.read(id)
    let title = c.meta.getOrDefault("title").toLowerAscii
    let desc = c.meta.getOrDefault("description").toLowerAscii & " " & c.meta.getOrDefault("tags").toLowerAscii
    let body = c.body.toLowerAscii
    var score = 0
    for w in words: score += 3 * title.count(w) + 2 * desc.count(w) + body.count(w) + (if w in id: 3 else: 0)
    if score > 0: result.add (score, id)
  result.sort(SortOrder.Descending)
  if result.len > n: result.setLen(n)

proc neighbors*(kb: Kb, id: string): tuple[outgoing, incoming: seq[string]] =
  result.outgoing = kb.read(id).body.links
  for other in kb.ids:
    if other != id and id in kb.read(other).body.links: result.incoming.add other

proc history*(kb: Kb, id: string): seq[string] =
  let f = "data/" & id & ".md"
  for l in kb.git("log", "--format=%h %s · %(trailers:key=Agent,valueonly,separator=%x2C) · " &
                  "%(trailers:key=Reason,valueonly,separator=%x2C)", "--", f).splitLines:
    if l.len > 0: result.add l

proc lint*(kb: Kb): seq[string] =
  ## Health of the whole KB, including damage done around the server (hand edits),
  ## and pages whose cited code has moved on since they were written.
  for l in kb.git("status", "--porcelain", "-uall", "--", "data").splitLines:
    if l.len > 3: result.add &"edited_outside: {l[3 .. ^1]} changed without going through the server"
  var inbound = initCountTable[string]()
  let all = kb.ids
  for id in all:
    var c: Concept
    try: c = kb.read(id)
    except KbError as e:
      result.add &"{id}: {e.msg}"; continue
    for p in kb.problems(c): result.add &"{id}: {p}"
    for l in c.body.links: inbound.inc l
    let review = c.meta.getOrDefault("review_after")
    if review.len >= 10 and review[0 ..< 10] < now()[0 ..< 10]:
      result.add &"{id}: review_due: review_after {review} has passed"
    for s in c.meta.getOrDefault("sources").list:
      let at = s.rfind('@')
      if at < 0 or ':' notin s: continue
      let (repo, path) = (s[0 ..< at].split(':', 1)[0], s[0 ..< at].split(':', 1)[1])
      if repo notin kb.repos: result.add &"{id}: unknown_repo: `{repo}`"; continue
      let blob = run(kb.repos[repo], ["rev-parse", "HEAD:" & path], allowFail = true).strip
      if blob.len != 40: result.add &"{id}: source_gone: {repo}:{path} no longer exists"
      elif not blob.startsWith(s[at+1 .. ^1]):
        result.add &"{id}: source_drift: {repo}:{path} changed since this page was written"
  for id in all:
    if inbound[id] == 0 and '/' in id: result.add &"{id}: orphan: no page links here"

proc guide*(kb: Kb): string =
  result = "This knowledge base is written only through these tools. Pages are OKF concepts: " &
    "Markdown with flat YAML frontmatter; `type` is required. Read a page before writing it and " &
    "pass its etag as if_match. Link pages with [[id]]. Cite code with sources: [repo:path].\n\nFolders:\n"
  for f in walkDirRec(kb.dataDir, relative = true):
    if f.extractFilename == "_map.md":
      let m = parseConcept(f, readFile(kb.dataDir / f))
      let (kind, types, req) = (m.meta.getOrDefault("kind", "map"),
        m.meta.getOrDefault("concept_types", "any"), m.meta.getOrDefault("required_fields", "none"))
      result.add &"- {f.parentDir} ({kind}): types {types}, required {req}\n"
  if kb.repos.len > 0: result.add "\nRepos: " & toSeq(kb.repos.keys).sorted.join(", ") & "\n"

# ---------------------------------------------------------------- MCP over stdio

proc prop(desc: string, typ = "string"): JsonNode = %*{"type": typ, "description": desc}

proc tools*(): JsonNode =
  proc tool(name, desc: string, props: JsonNode, req: seq[string] = @[], ro = true): JsonNode =
    %*{"name": name, "description": desc,
       "inputSchema": {"type": "object", "properties": props, "required": req},
       "annotations": {"readOnlyHint": ro}}
  %*[
    tool("kb_guide", "Conventions and folder contracts. Call this first.", newJObject()),
    tool("concept_read", "Read a page: frontmatter, body and etag.", %*{"id": prop("page id")}, @["id"]),
    tool("concept_write", "Create or replace a page. Validated, then one git commit.",
         %*{"id": prop("page id, e.g. teams/payments/retry-policy"),
            "frontmatter": prop("flat key -> string map; `type` is required", "object"),
            "body": prop("Markdown body"),
            "if_match": prop("etag from concept_read; empty to create"),
            "reason": prop("why, for the commit message")},
         @["id", "frontmatter", "body", "if_match", "reason"], ro = false),
    tool("search", "Keyword search over titles, descriptions and bodies.", %*{"query": prop("words")}, @["query"]),
    tool("graph_neighbors", "Pages this page links to, and pages that link to it.", %*{"id": prop("page id")}, @["id"]),
    tool("concept_history", "Commits that touched a page, with agent and reason.", %*{"id": prop("page id")}, @["id"]),
    tool("lint", "Problems across the KB: broken links, orphans, hand edits, drifted sources.", newJObject())]

proc callTool*(kb: Kb, name: string, a: JsonNode, agent: string): string =
  case name
  of "kb_guide": kb.guide
  of "concept_read":
    let id = a["id"].getStr
    let c = kb.read(id)
    $(%*{"id": id, "etag": kb.etag(id), "frontmatter": c.meta, "body": c.body})
  of "concept_write":
    var c = Concept(id: a["id"].getStr, body: a["body"].getStr)
    for k, v in a["frontmatter"]: c.meta[k] = (if v.kind == JString: v.getStr else: $v)
    "written, etag " & kb.write(c, a["if_match"].getStr, a["reason"].getStr, agent)
  of "search": kb.search(a["query"].getStr).mapIt(&"{it[1]} (score {it[0]})").join("\n")
  of "graph_neighbors":
    let n = kb.neighbors(a["id"].getStr)
    "links to: " & n.outgoing.join(", ") & "\nlinked from: " & n.incoming.join(", ")
  of "concept_history": kb.history(a["id"].getStr).join("\n")
  of "lint": (let l = kb.lint; if l.len == 0: "clean" else: l.join("\n"))
  else: refuse("unknown_tool", name)

proc handle*(kb: Kb, msg: JsonNode, agent: var string): JsonNode =
  ## One JSON-RPC request in, one response out (nil for notifications).
  let meth = msg{"method"}.getStr
  if not msg.hasKey("id"): return nil
  var res: JsonNode
  case meth
  of "initialize":
    agent = msg{"params", "clientInfo", "name"}.getStr("unknown")
    res = %*{"protocolVersion": msg{"params", "protocolVersion"}.getStr("2025-06-18"),
             "capabilities": {"tools": {}},
             "serverInfo": {"name": "carto", "version": "0.1.0"},
             "instructions": "Call kb_guide first. You cannot edit files; every change goes through concept_write."}
  of "tools/list": res = %*{"tools": tools()}
  of "tools/call":
    try:
      res = %*{"content": [{"type": "text",
                            "text": kb.callTool(msg["params"]["name"].getStr,
                                                msg["params"]{"arguments"}, agent)}]}
    except KbError as e:
      let text = if e.msg.startsWith(e.code & ":"): "refused " & e.msg else: &"refused {e.code}: {e.msg}"
      res = %*{"content": [{"type": "text", "text": text}], "isError": true}
  of "ping": res = newJObject()
  else:
    return %*{"jsonrpc": "2.0", "id": msg["id"], "error": {"code": -32601, "message": "unknown method " & meth}}
  %*{"jsonrpc": "2.0", "id": msg["id"], "result": res}

proc serve*(kb: Kb, input = stdin, output = stdout) =
  var agent = "unknown"
  for line in input.lines:
    if line.strip.len == 0: continue
    let reply = kb.handle(parseJson(line), agent)
    if reply != nil:
      output.writeLine($reply)
      output.flushFile

when isMainModule:
  let args = commandLineParams()
  if args.len >= 2 and args[0] == "init":
    discard initKb(args[1])
    echo "created ", args[1]
  elif args.len >= 3 and args[0] == "serve" and args[1] == "--kb":
    var repos = initTable[string, string]()
    var i = 3
    while i + 1 < args.len and args[i] == "--repo":
      let kv = args[i+1].split('=', 1)
      repos[kv[0]] = kv[1].absolutePath
      i += 2
    openKb(args[2].absolutePath, repos).serve
  else:
    quit "usage: carto init <dir> | carto serve --kb <dir> [--repo name=path ...]"
