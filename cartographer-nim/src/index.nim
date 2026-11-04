import std/[json, os, osproc, strutils, strformat, tables, streams, sequtils]
import nimib
import style
import carto

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.doc.context["title"] = %"Cartographer, in Nim"
nb.doc.context["stylesheet"] = %pageStyle
nb.doc.context["highlight"] = %""
nb.doc.context["disableHighlightJs"] = %true
func pageHeader(blk: JsonNode, nb: Nb): string =
  """<header><span>a nimib notebook</span><span>written 2026-11-04</span></header>"""
nb.backend.partials["header"] = pageHeader

# Show a proc from carto.nim, so the excerpts can't drift from the code that ran.
let cartoSrc = readFile(currentSourcePath().parentDir / "carto.nim").splitLines
proc excerpt(names: varargs[string]): string =
  var parts: seq[string]
  for name in names:
    var i = 0
    while i < cartoSrc.len and not cartoSrc[i].startsWith("proc " & name & "*") and
          not cartoSrc[i].startsWith("proc " & name & "("):
      inc i
    doAssert i < cartoSrc.len, "no proc " & name
    var lines = @[cartoSrc[i]]
    inc i
    while i < cartoSrc.len and (cartoSrc[i].len == 0 or cartoSrc[i].startsWith(" ")):
      lines.add cartoSrc[i]
      inc i
    while lines[^1].len == 0: discard lines.pop
    parts.add lines.join("\n")
  "```nim\n" & parts.join("\n\n") & "\n```\n"

# Fixed clock: commit ids and the log are the same on every build.
putEnv("CARTO_NOW", "2026-11-04T12:00:00Z")
putEnv("GIT_AUTHOR_DATE", "2026-11-04T12:00:00Z")
putEnv("GIT_COMMITTER_DATE", "2026-11-04T12:00:00Z")
let work = getTempDir() / "carto-demo"
removeDir(work)
createDir(work)

nbRawHtml: """
<h1>Cartographer, <em>in Nim</em></h1>
<p class="lede">Your team's coding agents each learn things and forget them. Cartographer gives them one shared wiki
they can all read and grow, but can't break. This page studies it, rebuilds its core in about 400 lines of Nim,
compares it with the alternatives, and asks whether it fits a project with many repos and many teams.</p>
"""

nbRawHtml: """
<div class="verdict">
<h3>The short answer</h3>
<p><b>The idea is a good fit for a multi-repo, multi-team project. Cartographer itself is worth a pilot, not a rollout.</b>
The pattern it builds on (an LLM-maintained Markdown wiki, stored in the Open Knowledge Format) is cheap to adopt and easy to
leave, because the knowledge is plain files in git. What Cartographer adds is a server that refuses bad writes and records
who changed what and why. That matters most when several teams' agents write to the same knowledge. Against it: it's a
pre-1.0 personal project with one maintainer, and it gives you a server to run.</p>
<p><b>And yes, "OKF LLMWiki" is the same family.</b> <i>LLM Wiki</i> is Andrej Karpathy's pattern (April 2026), and <i>OKF</i> is
Google Cloud's Open Knowledge Format (June 2026), which formalizes that pattern as a file format. Cartographer says it combines the two.
I couldn't find a single product called "OKF LLMWiki". The closest match is a small demo repo, <a href="https://github.com/real-jiakai/okf_llm_wiki">okf_llm_wiki</a>,
which lays the same knowledge out both ways. <a href="#fit">Jump to the fit analysis</a>.</p>
</div>
"""

nbRawHtml: """<h2><span class="num">01 · WHAT IT IS</span>Cartographer in one picture</h2>"""

nbText: """
[Cartographer](https://github.com/BeppeTemp/cartographer) is "a shared, git-backed wiki your team's AI agents maintain but can't break —
Claude Code, Codex, OpenCode and any MCP client." It is one Go binary, Apache-2.0, by GitHub user BeppeTemp, and it describes itself as
"Pre-1.0" and "a personal project maintained on a best-effort basis". When I read it, the repo had 924 commits and 54 stars.

Its README names three fixes teams usually try, and says why each falls short:

- **RAG** "retrieves, but nothing accumulates."
- **A folder of Markdown the agent edits freely** ends in "broken links, lost history and silent corruption."
- **Skills and instructions** "get hand-copied into `.claude/`, `.codex/`, `.kiro/`… and drift apart."

Its answer is one rule: *"The agent uses MCP tools; the server owns filesystem writes and validation."*
Agents never open the files. They call tools such as `concept_read` and `concept_write`, and the server checks every write before
it lands. Each write becomes one git commit, so nothing is lost and every change can be traced.
"""

