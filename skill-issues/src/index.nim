## An interactive explainer of "Skill Issues: Data-Centric Optimization of Lakehouse Agents"
## (Schneider, Ghilardi, Piccinini, Tagliabue; VLDB 2026 ADS workshop), for Nim and nimib people.
## Build: sh deps.sh && nim r index.nim   (writes ../index.html)
import std/[strformat, strutils, sequtils, os, json, math]
import nimib
import lib/[data, blocks, style]
import review   # tabelline's review mode, from shared/review at the root of this repository (config.nims)

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.title = "Skill issues, explained for Nim folks"
nb.useExplainerStyle
nb.useSourceFooter
nbReview(tpage = "skill-issues-explainer", tsource = "skill-issues/src/index.nim")

# ---------------------------------------------------------------- data, at build time
let here = currentSourcePath().parentDir
let seeds = bauplanSeeds(here / "data" / "bauplan-seeds")
let mine = pietroSkills(here / "data" / "pietro-skills")
let cases = evalCases(here / "data" / "pietro-skills")
let skillsCommit = readFile(here / "data" / "pietro-skills" / "COMMIT").strip
let seedAvg = seeds.mapIt(it.chars.float).mean
let optimizedAvg = seedAvg * lengthFactor
let byVal = curves.mapIt(it.byValidation)
let byTst = curves.mapIt(it.byTest)
let avgVal = byVal.mapIt(it.gain).mean
let avgTst = byTst.mapIt(it.gain).mean
var bestTst = 0
for i, p in byTst:
  if p.gain > byTst[bestTst].gain: bestTst = i
var graderTotals: array[GraderLevel, int]
for c in cases:
  for l in GraderLevel: graderTotals[l] += c.graders[l]
let nGraders = graderTotals.sum

# ---------------------------------------------------------------- the page
nbText: """
# **Skill issues**, explained for Nim folks
"""

nbLede: """
When a coding agent gets your library wrong, the fix is usually a Markdown file: a skill.
A team at Bauplan Labs stopped hand-tuning theirs and started *optimizing* them, like
hyperparameters, against hundreds of tasks whose results a program can check. This page
walks through how, and what the same trick would look like for Nim and nimib.
"""

nbText: """
This is an explainer of [“Skill Issues”: Data-Centric Optimization of Lakehouse
Agents](https://arxiv.org/abs/2606.01185) by Nicole Rose Schneider (University of Maryland),
Davide Ghilardi (Università Milano-Bicocca), Giacomo Piccinini and Jacopo Tagliabue (Bauplan Labs),
at the VLDB 2026 workshop on Agentic Data Systems. The code is open source (MIT) at
[BauplanLabs/skill-issues](https://github.com/BauplanLabs/skill-issues). Notes marked
**For nimib** are ours, not the paper's.

## In one minute
"""

nbStats(@[
  (value: "780", label: "generated tasks, each with a program that checks the result"),
  (value: "6", label: "Bauplan skills optimized, one at a time, with GEPA"),
  (value: "+12.0%", label: "average gain in held-out reward over the hand-written seed skills"),
  (value: "27×", label: "longer: the optimized skills, in characters, vs the seeds")])

nbText: """
- A coding agent setup is mostly fixed: you pick Claude Code and a model, and you cannot
  retrain either. What you *can* change is text: `CLAUDE.md` and the skills. So treat that text
  as the parameters to optimize.
- To optimize you need a score, and a score needs a check. Bauplan is a lakehouse with
  **git for data**: every write an agent makes becomes a commit you can inspect. So instead of
  asking "does the answer look right?", the checks ask "did the data change the way it should?"
- They generate tasks together with their verifiers, run the agent in sandboxes on a throwaway
  branch, score each run, and let an optimizer (GEPA) rewrite the skill. Repeat.
- Every skill improved on held-out tasks. Skills used in tasks that need *several* skills improved
  least: the next step is to optimize skills together.

## Why a Nim person should care

The paper's starting point will sound familiar:
"Bauplan APIs are not yet well represented in the training set, users' prompting abilities vary
widely, and the new affordances call for revised best practices." Replace *Bauplan* with *Nim*, or
with *nimib*, and it is the same situation. Models have seen far more Python than Nim, and far
more Jupyter than nimib. Skills are how we close the gap.

Here is the setup of the paper's Figure 1. Only two boxes are yours to write:
"""

