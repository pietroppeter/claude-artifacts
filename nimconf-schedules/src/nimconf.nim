## Every NimConf schedule, read from the pages where it was published. The post (`index.nim`)
## shows and runs these procs one by one; `fetch.nim` runs them all and writes `data/`.
##
## Two kinds of page are read:
## - the schedule of each edition on conf.nim-lang.org (one page per year, 2020 to 2026);
## - the YouTube playlist of each edition, for the length of every video.
## Only Nim's standard library: `std/httpclient` to download, `std/strutils` to read.
import std/[httpclient, os, strutils, sequtils, json]

# ------------------------------------------------------------------------------------ editions

type
  Edition* = object
    year*: int
    date*: string        ## the day of the conference (ISO), from its page and the Nim blog
    page*: string        ## where its schedule was published
    playlists*: seq[(string, string)]  ## (track, YouTube playlist id)

const editions* = [
  Edition(year: 2020, date: "2020-06-20", page: "https://conf.nim-lang.org/2020/",
          playlists: @{"": "PLxLdEZg8DRwTIEzUpfaIcBqhsj09mLWHx"}),
  Edition(year: 2021, date: "2021-06-26", page: "https://conf.nim-lang.org/2021/",
          playlists: @{"": "PLxLdEZg8DRwRXNrY7yyGU0-g_GRSyRGKo"}),
  Edition(year: 2022, date: "2022-10-22", page: "https://conf.nim-lang.org/2022/",
          playlists: @{"": "PLxLdEZg8DRwSQQaK0UVRd1DaetVc3lIwr"}),
  Edition(year: 2024, date: "2024-10-26", page: "https://conf.nim-lang.org/2024/",
          playlists: @{"": "PLxLdEZg8DRwSkT93RIO-CoY-MxHOjYzs2"}),
  Edition(year: 2026, date: "2026-06-20", page: "https://conf.nim-lang.org/",
          playlists: @{"Projects": "PLHUPmLYoCMoY", "Social and Workflow": "PLHI4D93Ts8_k"})]

# ------------------------------------------------------------------------------------ download

const cacheDir* = currentSourcePath().parentDir / "cache"

proc download*(url: string): string =
  ## The page at `url`, downloaded once: later calls read the copy in `cache/`.
  let file = cacheDir / url.multiReplace(("https://", ""), ("/", "_"), ("?", "_"), ("=", "_"))
  if fileExists(file): return readFile(file)
  let proxy = getEnv("HTTPS_PROXY")   # the sandbox this was written in goes through a proxy
  let client = newHttpClient(proxy = (if proxy.len > 0: newProxy(proxy) else: nil))
  defer: client.close()
  result = client.getContent(url)
  createDir(cacheDir)
  writeFile(file, result)

# -------------------------------------------------------------------------------- reading HTML

iterator between*(s, open, close: string): string =
  ## Every piece of `s` that starts after `open` and ends before the next `close`.
  var i = s.find(open)
  while i >= 0:
    let start = s.find('>', i) + 1          # `open` can be `<td`: skip its attributes
    let stop = s.find(close, start)
    if stop < 0: break
    yield s[start ..< stop]
    i = s.find(open, stop)

func dropComments*(html: string): string =
  ## The page without its `<!-- ... -->`: the 2026 page keeps the 2024 schedule in one.
  var i = 0
  while i < html.len:
    let open = html.find("<!--", i)
    if open < 0:
      result.add html[i .. ^1]; break
    result.add html[i ..< open]
    let close = html.find("-->", open)
    i = if close < 0: html.len else: close + 3