nbRawHtml: """
<svg class="flow" viewBox="0 0 760 270" role="img" aria-label="Agents call MCP tools on the server; the server validates and commits to a git repository of Markdown pages; agents cannot write the files directly.">
  <defs><marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="ah"/></marker></defs>
  <rect class="box" x="6" y="20" width="190" height="44" rx="8"/><text x="101" y="47" text-anchor="middle">Claude Code · team A</text>
  <rect class="box" x="6" y="80" width="190" height="44" rx="8"/><text x="101" y="107" text-anchor="middle">Codex · team B</text>
  <rect class="box" x="6" y="140" width="190" height="44" rx="8"/><text x="101" y="167" text-anchor="middle">any MCP client</text>
  <path class="arrow" d="M198 42 L300 92"/><path class="arrow" d="M198 102 L300 102"/><path class="arrow" d="M198 162 L300 112"/>
  <text class="mono muted" x="222" y="62">MCP tools</text>
  <rect class="srv" x="302" y="50" width="190" height="110" rx="12"/>
  <text class="srv-t" x="397" y="80" text-anchor="middle" font-weight="600">server</text>
  <text class="mono srv-t" x="397" y="102" text-anchor="middle">validate · if_match</text>
  <text class="mono srv-t" x="397" y="120" text-anchor="middle">one commit per write</text>
  <text class="mono srv-t" x="397" y="138" text-anchor="middle">index · log · lint</text>
  <path class="arrow" d="M494 105 L590 105"/>
  <rect class="box" x="592" y="40" width="160" height="130" rx="8"/>
  <text x="672" y="64" text-anchor="middle" font-weight="600">git repo</text>
  <text class="mono" x="606" y="88">data/</text>
  <text class="mono" x="618" y="106">index.md</text>
  <text class="mono" x="618" y="124">log.md</text>
  <text class="mono" x="618" y="142">services/…md</text>
  <text class="mono" x="618" y="160">teams/…md</text>
  <path class="no" d="M101 186 C 101 240, 672 240, 672 172"/>
  <text class="no-t mono" x="386" y="258" text-anchor="middle">✗ agents never write the files directly</text>
</svg>
"""

nbText: """
Beyond that core, the docs describe a lot of surrounding machinery. I read the
[README](https://github.com/BeppeTemp/cartographer), [overview](https://github.com/BeppeTemp/cartographer/blob/main/docs/overview.md),
[FAQ](https://github.com/BeppeTemp/cartographer/blob/main/docs/faq.md),
[data plane](https://github.com/BeppeTemp/cartographer/blob/main/docs/data-plane.md) and
[control plane](https://github.com/BeppeTemp/cartographer/blob/main/docs/control-plane.md) docs:

- **Layout.** An *Atlas* is one knowledge base (KB) and one git repo. Under `data/` are *Maps*, which are thematic folders, and *Journals*, which hold dated
  pages named `YYYY-MM-DD-slug`. Each page is a *Concept*. A folder's `_map.md` can declare a contract: which `concept_types`
  are allowed and which `required_fields` each page needs. A page's id is its path, and that id is its identity.
- **Beyond knowledge.** The same repo also holds `skills/`, `agents/` (subagents), `hooks/`, `mcp/` descriptors, SOPS-encrypted `secrets/`
  and `instructions.md`. `cartographer sync` installs them into each client, so every agent on the team is configured from one place.
- **Tools.** About 60 MCP tools covering reading, keyword search (the docs say "keyword search only"), writes (including an atomic
  `concept_batch`), graph queries (personalized PageRank), governance (`validate`, `lint`, `kb_review`, `gate_check`), ingest and conflicts.
- **Teams.** One HTTP server can serve several KBs, with bearer tokens scoped per KB and per map (`kb:<name>:r` or `rw`). Commits carry
  `Reason:`, `Agent:` and author trailers. When two machines' changes conflict, the KB is marked `degraded` and someone must pick `ours`,
  `theirs` or `edit` for each page. The FAQ says: "It is not a silent last-write-wins."
- **Its own limits, as stated.** Search has no model-backed mode, sync is "not atomic across clients", and: *"If your knowledge fits in
  one repository and one person, a plain instruction file is simpler and you should use it."*

I couldn't open the project site [beppetemp.github.io/cartographer](https://beppetemp.github.io/cartographer/) from my sandbox
because the network policy blocked it. Everything above comes from the GitHub repo and its `docs/` folder. I didn't read the
changelog, the decision records or the sync and concurrency docs.
"""