nbKnobs(@[
  (name: "Task", what: "what the user asks for", yours: false),
  (name: "Coding agent", what: "Claude Code (or another assistant)", yours: false),
  (name: "Model", what: "Sonnet, Opus…: frozen, closed weights", yours: false),
  (name: "Tools", what: "Bash, Python, the platform's CLI and SDK", yours: false),
  (name: "CLAUDE.md", what: "project instructions (AGENTS.md elsewhere)", yours: true),
  (name: "Skills", what: "SKILL.md files the agent loads when relevant", yours: true)])

nbNote(nkNimib, """
Pietro's [skills repo](https://github.com/pietroppeter/skills) is exactly these two boxes:
a `CLAUDE.md` and plugins of skills (`nimib`, `nimib-theme`, `nimib-blocks`, `nimibook`,
`publish-artifact`, …). Everything this paper does to Bauplan's skills could be done to those.
""")

nbText: """
## From matching outputs to checking state

The paper's central observation: on a branching lakehouse, evaluating an agent stops being an
*output-matching* problem and becomes a *state-verification* problem.

Two Bauplan features make that work. It is **headless**: everything (running pipelines,
creating tables, reading logs) is an API call, through a CLI or a typed Python SDK, so a verifier
can use the same calls the agent uses. And it is **git for data**: branches, commits and merges
over tables. When the agent runs a pipeline on a branch, each write is a commit, and the final
merge into `main` is one more. Reading the pipeline code, you can list the commits a successful
run *must* leave behind. The paper calls this the isomorphism between pipeline code and data
commits, and it is what lets a program check write tasks ("ingest this file", "fix this table"),
not just read-only ones like text-to-SQL.
"""

nbNote(nkPaper, """
"A candidate skill is rewarded only when the agent changes the lakehouse in the intended way."
Checking state also limits cheating: an agent that *says* it merged, but did not, gets no credit.
""")

nbNote(nkNimib, """
A nimib document has the same property on a small scale. It is code, and running it writes an
HTML page that follows from the code. So the page is state you can inspect. Pietro's `nimib`
skill already ships `nbcheck.nim`, which builds a document and checks the rendered HTML, and
`nimib-theme` ships `phonecheck.js`, which loads the page at 390 px and checks that code blocks fit.
Those are verifiers of state. Nim adds one more check for free: the paper notes that "a
statically checkable SDK reduces round-trips", and in Nim the compiler checks the document
before it runs.
""")

nbText: """
## One task, start to finish

Every benchmark task runs through the same six steps (the paper's Table 1). The fixed life-cycle is
what makes it safe to let the agent write: it only ever writes on a branch made for it. Switch
the tab to see the same steps for a nimib page.
"""

nbLifecycle("lifecycle", @[
  (title: "Create a writable branch",
   bauplan: "Branch `<username>.main` off `main`. The agent may write there, never on `main`.",
   nimib: "Fresh checkout on a scratch branch, or an empty folder for a new page: the agent's sandbox."),
  (title: "Prepare the initial state",
   bauplan: "Drop any tables the task says must be absent at the start.",
   nimib: "Put the task's starting files in place. Pietro's `nimib-fix-03-doc` case ships a broken `report.nim` and a `place-files.sh`."),
  (title: "Capture a baseline",
   bauplan: "Snapshot the latest commit on `main` and on the agent's branch.",
   nimib: "Record `git rev-parse HEAD`: the *before* to diff against."),
  (title: "The agent runs",
   bauplan: "Claude Code, with the skills under test, works on the task prompt.",
   nimib: "Claude Code, with the nimib skills, works on a prompt like *make a page that counts word frequencies*."),
  (title: "Validate",
   bauplan: "Score the run against the task's end conditions: commands in the trace, lakehouse state, the final answer.",
   nimib: "Run the graders: was the skill used? Does `word_freq.html` exist, with code output in it, and no raw HTML in the `.nim`? Then `nbcheck` and `phonecheck`."),
  (title: "Tear down",
   bauplan: "Delete the agent's branches. Nothing reaches `main`.",
   nimib: "Throw the branch away. For real work, the equivalent is a pull request Pietro merges from his phone.")])

