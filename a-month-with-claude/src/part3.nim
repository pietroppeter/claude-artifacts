## Part three: skills, from the beginning.
# The OpenSpec skills and commands in tabelline's repository on 7 November 2026: a snapshot of
# their sizes (data/openspec.tsv) and the top of one skill, taken from .claude/ in pietroppeter/tabelline.
type Installed = object
  name, kind: string
  kb: float
var installed: seq[Installed]
for line in readFile(srcDir / "data" / "openspec.tsv").splitLines[1 .. ^1]:
  let f = line.split('\t')
  if f.len == 3: installed.add Installed(name: f[0], kind: f[1], kb: parseFloat(f[2]) / 1024)
let skillHead = readFile(srcDir / "data" / "openspec-propose-head.yaml").strip
nbText: """
Skills are the fifth group of [Operetta](#part-two), the *suggeritore*, and the one with the
least in it. This part starts from nothing and goes step by step.

### A skill is a folder

A skill is a folder with a file called `SKILL.md` in it. The file starts with two fields, a
`name` and a `description`, and goes on with instructions in plain Markdown. The folder can also
hold scripts to run and longer references to read. That is all: no code to install, no server.

Here is the top of a skill that is in tabelline's repository, put there by OpenSpec:
"""

nbText "```yaml\n" & skillHead & "\n...\n```"

nbText: """
What makes skills work is *when* each part is read. The agent sees only the `name` and the
`description` of every skill it has, a line or two each. It reads the rest of `SKILL.md` only
when a task matches the description, and the scripts and references only if the instructions
send it there. A project can carry many skills and pay for the ones in use. The
[Agent Skills](https://agentskills.io) format is an open standard: Claude Code, Codex, Cursor
and others read the same folders.

### Skills and their neighbours

There are other ways to give an agent knowledge, and the difference is mostly who loads it and
when:
"""

block:
  type N = object
    what, isa, loaded, example: string
  let rows = @[
    N(what: "**AGENTS.md**", isa: "the house rules of a repository", loaded: "always, at the start of every session",
      example: "tabelline's AGENTS.md: specs first, one PR per change, previews"),
    N(what: "**slash command**", isa: "a prompt you call by name", loaded: "by you, when you type it",
      example: "/opsx:propose"),
    N(what: "**skill**", isa: "a procedure or a body of knowledge, in a folder", loaded: "by the agent, when a task matches its description",
      example: "openspec-propose: how to write a change"),
    N(what: "**llms.txt**", isa: "a library's docs, in one text file for any language model", loaded: "fetched when someone points the model at it",
      example: "Great Tables' llms.txt and llms-full.txt"),
    N(what: "**MCP server**", isa: "tools the agent can call: a program, not text", loaded: "always available, run when called",
      example: "the GitHub tools that opened this article's pull request"),
    N(what: "**plugin**", isa: "a package of skills, commands and servers, from a marketplace", loaded: "installed once, then as its parts",
      example: "posit-dev/skills, as a Claude Code marketplace"),
  ]
  var shown: seq[tuple[what, loaded, example: string]]
  for r in rows: shown.add (&"{r.what}<br>{r.isa}", r.loaded, r.example)
  let t = tabella(shown, rownameCol = "what"):
    tabHeader "Six ways to teach an agent", "and who loads each one, when"
    colsLabel {"loaded": "loaded", "example": "for example"}
    fmtMarkdown "what"
    colsWidth {"what": "36%"}
  nbTable t

nbText: """
### Who calls a skill

Either the agent, because the description matches, or you, by name. OpenSpec ships the same
workflows both ways: in tabelline there are six skills and six commands, nearly the same text
twice.
"""

block:
  # the same six workflows, as a skill (the agent loads it) and as a command (you type it)
  var rows: seq[tuple[workflow: string, skill, command: float]]
  for x in installed:
    if x.kind == "command":
      var row = (workflow: x.name.replace("/opsx:", ""), skill: 0.0, command: x.kb)
      for y in installed:
        if y.kind == "skill" and y.name.startsWith("openspec-" & row.workflow): row.skill = y.kb
      rows.add row
  let t = tabella(rows, rownameCol = "workflow"):
    tabHeader "OpenSpec in tabelline's repository", "each workflow twice: a skill and a command"
    colsLabel {"skill": md("skill<br>`.claude/skills/`"), "command": md("command<br>`/opsx:…`")}
    fmtNumber ["skill", "command"], decimals = 1, pattern = "{x} KB"
    tabSourceNote md("Sizes of the files in tabelline's `.claude/`, 7 Nov 2026. Written by `openspec init` (OpenSpec 1.16), MIT.")
  nbTable t