nbRawHtml: """<h2><span class="num">02 · WHERE IT COMES FROM</span>LLM Wiki + OKF, the "OKF LLMWiki" question</h2>"""

nbText: """
Cartographer's overview says it combines "Karpathy's LLM Wiki pattern" with "Google's Open Knowledge Format (OKF)". Both are recent:

**LLM Wiki** ([Karpathy's gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f), created April 4, 2026) is "an idea file":
instead of RAG re-deriving answers from raw documents on every question, an LLM "incrementally builds and maintains a persistent wiki",
so "the wiki is a persistent, compounding artifact." It has three layers: **raw sources**, which are immutable; **the wiki**; and **the schema**, a
`CLAUDE.md` or `AGENTS.md` that tells the agent the rules. It also has three operations: **ingest**, **query** and **lint**. Two files
are special. `index.md` is a catalog the agent reads first, and `log.md` is an "append-only record of what happened and when".

**OKF** ([Google Cloud blog, June 12, 2026](https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing))
is "an open specification that formalizes the LLM-wiki pattern". The [spec](https://github.com/GoogleCloudPlatform/open-knowledge-format),
now at v0.2, is short: a bundle is "a directory of markdown files with YAML frontmatter", and `type` "is the only always-required key".
`index.md` and `log.md` are reserved. Links are paths relative to the bundle that start with `/`. Consumers "MUST tolerate broken links".
That last point is where Cartographer goes further: it validates a bundle on every write, so it is stricter than OKF requires.

So **"OKF LLMWiki" names the same family of ideas**: the LLM Wiki is the workflow, and OKF is the file format. That phrasing comes from
[real-jiakai/okf_llm_wiki](https://github.com/real-jiakai/okf_llm_wiki), a 5-star demo that organizes one knowledge base both ways.
I found no product by that exact name. If you saw it somewhere specific, send me the link and I'll check whether it's something else.
"""

nbRawHtml: """<h2><span class="num">03 · THE MINIMAL VERSION</span>carto.nim: the core, in one file</h2>"""

nbText: """
To understand the idea, I rebuilt the part that makes Cartographer more than "a folder of Markdown": **a server that owns the writes**.
[`carto.nim`](https://github.com/pietroppeter/claude-artifacts/blob/main/cartographer-nim/src/carto.nim) is one file with no dependencies
beyond the Nim standard library and the `git` command. It keeps these parts:

| Cartographer idea | in `carto.nim` |
|---|---|
| OKF pages: Markdown + frontmatter, `type` required | `parseConcept`, `render`, round-trip check on every write |
| Agents use tools; the server owns the files | `write` is the only way a page changes |
| Folder contracts in `_map.md` (`concept_types`, `required_fields`, journals) | `mapFor`, `problems`; `mapCreate` is for people only, with no tool for agents |
| Optimistic concurrency, `stale_write` | the etag is the page's git blob id; `if_match` must match |
| One git commit per write, with `Reason:` and `Agent:` trailers | `commit`, `history` |
| `index.md` + `log.md` (OKF reserved files) | regenerated on every write; log is newest first |
| Keyword search, links graph, lint | `search`, `neighbors`, `lint` |
| MCP server | `carto serve`: JSON-RPC 2.0 over stdio, 7 tools |

I also added one thing aimed at a multi-repo project, which **I didn't find in Cartographer's docs**. A page can cite code with
`sources: [repo:path]`. The server pins each source to the file's current git blob, and `lint` reports `source_drift` once that code
changes. Documentation that silently goes stale is the main way a knowledge base dies across many repos.

Here is the write path. Everything else in the file supports it:
""" & excerpt("write")

nbText: """
The checks it runs come from `problems`. These are the same checks `lint` later runs over the whole KB:
""" & excerpt("problems")

nbRawHtml: """<h2><span class="num">04 · A WALKTHROUGH</span>Two teams, two repos, one knowledge base</h2>"""

nbText: """
Everything below ran while this page was built. Each output is what the code printed. The setup is a small version of a
multi-team project: a `payments-api` repo, a `web-checkout` repo, and one knowledge base they share.
"""