nbText: """
## Three ways to catch an agent

Each run is checked at three levels:

- **Trace**: what the agent did. Did it load the expected skill? Did it call the expected
  commands (CLI or SDK, either is fine)? Did it avoid forbidden ones, like `bauplan run` in a
  read-only task?
- **State**: what changed. Does the branch exist? Is a table unchanged that should be? For write
  tasks, a Python script uses the SDK to check the result commit by commit and exits non-zero,
  with an explanation, when something is off.
- **Response**: what the agent said. Hard checks (a string, a regex) and soft ones: a rubric that
  an LLM judge grades, for free-form answers like a data exploration.

The score of a run, its **reward**, is the share of checks that pass, from 0 to 1. Try placing
these cases. Some are from the paper, some are from Pietro's own nimib skill tests.
"""

nbQuiz("quiz")

let quizDomain = @["Bauplan", "Bauplan", "Bauplan", "nimib", "nimib", "nimib", "nimib"]
let quizText = @[
  "Asked only to explore some ticket data, the agent calls `bauplan run` to build a summary table. The run fails before writing anything.",
  "The agent replies: “Ingested 10,000 rows into raw.trips and merged to main.” On main, raw.trips has no new commit.",
  "Asked how ticket categories are distributed, the agent answers: “There are several categories, some more common than others.”",
  "Asked for a nimib page of word frequencies, the agent builds a fine word_freq.html, without ever opening the nimib skill.",
  "The agent says the page is built and checked, but word_freq.html has no code output in it: the code never ran.",
  "The page builds and shows outputs, but the prose says “the most common word is *the*, 12 times”, typed by hand in the nbText string.",
  "Asked to make a nimib page look nicer, the agent writes `<style>` and colour codes straight into nbText instead of a style module."]
let quizAnswer = @[0, 1, 2, 0, 1, 2, 1]
let quizWhy = @[
  "Nothing changed, so only the trace shows it: the task lists `bauplan run` as a forbidden action.",
  "Only the lakehouse state tells the truth: the claimed commit is not there. This is the cheating that state checks rule out.",
  "Nothing changed and no command was wrong. The paper's rubric “category_distribution_is_quantitative” fails it: a judge wants counts or a ranking.",
  "The result looks right, but the trace has no Skill call. Pietro's tests have a `tool_used: Skill` grader for exactly this.",
  "A regex on the HTML file looks for `<pre class=\"nb-output\">`. State, not the agent's word.",
  "The numbers are right today, but not computed. Pietro's test has an LLM grader for this: numbers in prose must come from the code.",
  "A regex on the .nim file forbids `<style`, `style=\"` and hex colours. Pietro's “no raw HTML” grader checks the state of the source."]

nbText: """
## Where the tasks come from

You cannot optimize against five hand-written examples, so the authors generate the benchmark,
carefully. Real usage sets the mix: here is what agents actually call on Bauplan (a May 2026
sample of anonymized production logs, the paper's Table 2).
"""

func shareBars(xs: seq[Share], cls: string): seq[Bar] =
  for x in xs:
    let lbl = if x.what.len > 0: &"{x.name} <span class=\"muted\">({x.what})</span>" else: x.name
    result.add (label: lbl, value: x.pct.float, shown: &"{x.pct}%", cls: cls)

nbBarTabs("usage", @[
  BarChart(tab: "Compute", title: "Compute calls", bars: shareBars(computeApis, "read"),
    note: "Share within the group, rounded. Writes (imports, runs) are most of the traffic."),
  BarChart(tab: "Branches", title: "Branch calls", bars: shareBars(branchApis, "read"),
    note: "Merges and deletes dominate: agents really do change data, not only read it.")])

