## Part two: Operetta, a first sketch.
nbText: """
Operetta is a way to make an open source library with an AI agent. It is not a tool and not a
template: it is a list of parts (a setup script, an explainer, specs, a devlog, a coverage map,
skills, ...), and a project uses the ones it needs. Each part is small, and each one was
already made once, in a project of the last month (the [first part](#part-one)
says where). Until now they were copied by hand from one repo to the next, and every copy
drifted a little; with a name they become something to pick from, and to improve in one place.

The name is **Operetta**. It came with Opus 5.5, the model the month was built with: a small
opus. And an operetta is a light, modular show, with songs between spoken parts; a company
can stage a short one with a few numbers or a long one with all of them.

### The idea in one sentence

> *The explainer is where the thinking happens; every other part keeps it true.*

A page that explains the idea, made with Claude and read on the phone, is how a project moves:
first as a claude-artifacts sketch, then as the living explainer of a repo. Specs, the devlog,
coverage maps, books and benchmarks are there so that the page, the code and Claude's next
session agree.

### Five groups of parts

Each group has an Italian name from the theatre, so the five are easy to tell apart, and a plain
one, so they are easy to understand.
"""

type Gruppo = object
  key, name, plain, pick: string
  parts: seq[string]
let gruppi = @[
  Gruppo(key: "scena", name: "Scena", plain: "the stage: what every repo needs",
         pick: "always, from the first commit",
         parts: @["agents", "setup", "pages", "disclosure"]),
  Gruppo(key: "prove", name: "Prove", plain: "rehearsals: places to think",
         pick: "from the first idea",
         parts: @["artifact", "explainer", "devlog", "living", "look"]),
  Gruppo(key: "partitura", name: "Partitura", plain: "the score: what the code must do",
         pick: "when you start saying \"it should\"",
         parts: @["openspec", "examples", "backlog"]),
  Gruppo(key: "repertorio", name: "Repertorio", plain: "the repertoire: growing toward a reference",
         pick: "when there is a library to follow (Polars, gt) or releases to plan",
         parts: @["coverage", "threads", "design", "useit", "book", "bench"]),
  Gruppo(key: "suggeritore", name: "Suggeritore", plain: "the prompter: help for other people's agents",
         pick: "when others use it, or many sessions work on it",
         parts: @["skills"]),
]

block:
  type Row = object
    gruppo, part, does: string
  var rows: seq[Row]
  for g in gruppi:
    for k in g.parts:
      let p = part(k)
      rows.add Row(gruppo: &"{g.name}, {g.plain}; pick it {g.pick}", part: &"**{p.name}**", does: p.does)
  let t = tabella(rows, rownameCol = "part", groupnameCol = "gruppo"):
    tabHeader "Operetta's parts", "by group, with what each one is for"
    colsLabel {"does": "what it is for"}
    fmtMarkdown "part"
    colsWidth {"part": "34%"}
    tabSourceNote md("Every part comes from the month: [where each first appeared](#part-one).")
  nbTable t

nbText: """
The prompter, *il suggeritore*, sits in a box under the stage and whispers the lines to the
singers when they need them, and only then. That is what a skill does for an agent, which is
why the fifth group has his name and why it has only one part today: it is the next one to
grow, and the subject of the [third part](#part-three).

### Pick by kind of project

Not every project needs every part. Here is what each kind of project from the month picked,
and what it could skip, from the one that needs least to the one that needs most:
"""