nbCode:
  proc sh(dir, cmd: string) =
    let (outp, code) = execCmdEx(cmd, workingDir = dir)
    doAssert code == 0, cmd & ": " & outp

  # two code repos, as two teams would have them
  for (repo, file, text) in [("payments-api", "openapi.yaml", "paths:\n  /charges: {post: {}}\n"),
                             ("web-checkout", "src/pay.ts", "export const retries = 3\n")]:
    createDir(work / repo / file.parentDir)
    writeFile(work / repo / file, text)
    sh(work / repo, "git init -q -b main && git add -A && " &
                    "git -c user.name=dev -c user.email=dev@x commit -qm init")

  # the knowledge base, and the folder contracts people agree on
  var kb = initKb(work / "kb-platform")
  kb.repos = {"payments-api": work / "payments-api",
              "web-checkout": work / "web-checkout"}.toTable
  kb.mapCreate("services", {"kind": "map", "concept_types": "[Service]",
                            "required_fields": "[owner, sources]"}.toOrderedTable, "one page per deployable")
  kb.mapCreate("teams", {"kind": "map", "concept_types": "[Runbook, Reference, Note]",
                         "required_fields": "[owner]"}.toOrderedTable, "team-owned know-how")
  kb.mapCreate("decisions", {"kind": "journal", "concept_types": "[Decision]",
                             "required_fields": "[status]"}.toOrderedTable, "cross-team decisions")
  echo kb.guide

nbText: """
`kb_guide` is the first thing an agent reads. Now an agent, Claude Code on the payments team, writes the first page.
A small helper builds pages and reports refusals:
"""

nbCode:
  proc page(id: string, meta: openArray[(string, string)], body: string): Concept =
    Concept(id: id, meta: meta.toOrderedTable, body: body)

  proc attempt(kb: Kb, c: Concept, reason: string, ifMatch = "", agent = "claude-code"): string =
    try:
      result = kb.write(c, ifMatch, reason, agent)
      echo "✓ ", reason, "  (etag ", result[0 ..< 7], ")"
    except KbError as e:
      let msg = if e.msg.startsWith(e.code & ":"): e.msg else: e.code & ": " & e.msg
      echo "✗ ", reason, "\n    refused ", msg.replace("\n", "\n    refused ")

  var svc = page("services/payments-api",
    {"type": "Service", "title": "Payments API", "owner": "team-payments",
     "description": "Charges, refunds and idempotency for every checkout.",
     "sources": "[payments-api:openapi.yaml]"},
    "# Payments API\n\nPublic contract: `POST /charges`. Owned by team-payments.\n")
  let svcTag = kb.attempt(svc, "document the payments service")
  echo readFile(work / "kb-platform/data/services/payments-api.md")

nbText: """
The server pinned the source to `@<blob>`, the exact version of `openapi.yaml` the page describes.
Next come the writes a careless agent would make. Each one is refused with a code the agent can act on:
"""

nbCode:
  discard kb.attempt(page("teams/payments/retries", {"title": "Retries"}, "Retry 3 times."),
                     "no type")
  discard kb.attempt(page("services/retry-howto", {"type": "Runbook", "owner": "team-payments"}, "…"),
                     "a runbook in the services folder")
  discard kb.attempt(page("teams/checkout/retries", {"type": "Runbook"}, "Retry 3 times."),
                     "a team page with no owner")
  discard kb.attempt(page("teams/checkout/retries", {"type": "Runbook", "owner": "team-checkout"},
                          "Follow [[teams/payments/idempotency]] first."),
                     "a link to a page that doesn't exist")
  discard kb.attempt(page("decisions/idempotency-keys", {"type": "Decision", "status": "accepted"}, "…"),
                     "a journal entry without a date")
  discard kb.attempt(page("services/payments-api", {"type": "Service", "owner": "x", "sources": "[a:b]"}, "…"),
                     "create the payments page again, without reading it", agent = "codex")

nbText: """
The last one is the important case for teams. You can't create a page that already exists or overwrite one you haven't read.
Two agents on two teams now work on the same page at the same time:
"""