nbText: """
Raw counts are only a prior. Today's traces are shaped by today's skills (well-documented calls
show up more), and some rare calls matter a lot for safety, so every API is covered on purpose.
The authors also look at whole **sessions**: a branch, an import, a check query and a merge in a row
read as a *safe ingestion*. A model can infer the intent behind a session and turn it into a
task template (they call this inverse planning).

Tasks vary along three axes: the scenario (six kinds, read or write), the persona (data engineer,
analyst, scientist), and how **explicit** the prompt is. Vague prompts model novices, detailed
ones model experts who name tables, columns and acceptance criteria. Here is the same intent at
the three levels, for a nimib task:

| Explicitness | Prompt |
|---|---|
| vague | make me an IMIB page with word counts |
| medium | Make a nimib document that counts word frequencies in a paragraph and shows the top 5. |
| detailed | `word_freq.nim`: one `nbCode` counts words with a `CountTable`, echo the top 5, prose interpolates the top word; build `word_freq.html`; no raw HTML. |

An LLM (GPT-5.5 was the one that could write a consistent task and verifier in one go) emits one
task at a time through a typed tool call. Each is validated, for example "commands must
correspond to real CLI arguments", and read-only tasks must forbid at least one write and assert
that nothing changed. Invalid ones are thrown away and regenerated. Then domain experts sample and
read tasks by hand.
"""

nbNote(nkNimib, """
The vague row is not a joke: Pietro dictates, and voice recognition turns "nimib" into "IMIB".
A skill that only works for detailed prompts fails its most frequent user. The explicitness axis
is a good idea for any Nim skill benchmark.
""")

nbBarTabs("dataset", @[
  BarChart(title: "The 780 tasks, by scenario (Table 3)",
    legend: legend(key("read", "read-only (365)"), key("write", "write (415)")),
    bars: readTasks.shareBars("read").mapIt((label: it.label, value: it.value, shown: $it.value.int, cls: it.cls)) &
          writeTasks.shareBars("write").mapIt((label: it.label, value: it.value, shown: $it.value.int, cls: it.cls)))])

nbText: """
## The optimizer, and what it found

The optimizer is [GEPA](https://github.com/gepa-ai/gepa) (*optimize anything*), which evolves
text by reflecting on failures. It takes a **seed skill**, an **evaluation function** (run the agent
in a sandbox on tasks that need the skill, return the reward) and a **description of the goal**.
It proposes new versions of the skill, reading the error traces as hints.

For each of the six skills, the tasks that need it are split 70 / 15 / 15: GEPA learns on the
first part, picks its best candidate on the second (validation), and the third (test) is held out to
measure the result. The agent is Claude Code with Sonnet 4.6. Here are the curves, redrawn from the
paper's Figure 4:
"""

nbCurves("curves")

nbNote(nkPaper, """
For every skill, GEPA found a candidate that beats the seed on validation *and* on held-out
tasks, by 12.0% on average and by up to 28.6%. Skills whose tasks need several skills at once
improved only a little when optimized alone.
""")

nbText: &"""
What changed in the text? The optimizer added detail: pointers to the docs, phrases telling the
agent *not to invent or guess flags*, good practice like Write-Audit-Publish on an isolated branch,
and better `description` lines when a check failed because the agent never loaded the skill.

### How long is a good skill?

The seeds were tiny. Here is the safe-ingestion seed from the repo, in full (frontmatter left out):

```text
# Safely Ingesting Data into Bauplan

See https://docs.bauplanlabs.com for details.
```

Optimized skills were **27.2 times longer** on average. Compare with Pietro's skills, counted
from his repo (commit `{skillsCommit[0..6]}`) when this page was built:
"""

var lengthBars: seq[Bar]
for s in seeds:
  lengthBars.add (label: s.name, value: s.chars.float, shown: &"{s.chars}", cls: "bauplan")
