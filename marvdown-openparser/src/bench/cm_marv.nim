import std/options, marvdown
let opts = MarkdownOptions(allowed: @[], allowTagsByType: some(tagAll), enableAnchors: false,
  enableEmailAutolinks: true, showFootnotes: false, parseYaml: false)
var m = newMarkdown(stdin.readAll, opts)
stdout.write m.toHtml()