nbCode:
  # both agents read the page at the same version
  let seenByCodex = kb.etag("services/payments-api")
  var c1 = kb.read("services/payments-api")

  # checkout's Claude records a decision, writes a runbook, and links them from the service page
  discard kb.attempt(page("decisions/2026-10-30-idempotency-keys",
    {"type": "Decision", "title": "Idempotency keys on every charge", "status": "accepted",
     "description": "Clients send Idempotency-Key; the API dedupes for 24h."},
    "Agreed by payments and checkout. Affects [[services/payments-api]].\n"),
    "record the idempotency decision")
  discard kb.attempt(page("teams/checkout/retries",
    {"type": "Runbook", "title": "Retrying a failed payment", "owner": "team-checkout",
     "sources": "[web-checkout:src/pay.ts]"},
    "Retry up to 3 times with the same key, see [[decisions/2026-10-30-idempotency-keys]].\n"),
    "write the checkout retry runbook")
  c1.body.add "\nDecisions: [[decisions/2026-10-30-idempotency-keys]]. Client retries: [[teams/checkout/retries]].\n"
  discard kb.attempt(c1, "link decision and runbook", svcTag)

  # codex, still holding the old version, tries to add its own line
  var c2 = page("services/payments-api", toSeq(kb.read("services/payments-api").meta.pairs), svc.body & "\nRate limit: 100 rps.\n")
  discard kb.attempt(c2, "add rate limit", seenByCodex, agent = "codex")
  # it re-reads, merges its change into the current page, and tries again
  var merged = kb.read("services/payments-api")
  merged.body.add "\nRate limit: 100 rps.\n"
  discard kb.attempt(merged, "add rate limit", kb.etag("services/payments-api"), agent = "codex")

nbText: """
Nothing was silently lost. Every change is a commit that records which agent made it and why:
"""

nbCode:
  for line in kb.history("services/payments-api"): echo line
  echo ""
  echo readFile(work / "kb-platform/data/log.md")
  echo readFile(work / "kb-platform/data/index.md")

nbText: """
`search` and `neighbors` are what an agent uses to find its way around before it writes:
"""

nbCode:
  for (score, id) in kb.search("retry idempotency"): echo score, "  ", id
  let n = kb.neighbors("decisions/2026-10-30-idempotency-keys")
  echo "links to:    ", n.outgoing.join(", ")
  echo "linked from: ", n.incoming.join(", ")

nbText: """
### When something goes around the server

Someone (or some agent with shell access) edits the files directly. The server can't stop that, but `lint` notices,
and because every good state is a commit, recovery is a `git checkout`:
"""

nbCode:
  createDir(work / "kb-platform/data/teams/payments")
  writeFile(work / "kb-platform/data/teams/payments/scratch.md", "quick notes, no frontmatter\nsee [[nowhere]]\n")
  for l in kb.lint: echo l
  sh(work / "kb-platform", "git clean -fdq data && git checkout -q -- data")
  echo "after restore: ", (if kb.lint.len == 0: "clean" else: kb.lint.join("; "))

nbText: """
### When the code moves on

This is the multi-repo problem. The payments team changes its API, and nobody updates the wiki. Because the service page
pinned the blob of `openapi.yaml`, `lint` can tell:
"""

nbCode:
  writeFile(work / "payments-api/openapi.yaml", "paths:\n  /charges: {post: {}}\n  /refunds: {post: {}}\n")
  sh(work / "payments-api", "git -c user.name=dev -c user.email=dev@x commit -qam 'add refunds'")
  for l in kb.lint: echo l

nbText: """
Running that `lint` in each code repo's CI, or on a schedule, turns "the docs are stale" from a surprise into a work item.
An agent can pick it up: read the diff, update the page, and pass the new etag.
"""

nbRawHtml: """<h2><span class="num">05 · OVER MCP</span>What an agent actually sees</h2>"""

nbText: """
The same library behind `carto serve` speaks [MCP](https://modelcontextprotocol.io) over stdio: one JSON-RPC message per line.
This block compiles the binary, starts it, and talks to it the way Claude Code or Codex would.
"""