lengthBars.add (label: "bauplan, optimized (average, estimated)", value: optimizedAvg,
  shown: &"≈ {optimizedAvg.round.int}", cls: "estimate")
for s in mine:
  lengthBars.add (label: s.name, value: s.chars.float, shown: &"{s.chars}", cls: "pietro")

nbBarTabs("lengths", @[
  BarChart(title: "Characters in each SKILL.md",
    legend: legend(key("bauplan", "Bauplan seed"), key("estimate", "Bauplan optimized (seed average × 27.2)"), key("pietro", "Pietro's skills")),
    bars: lengthBars,
    note: &"Bauplan seeds average {seedAvg.round.int} characters, frontmatter included. The paper does not publish the optimized skills; the striped bar is our estimate.")])

nbNote(nkNimib, """
Pietro's skills are already as long as Bauplan's *optimized* ones: they were written by hand
from many failed attempts, which is a slow, manual version of the same loop. An optimizer
starting from a rich seed has less room to gain, and longer skills cost context on every task.
""")

nbText: &"""
### Read the curves carefully

GEPA picks its candidate on validation; the test set should only measure the result. We read the
points off Figure 4 and compared two ways to choose a candidate per skill:

| skill | GEPA's pick | Δ test | best test | Δ test |
|---|---|---|---|---|
""" & toSeq(0 ..< curves.len).mapIt(
  &"| {curves[it].skill.short} | {byVal[it].candidate} | {signed byVal[it].gain}% | {byTst[it].candidate} | {signed byTst[it].gain}% |").join("\n") & &"""

| **average** | | **{signed avgVal}%** | | **{signed avgTst}%** |
"""

nbNote(nkReading, &"""
Picking by validation, as the method says, gives about **{signed avgVal}%** on average in our
reading, and `debug-and-fix-pipeline` gets slightly *worse* on test ({signed byVal[4].gain}%).
The headline "up to 28.6%" matches the best *test* point of `{curves[bestTst].skill.short}`
(candidate {byTst[bestTst].candidate}, {signed byTst[bestTst].gain}% in our reading), not the candidate
validation would pick there ({byVal[bestTst].candidate}, {signed byVal[bestTst].gain}%). Our readings are
by eye, to about ±0.01, and the paper does not say how its 12.0% average was computed, so take this
as a question to ask the authors, not a finding.
""")

nbText: """
## What a nimib version would look like

Pietro's skills repo already has the first ingredient: graded test cases in the format of
`claude plugin eval`. Each case has a prompt and a folder of graders. Here they are, counted when
this page was built, sorted into the paper's three levels (a `tool_used` grader is a trace check,
`file_exists` and `regex` on files are state checks, an `llm` grader is a judge):
"""

var caseRows = "| skill | case | trace | state | judge |\n|---|---|---|---|---|\n"
for c in cases:
  caseRows.add &"| {c.skill} | {c.name} | {c.graders[glTrace]} | {c.graders[glState]} | {c.graders[glJudge]} |\n"
caseRows.add &"| **total** | **{cases.len} cases** | **{graderTotals[glTrace]}** | **{graderTotals[glState]}** | **{graderTotals[glJudge]}** |\n"
nbText: caseRows

nbText: &"""
So {cases.len} task-verifier pairs with {nGraders} checks, about the size of the paper's first
version (its v1 abstract reported results on 25 tasks). The paper ends with 780. Here is the shape
of one pair and its reward, in Nim. The code runs when the page is built:
"""

