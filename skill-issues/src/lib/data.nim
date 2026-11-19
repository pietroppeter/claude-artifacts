## The numbers of the "Skill issues" explainer: what the paper reports, what we read off its
## Figure 4, and what we count at build time in two snapshots of SKILL.md files (data/).
import std/[os, strutils, algorithm, math, unicode]

type
  Curve* = object
    skill*: string            ## the Bauplan skill, e.g. "bauplan-safe-ingestion"
    validation*, test*: seq[float]  ## reward by GEPA candidate; index 0 is the seed skill
  Pick* = object
    candidate*: int
    validation*, test*, gain*: float   ## gain: relative change of test reward vs the seed, in %

# Read by eye off the six panels of the paper's Figure 4 (arXiv 2606.01185v2), to about ±0.01.
# The paper does not publish the numbers behind the plots.
const curves* = [
  Curve(skill: "bauplan-data-pipeline",
    validation: @[0.790, 0.865, 0.835, 0.845, 0.858, 0.852, 0.860, 0.846, 0.841, 0.821, 0.835, 0.846, 0.863, 0.855, 0.848, 0.835, 0.853],
    test:       @[0.722, 0.805, 0.835, 0.847, 0.835, 0.846, 0.853, 0.800, 0.824, 0.794, 0.824, 0.824, 0.836, 0.858, 0.824, 0.840, 0.858]),
  Curve(skill: "bauplan-data-assessment",
    validation: @[0.920, 0.929, 0.934, 0.944, 0.944, 0.925, 0.939, 0.934, 0.954, 0.934],
    test:       @[0.942, 0.985, 0.980, 0.985, 0.960, 0.965, 0.965, 0.975, 0.980, 0.950]),
  Curve(skill: "bauplan-data-quality-checks",
    validation: @[0.743, 0.876, 0.877, 0.848, 0.833, 0.921, 0.864, 0.860, 0.950, 0.935, 0.908, 0.790, 0.834, 0.850, 0.876, 0.820, 0.937],
    test:       @[0.743, 0.848, 0.834, 0.940, 0.790, 0.940, 0.940, 0.848, 0.910, 0.955, 0.895, 0.880, 0.925, 0.803, 0.803, 0.864, 0.925]),
  Curve(skill: "bauplan-explore-data",
    validation: @[0.955, 0.980, 0.965, 0.975, 0.980, 0.990, 0.985, 0.990, 0.990, 0.985, 0.995, 0.995, 0.985],
    test:       @[0.970, 0.980, 0.970, 0.980, 0.985, 0.985, 0.985, 0.990, 0.975, 0.990, 0.985, 0.975, 0.985]),
  Curve(skill: "bauplan-debug-and-fix-pipeline",
    validation: @[0.860, 0.859, 0.879, 0.888, 0.810, 0.821, 0.832, 0.867, 0.768, 0.927],
    test:       @[0.867, 0.909, 0.871, 0.922, 0.838, 0.926, 0.870, 0.907, 0.837, 0.855]),
  Curve(skill: "bauplan-safe-ingestion",
    validation: @[0.763, 0.921, 0.936, 0.903, 0.936, 0.895, 0.917, 0.840, 0.931, 0.948, 0.948],
    test:       @[0.792, 0.879, 0.951, 0.939, 0.914, 0.895, 0.908, 0.880, 0.888, 0.945, 0.946])]

func short*(skill: string): string = skill.replace("bauplan-", "")

func pickBy(c: Curve, scores: seq[float]): Pick =
  ## The candidate with the highest score (the first one on ties), seed excluded.
  var best = 1
  for i in 1 ..< scores.len:
    if scores[i] > scores[best]: best = i
  Pick(candidate: best, validation: c.validation[best], test: c.test[best],
       gain: 100 * (c.test[best] / c.test[0] - 1))

func byValidation*(c: Curve): Pick = c.pickBy(c.validation)
  ## The honest rule: GEPA picks on validation, test stays held out.
func byTest*(c: Curve): Pick = c.pickBy(c.test)
  ## Peeking: the best test point among all candidates.

func mean*(xs: openArray[float]): float = xs.sum / xs.len.float

# ---------------------------------------------------------------- the paper's tables
type Share* = tuple[name, what: string, pct: int]
const
  computeApis*: seq[Share] = @[("Import", "append data to a table", 40), ("Query", "run a SQL query", 35),
    ("Run", "run a pipeline", 25)]
  branchApis*: seq[Share] = @[("Merge", "merge a ref into a branch", 43), ("Delete", "delete a branch", 37),
    ("Create", "create a branch", 11), ("Get", "details of a branch", 8), ("List", "list branches", 1)]
  readTasks*: seq[Share] = @[("Exploration", "", 139), ("Assessment", "", 126), ("Data quality check", "", 100)]
  writeTasks*: seq[Share] = @[("New pipeline", "", 209), ("Fix table", "", 100), ("Ingestion", "", 106)]
  lengthFactor* = 27.2   ## optimized skills vs seeds, in characters (paper, Section 4)

# ---------------------------------------------------------------- the snapshots in data/
type
  SkillFile* = object
    name*, owner*: string
    chars*: int
  GraderLevel* = enum glTrace = "trace", glState = "state", glJudge = "judge"
  EvalCase* = object
    skill*, name*: string
    graders*: array[GraderLevel, int]

func levelOf*(graderType: string): GraderLevel =
  ## `claude plugin eval` grader types, mapped to the paper's three levels of verification.
  case graderType
  of "tool_used": glTrace                  # did the agent call the Skill tool?
  of "file_exists", "regex": glState       # what is on disk after the run
  else: glJudge                            # "llm": a rubric read by a model

proc chars(path: string): int = readFile(path).runeLen   # characters, not bytes

proc bauplanSeeds*(dir: string): seq[SkillFile] =
  for f in walkFiles(dir / "*.md"):
    result.add SkillFile(name: f.splitFile.name, owner: "bauplan", chars: chars(f))
  result.sort(proc (a, b: SkillFile): int = cmp(a.name, b.name))

proc pietroSkills*(dir: string): seq[SkillFile] =
  for d in walkDirs(dir / "*"):
    if fileExists(d / "SKILL.md"):
      result.add SkillFile(name: d.lastPathPart, owner: "pietro", chars: chars(d / "SKILL.md"))
  result.sort(proc (a, b: SkillFile): int = cmp(b.chars, a.chars))

proc evalCases*(dir: string): seq[EvalCase] =
  for d in walkDirs(dir / "*" / "evals" / "*"):
    var c = EvalCase(skill: d.parentDir.parentDir.lastPathPart, name: d.lastPathPart)
    for g in walkFiles(d / "graders" / "*.md"):
      for line in readFile(g).splitLines:
        if line.startsWith("type:"):
          inc c.graders[levelOf(line["type:".len .. ^1].strip)]
    result.add c
  result.sort(proc (a, b: EvalCase): int = cmp((a.skill, a.name), (b.skill, b.name)))

func pct1*(x: float): string = formatFloat(x, ffDecimal, 1)
func signed*(x: float): string = (if x >= 0: "+" else: "−") & pct1(abs x)