nbCode:
  let bin = work / "carto"
  let src = currentSourcePath().parentDir / "carto.nim"
  doAssert execCmd(&"nim c -d:release --hints:off --warnings:off -o:{bin} {src} > /dev/null") == 0
  let p = startProcess(bin, args = ["serve", "--kb", work / "kb-platform",
                                    "--repo", "payments-api=" & work / "payments-api"])
  var id = 0
  proc rpc(meth: string, params: JsonNode): JsonNode =
    inc id
    let req = %*{"jsonrpc": "2.0", "id": id, "method": meth, "params": params}
    p.inputStream.writeLine($req)
    p.inputStream.flush
    result = parseJson(p.outputStream.readLine)
  proc call(tool: string, args: JsonNode) =
    let r = rpc("tools/call", %*{"name": tool, "arguments": args})["result"]
    echo "→ ", tool, " ", $args
    echo (if r{"isError"}.getBool: "← ERROR " else: "← "), r["content"][0]["text"].getStr.replace("\n", "\n  "), "\n"

  let hello = rpc("initialize", %*{"protocolVersion": "2025-06-18", "clientInfo": {"name": "claude-code"}})
  echo "server: ", hello["result"]["serverInfo"], "\n"
  echo "tools:  ", rpc("tools/list", newJObject())["result"]["tools"].mapIt(it["name"].getStr).join(", "), "\n"
  call("search", %*{"query": "refunds"})
  call("concept_write", %*{"id": "teams/payments/refunds", "if_match": "", "reason": "doc refunds",
                           "frontmatter": {"type": "Reference"}, "body": "See [[services/payments-api]]."})
  call("concept_write", %*{"id": "teams/payments/refunds", "if_match": "", "reason": "document refunds",
                           "frontmatter": {"type": "Reference", "owner": "team-payments", "title": "Refunds"},
                           "body": "POST /refunds reverses a charge. See [[services/payments-api]].\n"})
  call("concept_history", %*{"id": "teams/payments/refunds"})
  p.inputStream.close
  discard p.waitForExit
  p.close

nbText: """
The agent gets a refusal it can fix (`missing_field`), fixes it, and the commit records `claude-code` as the agent.
The name comes from the client's `initialize` handshake. Connecting it to a real client takes one line of config, for example
`claude mcp add carto -- /path/to/carto serve --kb /path/to/kb-platform --repo payments-api=/path/to/payments-api`.
"""

nbRawHtml: """<h2><span class="num">06 · WHAT THE MINIMUM LEAVES OUT</span>Where the other 90% of Cartographer goes</h2>"""

nbText: """
`carto.nim` shows the core idea, and it leaves out most of what you'd need to run this for real teams. Here's what Cartographer
documents and this version skips:

- **A server for many people.** Cartographer has an HTTP mode with bearer tokens scoped per KB and per map, and serves several KBs
  from one process. `carto` is one local process per user. With git underneath, each person would run their own and push and pull,
  and then you need Cartographer's answer to conflicting merges (`degraded` state, `git_conflict_resolve`).
- **Atomic multi-page writes** (`concept_batch`). In the walkthrough, the decision, runbook and service page took three commits and
  had to be written in dependency order.
- **Agent configuration as knowledge.** Syncing `skills/`, `agents/`, `hooks/`, MCP descriptors and SOPS secrets into every client.
  For a team lead this may be the most useful part, because it stops each developer's `.claude/` from drifting.
- **Lifecycle and trust fields** (`status`, `superseded_by`, `confidence`, `provenance`), `supersede`, archive, review gates, the
  read-only web UI ("Atlas"), a graph ranked by personalized PageRank, and a signed audit log.
- **Ingest.** Registering sources and letting a planner decide where new knowledge goes.

The code-drift check goes the other way: it's my addition. I didn't find it in Cartographer's docs, though I didn't read
`changes_since` or the ingest docs in full.
"""

nbRawHtml: """<h2><span class="num">07 · ALTERNATIVES</span>What else solves this</h2>"""

nbText: """
The tools people reach for to give agents shared knowledge fall into four groups. For each one I checked the README or official
page on 2026-11-04. Star counts are rough and change quickly. Rows marked *unverified* are from memory, because my sandbox couldn't reach the site.
"""