nbCode:
  type
    Level = enum trace, state, judge
    Check = object
      level: Level
      what: string

  let task = %*{
    "task_name": "nimib_word_frequency_page",
    "category": "write_new_page",
    "explicitness": "vague",
    "prompt": "make me an IMIB page with word counts",
    "expected_skills": ["nimib"],
    "forbidden_actions": [{"pattern": "cdn\\.jsdelivr|highlight\\.min\\.js",
                           "reason": "pages are self-contained"}]}

  let checks = @[
    Check(level: trace, what: "the nimib skill was loaded"),
    Check(level: state, what: "word_freq.html exists"),
    Check(level: state, what: "it shows code output (nb-output)"),
    Check(level: state, what: "nbcheck passes, phonecheck passes at 390px"),
    Check(level: judge, what: "numbers in the prose come from the code")]

  func reward(passed: openArray[bool]): float =
    passed.countIt(it).float / passed.len.float

  echo task["prompt"].getStr, "  (", task["explicitness"].getStr, ")"
  # an agent that wrote a page but never ran it, and said it did
  let passed = [true, true, false, false, true]
  for i, c in checks:
    echo (if passed[i]: "pass " else: "FAIL "), ($c.level).alignLeft(6), c.what
  echo "reward: ", reward(passed), "   (output matching on \"Done!\" would give 1.0)"

nbText: """
The rest of the loop exists too. The skill-issues repo separates a domain-agnostic engine
(`src/core`) from domains (`src/domains`), and `just new-domain <name>` copies a template to fill
in: scenario and task prompts, a schema, a Docker environment with the skills, a test script. A
`nimib` domain would need:

1. **Tasks from real sessions.** Pietro's project threads are sessions: an ask, a sequence of
   commands, a merged PR or a complaint. That is the input for inverse planning, and the
   complaints ("code spills out of its box on my phone") become checks.
2. **Verifiers that read state.** `nim r` compiles the document (the static check), `nbcheck`
   reads the HTML, `phonecheck` loads it at 390 px, and regexes keep raw HTML out of the source.
3. **An adapter.** The paper runs tasks with Harbor on Modal sandboxes and scores with its own
   checks; Pietro's cases use `claude plugin eval` graders. One format would have to be
   translated into the other.
4. **Multi-skill tasks, with care.** A page like this one uses `nimib`, `nimib-blocks`,
   `nimib-theme` and `publish-artifact` together. The paper found that optimizing one skill
   at a time barely helps such tasks, so optimizing them jointly is the interesting part.
"""

nbNote(nkCareful, """
We have not run the skill-issues code on nimib: the list above is a plan, not a result.
It needs Modal and LLM API keys, and every optimization run costs many agent runs.
""")

nbText: """
## Caveats

- **Preliminary, by the authors' own word.** One agent (Claude Code) and one model (Sonnet 4.6).
  A skill tuned for one model may not transfer to another.
- **Small held-out sets.** Each skill's test set is 15% of its pool of tasks, so a few tasks
  move the reward by points. Several curves zig-zag by as much as the gains.
- **The headline moved.** The first version of the abstract said 31.9% on 25 tasks; the
  current one says up to 28.6% on hundreds. The body reports 12.0% on average.
- **Synthetic tasks, checked by sampling.** An LLM wrote both tasks and verifiers; experts read
  a sample. A wrong verifier rewards the wrong behaviour, and the optimizer will find it.
- **Longer skills cost context.** The optimizer has no reason to keep skills short unless the
  goal says so; 27× longer means more tokens on every task that loads them.
- **Bauplan's own features do much of the work.** The authors say so: without headless APIs
  and git for data, fine-grained write checks would not have been possible. Other domains need
  their own way to read state (for nimib: the HTML).

## Check our numbers

The Figure 4 readings are in `lib/data.nim`. This printed the comparison table when the page
was built:
"""

nbCode:
  for i, c in curves:
    let v = c.byValidation
    let t = c.byTest
    echo &"{c.skill.short:<24} seed test {c.test[0]:.3f}  by validation #{v.candidate:<2} {signed v.gain:>6}%  best test #{t.candidate:<2} {signed t.gain:>6}%"

# ---------------------------------------------------------------- browser side
let curveVal = curves.mapIt(it.validation)
let curveTest = curves.mapIt(it.test)

nbJsFromCodeGlobal:
  import std/[dom, strutils]

