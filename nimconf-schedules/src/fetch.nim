## Downloads every NimConf schedule and playlist (`nimconf.nim`) and writes `data/`:
## `slots.tsv` (every row of every schedule) and `videos.tsv` (every video of every playlist).
## Run from this folder: `nim r -d:ssl fetch.nim`. Pages are kept in `cache/` (not committed);
## delete it to download them again.
import std/[os, strformat, sequtils]
import nimconf

const dataDir = currentSourcePath().parentDir / "data"
let fetched = getEnv("FETCHED", "2026-11-10")   # the day the pages were read, written in the files

var slots = &"# NimConf schedules, from conf.nim-lang.org, read {fetched}\n" &
            "year\ttrack\tstart\tkind\ttitle\tspeakers\tvideo\n"
var videos = &"# NimConf playlists on YouTube (channel @nimprogramminglanguage3130), read {fetched}\n" &
             "year\ttrack\tplaylist\tid\tseconds\ttitle\n"
for e in editions:
  var all: seq[Video]
  for (track, list) in e.playlists:
    for v in download("https://www.youtube.com/playlist?list=" & list).playlistVideos(list):
      all.add v
      videos.add &"{e.year}\t{track}\t{list}\t{v.id}\t{v.seconds}\t{v.title}\n"
  for s in schedule(e.year, download(e.page)):
    # the video the schedule links, if its playlist has it; else the playlist's video of the talk
    let video = if all.anyIt(it.id == s.video): s.video else: s.matchVideo(all)
    if s.video.len > 0 and video != s.video: echo &"{e.year} {s.title}: {s.video} is not in the playlist, {video} is"
    slots.add &"{s.year}\t{s.track}\t{s.start}\t{s.kind}\t{s.title}\t{s.speakers}\t{video}\n"
writeFile(dataDir / "slots.tsv", slots)
writeFile(dataDir / "videos.tsv", videos)
echo "wrote ", dataDir / "slots.tsv", " and ", dataDir / "videos.tsv"