nbRawHtml: """
<div class="table-wrap"><table>
<tr><th>Option</th><th>Store</th><th>Agents write?</th><th>Teams / many repos</th><th>Signal</th></tr>
<tr><td colspan="5"><b>Agent-maintained Markdown wikis</b> (same family as Cartographer)</td></tr>
<tr><td><a href="https://github.com/BeppeTemp/cartographer">Cartographer</a></td><td>OKF files in git</td><td>Only through validated MCP tools</td><td>Several KBs per server, scoped tokens, commit trailers, conflict flow</td><td>Apache-2.0, pre-1.0, 1 maintainer, ~54★</td></tr>
<tr><td>Plain OKF bundle + <code>AGENTS.md</code> rules, e.g. <a href="https://github.com/mchu1966/okf-wiki">okf-wiki</a></td><td>OKF files in git</td><td>Directly, with rules in a prompt file</td><td>Through git and PR review; no enforcement unless CI lints</td><td>Spec Apache-2.0; okf-wiki is a 1-commit template</td></tr>
<tr><td><a href="https://github.com/atomicstrata/llm-wiki-compiler">llm-wiki-compiler</a></td><td>Local files, embeddings in files</td><td>Yes, MCP, optional review queue</td><td>No permission model</td><td>MIT, ~2.2k★, v1.5.0, "early software", OKF import/export</td></tr>
<tr><td><a href="https://github.com/lucasastorian/llmwiki">llmwiki</a></td><td>Local files + SQLite, or Postgres/S3 hosted</td><td>Yes, MCP</td><td>Single-user; team capture on the roadmap</td><td>Apache-2.0, ~1.8k★</td></tr>
<tr><td colspan="5"><b>Agent memory systems</b> (facts in a database, not a doc corpus people read)</td></tr>
<tr><td><a href="https://github.com/basicmachines-co/basic-memory">basic-memory</a></td><td>Markdown + SQLite index, vectors</td><td>Yes, MCP</td><td>Local is single-user; hosted Teams tier announced</td><td>AGPL-3.0, ~4.5k★, active</td></tr>
<tr><td><a href="https://github.com/mem0ai/mem0">mem0</a></td><td>Vector store</td><td>Yes, SDK</td><td>Scoped by user/agent id, not a shared wiki</td><td>Apache-2.0, ~68k★</td></tr>
<tr><td><a href="https://github.com/getzep/graphiti">Graphiti</a> / Zep</td><td>Temporal graph DB (Neo4j…)</td><td>Yes; reference MCP server has no auth</td><td>Build your own service, or use Zep</td><td>Apache-2.0, ~32k★</td></tr>
<tr><td><a href="https://github.com/letta-ai/letta">Letta</a></td><td>Server-side agent state</td><td>Agents edit their own memory</td><td>Per agent</td><td>Apache-2.0, ~25k★; code moved to letta-code</td></tr>
<tr><td colspan="5"><b>Docs generated from code</b> (read-only for agents)</td></tr>
<tr><td><a href="https://github.com/AsyncFuncAI/deepwiki-open">deepwiki-open</a></td><td>Generated wiki + embeddings</td><td>No</td><td>One wiki per repo</td><td>MIT, ~18k★</td></tr>
<tr><td>DeepWiki (deepwiki.com) <i>unverified</i></td><td>Hosted, generated</td><td>No</td><td>Per repo</td><td>Couldn't reach the site</td></tr>
<tr><td><a href="https://github.com/upstash/context7">Context7</a></td><td>Hosted index of third-party library docs</td><td>No, read-only</td><td>Not for your own knowledge</td><td>MIT, ~64k★</td></tr>
<tr><td colspan="5"><b>Classic docs platforms</b></td></tr>
<tr><td>Backstage TechDocs <i>unverified</i></td><td>MkDocs Markdown next to each repo, built into a portal</td><td>Through normal PRs</td><td>Designed for many repos and teams: software catalog, ownership</td><td>Apache-2.0, CNCF; couldn't reach backstage.io</td></tr>
<tr><td>Per-repo <code>AGENTS.md</code> / <code>CLAUDE.md</code></td><td>One file per repo</td><td>Directly</td><td>Doesn't share across repos; copies drift</td><td>What Cartographer's FAQ recommends for one repo and one person</td></tr>
</table></div>
"""

nbText: """
Two things stand out. First, **only Cartographer in this list is built for many agents from many teams writing to the same knowledge.**
The other wikis are single-user, and the memory systems store facts for one agent, not documentation people can review.
Second, the two real alternatives for a team are not tools. One is the **plain OKF bundle** (a git repo of Markdown plus written rules
and CI), and the other is the **docs platform you may already have**. Cartographer competes with those on enforcement and audit, not on format.
"""

nbRawHtml: """<h2 id="fit"><span class="num">08 · FIT</span>For a multi-repo, multi-team project</h2>"""