nbText: """
That is why OpenSpec can feel like it is not there. Typing `/opsx:propose` runs the command;
asking *"let's propose a change for summary rows"* makes the agent load the skill on its own.
Either way 11 to 23 KB of instructions arrive (3,000 to 6,000 tokens), only for that task, and the work
just goes the OpenSpec way. A skill that works well is mostly invisible.

### Where skills live

For an open source library there are two audiences, and they want different skills in
different places:

- **People who work *on* the library** (and their agents): how to build it, test it, write a
  spec, make a release. These skills belong in the repository, next to AGENTS.md, and change
  with it.
- **People who work *with* the library**: how to use its API today. These belong with the
  documentation, versioned with the releases, so that a user gets the skill that matches the
  version they have.

Then there is where a skill is put on a computer, or an account:
"""

block:
  type W = object
    place, forWhom, example, install: string
  let rows = @[
    W(place: "`.claude/skills/` in the repository", forWhom: "everyone working on the repo, and every cloud session on it",
      example: "tabelline's OpenSpec skills", install: "nothing: they come with `git clone`"),
    W(place: "`~/.claude/skills/` (or `~/.agents/skills/`)", forWhom: "you, in every project on that computer",
      example: "[planetis-m/skills](https://github.com/planetis-m/skills), cloned there", install: "copy, clone or symlink a folder"),
    W(place: "your claude.ai account", forWhom: "you, in the Claude apps, and synced into Claude Code",
      example: "a skill of your own", install: "Customize → Skills → upload a ZIP of the folder"),
    W(place: "a plugin marketplace", forWhom: "anyone using Claude Code",
      example: "[posit-dev/skills](https://github.com/posit-dev/skills), [mattpocock/skills](https://github.com/mattpocock/skills), [anthropics/skills](https://github.com/anthropics/skills)",
      install: "`/plugin marketplace add owner/repo`, then `/plugin install`"),
    W(place: "the library's docs site", forWhom: "the library's users, with any agent",
      example: "Great Tables' `skill.md`, next to its `llms.txt`", install: "`npx skills add` and the site's address"),
  ]
  var shown: seq[tuple[place, install: string]]
  for r in rows: shown.add (&"{r.place}<br>for {r.forWhom}", &"{r.install}<br>*for example:* {r.example}")
  let t = tabella(shown, rownameCol = "place"):
    tabHeader "Five places for a skill"
    colsLabel {"install": "how it gets there"}
    fmtMarkdown ["place", "install"]
    colsWidth {"place": "45%"}
    tabSourceNote md("Install commands from each project's README and the [Claude help center](https://support.claude.com/en/articles/12512180-using-skills-in-claude), 7 Nov 2026.")
  nbTable t

nbText: """
`npx skills` is a small installer that copies skills from a repository or a site into the
folder each agent reads; a plugin, instead, stays managed and updates itself. Matt Pocock's
README warns not to use both for the same skills, or the agent sees every skill twice.

### Who does it well

Four collections worth reading, each with an idea worth taking:
"""

block:
  type Who = object
    who, what, idea: string
  let rows = @[
    Who(who: "**Posit**<br>[posit-dev/skills](https://github.com/posit-dev/skills)",
        what: "About two dozen skills in eight groups (open source upkeep, r-lib, Shiny, Quarto, GitHub). Separately, Great Tables publishes its own skill and an llms.txt on its docs site, made by their docs tool, Great Docs.",
        idea: "Contributor skills in one shared repo; user skills built by the docs, with the docs."),
    Who(who: "**Matt Pocock**<br>[mattpocock/skills](https://github.com/mattpocock/skills)",
        what: "A TypeScript teacher (Total TypeScript, AI Hero) who publishes the skills he uses: 27, such as grill-me (Claude asks you questions until the plan is clear), tdd, to-spec, to-tickets, diagnosing-bugs.",
        idea: "Small, composable skills that keep you in control, rather than one big framework that takes it."),
    Who(who: "**Anthropic**<br>[anthropics/skills](https://github.com/anthropics/skills)",
        what: "The reference examples, the Word, PDF, PowerPoint and Excel skills, and skill-creator, a skill that writes and tests skills.",
        idea: "Test a skill against a baseline, and test its description on its own."),
    Who(who: "**planetis**<br>[planetis-m/skills](https://github.com/planetis-m/skills)",
        what: "Fourteen Nim skills: API design, C bindings, ownership hooks, error handling, testing, fuzzing, style, an atlas helper, and one for Nimony plugins. Licence CC BY-NC-SA 4.0.",
        idea: "\"Empirically verified\": skills for Nim, checked rather than just written."),
  ]
  let t = tabella(rows, rownameCol = "who"):
    tabHeader "Four collections"
    colsLabel {"what": "what is in it", "idea": "the idea to take"}
    fmtMarkdown ["who", "what"]
    colsWidth {"who": "24%"}
    tabSourceNote md("Read on 7 Nov 2026. The Great Tables and Great Docs pages, and planetis's verified-nim site, could not be read from the sandbox; what is said of them comes from search results.")
  nbTable t

