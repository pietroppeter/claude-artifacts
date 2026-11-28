## nim-markdown (GFM) and marvdown on one file, 50 runs each, in process: prints file, KB, ms, ms.
import std/[times, monotimes, options, os, strutils], markdown, marvdown
let src = readFile(paramStr(1))
const n = 50
var t = getMonoTime()
for i in 1..n: discard markdown.markdown(src, config=initGfmConfig())
let a = (getMonoTime()-t).inMicroseconds.float / n / 1000
let opts = MarkdownOptions(allowTagsByType: some(tagAll), enableAnchors: false, parseYaml: false)
t = getMonoTime()
for i in 1..n:
  var m = newMarkdown(src, opts)
  discard m.toHtml()
let b = (getMonoTime()-t).inMicroseconds.float / n / 1000
echo paramStr(1).parentDir.lastPathPart & "/" & extractFilename(paramStr(1)), "\t", src.len div 1024, "\t", formatFloat(a, ffDecimal, 2), "\t", formatFloat(b, ffDecimal, 2)