block:
  type Kind = object
    kind, examples, picks, skips: string
  let rows = @[
    Kind(kind: "A sketch", examples: "the diagrams history, declarative dragging before zogyn",
         picks: "an artifact page: Prove only", skips: "everything else, until the idea holds"),
    Kind(kind: "An experiment", examples: "cicak's hot code reloading, nanuqy",
         picks: "Scena, a devlog, benchmarks", skips: "specs, until it becomes a tool"),
    Kind(kind: "An app or a game", examples: "parloku, cadero",
         picks: "Scena, an explainer, a look of its own, specs as scenarios that run (parloku's drags)", skips: "coverage, book, releases"),
    Kind(kind: "A small new library", examples: "zogyn, diagrammari",
         picks: "Scena, an explainer, a devlog, specs with runnable examples", skips: "Repertorio: there is no reference to cover"),
    Kind(kind: "A talk", examples: "Sailing Seas of Scientific Nim",
         picks: "Scena, specs with a schema of its own (abstract, outline, islands), a talk log", skips: "releases, coverage"),
    Kind(kind: "A port of a reference", examples: "nanuq (Polars), tabelline (gt and Great Tables)",
         picks: "everything: the coverage map and three threads per release carry it", skips: "nothing; benchmarks when speed is a claim"),
    Kind(kind: "A library with users", examples: "nimib",
         picks: "what it has, plus the Suggeritore: skills and an llms.txt for its users", skips: "parts a mature project already does another way"),
  ]
  var shown: seq[tuple[kind, picks, skips: string]]
  for r in rows: shown.add (&"**{r.kind}**<br>{r.examples}", r.picks, r.skips)
  let t = tabella(shown, rownameCol = "kind"):
    tabHeader "Seven kinds of project", "and the parts each one picks"
    colsLabel {"picks": "picks", "skips": "can skip"}
    fmtMarkdown "kind"
    colsWidth {"kind": "30%"}
  nbTable t

nbText: """
### Grow by adding

A project does not pick once. It starts small and adds a group when it reaches the stage that
needs it. Each stage has a sign that says it is time:
"""

block:
  type Stage = object
    stage, adds, sign: string
  let rows = @[
    Stage(stage: "0 · sketch", adds: "Prove: an artifact page", sign: "an idea worth a page"),
    Stage(stage: "1 · repo", adds: "Scena; the explainer and the devlog move into the repo", sign: "the page still interests you a day later"),
    Stage(stage: "2 · behaviour", adds: "Partitura: specs, examples that run, a backlog", sign: "you write \"it should\" twice, or a fix breaks something agreed"),
    Stage(stage: "3 · releases", adds: "Repertorio: coverage, roadmap, three threads, a book", sign: "there is a reference to follow, or a 0.1 to tag"),
    Stage(stage: "4 · users", adds: "Suggeritore: skills, llms.txt", sign: "someone else, or their agent, uses it"),
  ]
  let t = tabella(rows, rownameCol = "stage"):
    tabHeader "Five stages", "and what each one adds"
    colsLabel {"adds": "adds", "sign": "time to add it when"}
    colsWidth {"stage": "20%"}
  nbTable t

nbText: """
nanuq reached stage 3 in its first week. tabelline went to stage 3 on its first day, because it
follows gt and Great Tables from the start. parloku stopped at 2, which is right for a game.

### A part has variations

Copying showed that a part is not one template. Each has a few ways to be done, and a project
picks one:

- **Specs.** nanuq writes the proposal and the implementation in separate pull requests;
  tabelline and parloku in one. parloku's scenarios are drags that run and animate on the specs
  page; the talk has a schema of its own, with an abstract, an outline and its islands.
- **Book.** nanuq's book is a repository of its own, with a CI that rebuilds only the chapters
  that changed; tabelline's book will live in the main repository, until its CI grows heavy.
- **Look.** Every project has its own theme; tabelline has two, and its devlog posts can have one
  each.
- **Explainers.** Nim only, or Nim, Python and R in tabs, checked to agree.

So Operetta describes each part with its variations and says when to pick which, rather than
shipping one way of doing it.

### Still open

- **Where it lives.** A repository of its own, later, holding the parts as short documents, a
  small template for each, and one skill per part (*add a devlog post*, *start a coverage map*,
  *publish a preview with deep links*). Installed as a plugin, the skills would be how a project
  picks parts: the third part explains why that fits.
- **Keeping copies in step.** Today a part improved in one repo stays there. With skills, the
  next session in any project that picked it gets the improved version.
- **The garden.** A place for ideas and notes that are neither backlog nor posts; how it works is
  not decided yet, so it is not a part yet.
- **How heavy it gets.** Every part costs CI time and attention. The rule so far: a part comes in
  when a stage's sign shows, not before.

This is a sketch. The next projects will move parts between groups, split some and drop others,
and that is how it should go: *complicare è facile, semplificare è difficile*.
"""