nbText: """
Matt Pocock's choice is a useful warning for Operetta. He keeps skills small because
frameworks like Spec-Kit or BMAD, in his words, *take away your control*. Operetta has to stay a
set of parts to pick, each one small, and not become one of those.

### From the phone

Pietro works with Claude Code mostly from the phone, in cloud sessions: each one starts on a
fresh clone of the repository. That decides where skills should go:

- **Skills in the repository always come along.** This article was written in such a session, and
  tabelline's six OpenSpec skills were there without anything installed.
- **Skills uploaded to the claude.ai account** are there in the Claude apps, and Claude Code
  syncs them too; in the session that wrote it, one of Pietro's own skills was present
  next to the repository's.
- **Plugins** can also be listed in the repository's `.claude/settings.json`. How that behaves in
  a session started from the phone was not tested here, so for cloud sessions the
  repository's own `.claude/skills/` is the dependable place.

So: skills for working on a project go in its repository; personal skills, for any project, go
in the account.

### Does a skill help?

A skill can fail three ways: it does not fire, it fires and does not help, or it was true once
and is not any more. Each needs its own test:
"""

block:
  type T = object
    test, how, source: string
  let rows = @[
    T(test: "**Does it fire?**", how: "About twenty requests, half that should load the skill and half near misses that should not; run each a few times, tune the description on some, check on the rest.",
      source: "[skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator)"),
    T(test: "**Does it help?**", how: "The same task with the skill and without it, several runs each. Grade the files the agent made with checks that cannot be argued with (it compiles, the HTML has the table), and a model as judge only for the rest.",
      source: "skill-creator; [SkillsBench](https://arxiv.org/abs/2602.12670); the nimib skills, [nimib#264](https://github.com/pietroppeter/nimib/pull/264)"),
    T(test: "**Is it still true?**", how: "Build every example the skill teaches, on every push, against the current library.",
      source: "the nimib skills' snippet checker; tabelline's spec examples already do this for the specs"),
  ]
  let t = tabella(rows, rownameCol = "test"):
    tabHeader "Three tests for a skill"
    colsLabel {"how": "how", "source": "from"}
    fmtMarkdown ["test", "source"]
    colsWidth {"test": "20%", "source": "26%"}
  nbTable t

nbText: """
Two studies from this year say what to expect:

- [SkillsBench](https://arxiv.org/abs/2602.12670) (February 2026) ran agents on about 85 tasks in
  11 domains with and without skills. Skills written by people raised the pass rate by 16 points
  on average, from 4.5 in software engineering to 52 in healthcare, and made 16 tasks worse.
  Skills the models wrote for themselves gave nothing. Focused skills, with two or three parts,
  beat complete documentation.
- [Vercel](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)
  (January 2026) tested agents writing Next.js 16 code. An 8 KB index of the docs in AGENTS.md passed
  every test; skills passed at most 79%, and when the agent did not call the skill it did no
  better than with no docs at all (53%).

The lesson for a small library: what every session needs goes in AGENTS.md, which is always
read; procedures that only some tasks need go in skills; and a skill that is not tested for
firing may as well not be there. The numbers come from the papers' summaries, read through
search: both pages were blocked from the sandbox.

### For tabelline and Operetta

Three small steps, in order, none of them for today:

1. **A skill for tabelline's users**, built by the docs: `skill.md` and `llms.txt` written from
   the specs while the pages are built, the way Great Docs does it for Great Tables, and served
   from the site. Every requirement already has an example that runs, so the skill would be
   checked on every push for free. Models trained before November 2026 have never seen
   tabelline, so this is where a skill helps most.
2. **A small benchmark** for it: five tasks (a table with a header and a spanner, formatted
   numbers, a styled column, a nimib page, a Great Tables snippet ported), each with and
   without the skill, graded by building the result.
3. **One skill per Operetta part**, kept in Operetta's repository when it has one and installed
   as a plugin, or copied into a project's `.claude/skills/` for cloud sessions: *add a devlog
   post*, *start a coverage map*, *publish a preview with deep links*. Picking a part would be
   adding its skill.

The first two are in tabelline's backlog.
"""