func plain*(html: string): string =
  ## The text of a piece of HTML: no tags, the usual entities decoded, spaces collapsed.
  var inTag = false
  for c in html:
    if c == '<': inTag = true
    elif c == '>': inTag = false
    elif not inTag: result.add c
  result = result.multiReplace(("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""),
                               ("&#39;", "'"), ("&nbsp;", " ")).splitWhitespace.join(" ")

func videoId*(html: string): string =
  ## The YouTube id in the first link of `html` (`watch?v=<id>&...`), or "".
  let i = html.find("watch?v=")
  if i >= 0: html[i + 8 ..< i + 19] else: ""

# ------------------------------------------------------------------------------------ schedule

type
  Slot* = object
    year*: int
    track*: string      ## "" when the edition had one track
    start*: string      ## UTC, "11:00"
    kind*: string       ## talk, break or end
    title*: string
    speakers*: string
    video*: string      ## YouTube id, "" when the page links none

func slotKind*(title: string): string =
  let t = title.toLowerAscii
  if t.contains("break"): "break" elif t == "track end": "end" else: "talk"

func scheduleTable*(page: string): string =
  ## The schedule's `<table>`: the first one after its heading, comments dropped.
  let html = page.dropComments
  let at = html.find("id=\"time-schedule\"")
  for table in html[max(at, 0) .. ^1].between("<table", "</table>"):
    return table

func oneTrack*(year: int, table: string): seq[Slot] =
  ## 2020 to 2024: a row per talk, cells Talk name (with its video link), Starting time,
  ## Presenter. A break is a row with one cell.
  var start = ""
  for row in table.between("<tr", "</tr>"):
    let cells = toSeq(row.between("<td", "</td>"))
    if cells.len == 0: continue                       # the header row has <th>
    let title = cells[0].plain.replace(" (video)", "").replace(" (link)", "")
    if cells.len >= 3: start = cells[1].plain.replace(" UTC", "")
    result.add Slot(year: year, start: (if cells.len >= 3: start else: ""), kind: slotKind(title),
                    title: title, speakers: (if cells.len >= 3: cells[2].plain else: ""),
                    video: cells[0].videoId)

func splitSpeaker*(cell: string): (string, string) =
  ## 2026 writes "Speaker: Title" in one cell; a cell with no colon has no speaker.
  let i = cell.find(':')
  if i < 0 or cell.slotKind != "talk": ("", cell) else: (cell[0 ..< i].strip, cell[i + 1 .. ^1].strip)

func tracks*(year: int, table: string): seq[Slot] =
  ## 2026: a row per starting time, a column per track (the header names them).
  let names = toSeq(table.between("<th>", "</th>")).mapIt(it.plain.replace(" track", ""))
  for row in table.between("<tr", "</tr>"):
    let cells = toSeq(row.between("<td", "</td>"))
    if cells.len == 0: continue
    for col in 1 ..< cells.len:
      let text = cells[col].plain
      if text.len == 0: continue
      let (speaker, title) = splitSpeaker(text)
      result.add Slot(year: year, track: names[col], start: cells[0].plain, kind: slotKind(title),
                      title: title, speakers: speaker, video: cells[col].videoId)

func schedule*(year: int, page: string): seq[Slot] =
  ## The schedule of an edition from its page, whichever of the two layouts it has.
  let table = scheduleTable(page)
  if table.contains("Talk name"): oneTrack(year, table) else: tracks(year, table)

# ------------------------------------------------------------------------------------- YouTube

type
  Video* = object
    id*, title*: string
    seconds*: int
    playlist*: string

proc jsonText(s: string, at: int): string =
  ## The JSON string that starts at `at` (just after its opening quote), unescaped.
  var i = at
  while i < s.len and s[i] != '"':
    i += (if s[i] == '\\': 2 else: 1)
  parseJson("\"" & s[at ..< i] & "\"").getStr

func seconds*(length: string): int =
  ## "1:02:03" or "45:25" as seconds.
  for part in length.split(':'): result = result * 60 + part.parseInt

proc playlistVideos*(page, playlist: string): seq[Video] =
  ## The videos of a playlist page: YouTube puts its data in the page as JSON, one
  ## `lockupViewModel` per video, with its id, its title and the length on its thumbnail.
  const id = "\"contentId\":\""
  const title = "\"title\":{\"content\":\""
  const badge = "\"thumbnailBadgeViewModel\":{\"text\":\""
  for part in page.split("\"lockupViewModel\":{")[1 .. ^1]:
    let (i, t, b) = (part.find(id), part.find(title), part.find(badge))
    if i < 0 or t < 0 or b < 0: continue
    result.add Video(id: part.jsonText(i + id.len), title: part.jsonText(t + title.len),
                     seconds: part.jsonText(b + badge.len).seconds, playlist: playlist)

func normal(s: string): string =
  for c in s.toLowerAscii:
    if c.isAlphaNumeric: result.add c

func videoTalk*(title: string): string =
  ## The talk in a video's title: "Speaker: Title (NimConf 2026)" is "Title".
  result = title
  let paren = result.rfind(" (NimConf")
  if paren >= 0: result = result[0 ..< paren]
  let colon = result.find(": ")
  if colon >= 0: result = result[colon + 2 .. ^1]

func matchVideo*(slot: Slot, videos: openArray[Video]): string =
  ## The video of a slot that the schedule does not link (2026): the one whose talk, as YouTube
  ## writes it, starts the slot's title or is started by it ("Why I Nim" and "Why I Nim - a love
  ## letter to ..."), ignoring case, spaces and punctuation.
  if slot.kind != "talk": return ""
  let mine = slot.title.normal
  for v in videos:
    let theirs = v.title.videoTalk.normal
    if mine.startsWith(theirs) or theirs.startsWith(mine): return v.id

# ----------------------------------------------------------------------------- the data files

proc tsvRows(path: string): seq[seq[string]] =
  ## The rows of a TSV file of `data/`, without its comment lines and its header.
  for line in readFile(path).splitLines:
    if line.len == 0 or line.startsWith("#"): continue
    result.add line.split('\t')
  result.delete(0)

proc readSlots*(path: string): seq[Slot] =
  for r in tsvRows(path):
    result.add Slot(year: r[0].parseInt, track: r[1], start: r[2], kind: r[3], title: r[4],
                    speakers: r[5], video: r[6])

proc readVideos*(path: string): seq[Video] =
  for r in tsvRows(path):
    result.add Video(playlist: r[2], id: r[3], seconds: r[4].parseInt, title: r[5])

# ----------------------------------------------------------------------------------- speakers

const sameSpeaker* = {
  # by hand: the pages spell some names in more than one way
  "Mamy André-Ratsimbazafy": "Mamy Ratsimbazafy",
  "Hugo Granstrom": "Hugo Granström",
  "Juan Gomez": "Juan M. Gomez",
  "Trayambak Ray": "Trayambak Rai",
  "Andre von Houck": "Andre von Houck (treeform)",
  "treeform": "Andre von Houck (treeform)"}

func people*(speakers: string): seq[string] =
  ## The speakers of a slot, one name each: "A and B" and "A & B" are two.
  for name in speakers.multiReplace((" and ", "|"), (" & ", "|")).split('|'):
    let name = name.strip
    if name.len == 0: continue
    var same = name
    for (spelled, one) in sameSpeaker:
      if name == spelled: same = one
    result.add same