nbText: """
I don't know your project's details, so this assumes several teams, each owning a few repos, with developers using coding agents
(Claude Code, Codex and others), and knowledge that crosses repo boundaries: contracts between services, decisions, runbooks and onboarding.

**Where it helps most**

- **Cross-repo knowledge with no home.** "Why do we retry this way" lives in Slack, in one person's head, or in one repo's `CLAUDE.md`.
  A shared KB with one folder per team and a journal of decisions gives it a home that every agent reads at the start of a session.
- **Many writers, little trust.** If agents on several teams will write, the guardrails are the point: required `type` and `owner`,
  no broken links, no blind overwrites, and an audit trail that names the agent and the reason. This is the gap between Cartographer and a plain folder.
- **One agent setup for everyone.** Shipping the team's skills, subagents and instructions from one repo to every client fixes the
  drift between developers' `.claude/` and `.codex/` folders. You may find this useful even if you use nothing else.
- **Easy to leave.** It's OKF Markdown in git. If Cartographer stalls, the bundle stays readable by people, by other OKF tools, and by any agent with plain file access.

**What to watch**

- **Bus factor.** It's a pre-1.0 personal project, maintained on a best-effort basis, with breaking changes in minor versions.
  Pin a version and don't put it in the critical path yet.
- **A server to run.** You'd need the HTTP mode, tokens, backups, and someone who owns it. The local mode is one person's KB.
- **KBs don't link to each other.** The docs say "no cross-links between different KBs". For one project, use **one KB with a map
  per team**, not one KB per team, or the cross-team links you want most won't be possible.
- **Drift from code.** The KB lives outside the code repos. Unless something ties pages to code (like the `sources` check above,
  or a CI job that asks for KB updates on API changes), it will drift the way wikis always do.
- **Search is keyword-only.** That's a deliberate choice, and fine for a curated wiki. It's weak for fuzzy recall over a large corpus.

**What I'd do**

1. **Start with the format, not the server.** Create one `kb-<project>` repo as an OKF bundle with `services/`, `teams/<team>/` and a
   `decisions/` journal. Add a short `AGENTS.md` with the rules and link it from every code repo's `AGENTS.md`/`CLAUDE.md`. Run a
   lint in CI, either `carto`'s or a 50-line script. This costs a day and settles whether agents and people actually use the KB.
2. **Pilot Cartographer with two teams for two to four weeks** once more than a couple of people's agents are writing. Watch for refused
   writes (that's the guardrails working), conflicts, merge pain, and whether `cartographer sync` of skills saves real time.
3. **Decide on evidence.** If agents edit freely and quality holds, the plain bundle may be enough. If you see broken links,
   overwrites or nobody knowing where a claim came from, that's what Cartographer is for. Either way, nothing is wasted, because the files are the same.

Questions that would change this: How many people's agents would write, as opposed to read? Do you already run a docs portal such as
Backstage or Confluence that this must coexist with? Can your teams run a shared internal service, or must everything be local and git-only?
"""

nbRawHtml: """<h2><span class="num">09 · SOURCES</span>What I read, and what I couldn't</h2>"""

nbText: """
- **Cartographer:** [repo and README](https://github.com/BeppeTemp/cartographer),
  [overview](https://github.com/BeppeTemp/cartographer/blob/main/docs/overview.md), [FAQ](https://github.com/BeppeTemp/cartographer/blob/main/docs/faq.md),
  [data plane](https://github.com/BeppeTemp/cartographer/blob/main/docs/data-plane.md), [control plane](https://github.com/BeppeTemp/cartographer/blob/main/docs/control-plane.md).
  The ends of the last two were too long to read in full.
- **LLM Wiki:** [Karpathy's gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f), April 4, 2026.
- **OKF:** [spec v0.2](https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/main/SPEC.md),
  [Google Cloud announcement](https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing) (June 12, 2026, describing v0.1).
  The announcement and some third-party pages point to a v0.1 spec in `GoogleCloudPlatform/knowledge-catalog`. I didn't read that version.
- **"OKF LLMWiki":** [real-jiakai/okf_llm_wiki](https://github.com/real-jiakai/okf_llm_wiki). I didn't find a product by that name.
- **Alternatives:** the READMEs linked in the table.
- **Couldn't reach** (sandbox network policy): beppetemp.github.io/cartographer, deepwiki.com, backstage.io, agents.md. Rows that depend on them are marked *unverified*.

The page's sources are in [`cartographer-nim/src`](https://github.com/pietroppeter/claude-artifacts/tree/main/cartographer-nim/src).
`carto.nim` is the library and MCP server, and `index.nim` is this [nimib](https://github.com/pietroppeter/nimib) notebook. Every
output above was produced by running it.
"""

nbSave