nbJsFromCodeInBlock:
  # tabs: every .tabbed figure switches its panes
  proc wireTab(fig, t: Element) =   # a proc per element: closures made in a loop share one variable in Nim's JS backend
    t.addEventListener("click", proc (e: Event) =
      let pane = t.getAttribute("data-pane")
      for o in fig.querySelectorAll(".tab"):
        o.setAttribute("aria-selected", cstring(if o.getAttribute("data-pane") == pane: "true" else: "false"))
      for p in fig.querySelectorAll(".pane"):
        if p.getAttribute("data-pane") == pane: p.removeAttribute("hidden")
        else: p.setAttribute("hidden", ""))
  for fig in document.querySelectorAll(".tabbed"):
    for t in fig.querySelectorAll(".tab"): wireTab(fig, t)

nbJsFromCodeInBlock(curveVal, curveTest):
  proc f3(x: float): string = formatFloat(x, ffDecimal, 3)
  proc pctChange(x: float): string =
    let sign = if x >= 0: "+" else: "−"
    result = sign & formatFloat(abs(x), ffDecimal, 1) & "%"
  proc wireHit(pane, hit, cursor, readout: Element, k: int) =
    hit.addEventListener("click", proc (e: Event) =
      let i = parseInt($hit.getAttribute("data-i"))
      cursor.setAttribute("x", hit.getAttribute("x"))
      cursor.setAttribute("visibility", "visible")
      let v = curveVal[k][i]
      let t = curveTest[k][i]
      let seedT = curveTest[k][0]
      if i == 0:
        readout.innerHTML = cstring("Candidate <b>0</b> is the seed skill: validation " & f3(v) & ", test " & f3(t) & ".")
      else:
        readout.innerHTML = cstring("Candidate <b>" & $i & "</b>: validation " & f3(v) & ", test " & f3(t) &
          ". Test change vs the seed: <b>" & pctChange(100 * (t / seedT - 1)) & "</b>."))
  let fig = getElementById("curves")
  var k = 0
  for pane in fig.querySelectorAll(".pane"):
    let cursor = pane.querySelector(".cursor")
    let readout = pane.querySelector(".readout")
    for hit in pane.querySelectorAll(".hit"): wireHit(pane, hit, cursor, readout, k)
    inc k

nbJsFromCodeInBlock(quizDomain, quizText, quizAnswer, quizWhy):
  const names = ["trace", "state", "judge"]
  let card = getElementById("quiz")
  let domainEl = card.querySelector(".quiz-domain")
  let promptEl = card.querySelector(".quiz-prompt")
  let feedback = card.querySelector(".quiz-feedback")
  let score = card.querySelector(".quiz-score")
  let picks = card.querySelectorAll(".pick")
  var pos = 0
  var right, total = 0
  proc code(s: string): string =   # `x` to <code>x</code>, after escaping
    var inCode = false
    for c in s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;")):
      if c == '`':
        if inCode: result.add "</code>"
        else: result.add "<code>"
        inCode = not inCode
      else: result.add c
  proc show() =
    let i = pos mod quizText.len
    domainEl.textContent = cstring(quizDomain[i] & " · case " & $(i + 1) & " of " & $quizText.len)
    promptEl.innerHTML = cstring(code(quizText[i]))
    feedback.innerHTML = ""
    for b in picks:
      b.removeAttribute("disabled")
      b.classList.remove("chosen")
  proc wire(btn: Element) =
    btn.addEventListener("click", proc (e: Event) =
      let i = pos mod quizText.len
      let guess = parseInt($btn.getAttribute("data-k"))
      inc total
      btn.classList.add("chosen")
      var head = "<span class=\"wrong\">It's " & names[quizAnswer[i]] & ".</span> "
      if guess == quizAnswer[i]:
        inc right
        head = "<span class=\"right\">Right: " & names[quizAnswer[i]] & ".</span> "
      feedback.innerHTML = cstring(head & code(quizWhy[i]))
      for o in picks: o.setAttribute("disabled", "")
      score.textContent = cstring($right & " / " & $total))
  for b in picks: wire(b)
  card.querySelector(".quiz-next").addEventListener("click", proc (e: Event) =
    inc pos
    show())
  show()

nbSave
