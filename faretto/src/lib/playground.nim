## The lighthouse in the page: faretto's VM compiled to JavaScript (`nim js`), running the
## image that the page build saved. Every 450 ms it calls the image's own `tick(capo)`;
## the chips accept a new `lit` (its NIF was made by Nimony when the page was built),
## and the buttons do `become`, install a MetaLink, snapshot and restore the whole image.
import std/[dom, strutils]
import ../faretto/vm

var
  v: VM
  playing = true
  snapshot = ""
  strip: seq[string]
  link: MetaLink
  current = 0

proc el(id: string): Element = document.getElementById(cstring(id))
proc setText(e: Element; s: string) = e.textContent = cstring(s)

proc nifOf(kind: string; i = -1): string =
  for e in document.querySelectorAll(cstring("script[type=\"text/plain\"]")):
    if kind == "image" and e.id == "pg-image": return $e.textContent
    if kind == "variant" and e.classList.contains("pg-nif") and
       $e.getAttribute("data-v") == $i: return $e.textContent

proc showLog() =
  let log = el("pg-log")
  var html = ""
  for i in countdown(v.img.changes.high, 0):
    html.add "<li>" & v.img.changes[i].what.multiReplace(("&", "&amp;"), ("<", "&lt;")) & "</li>"
  if html.len == 0: html = "<li>(nothing accepted yet)</li>"
  log.innerHTML = cstring(html)

proc lampKind(): string = v.field(v.field(v.global("capo"), "lamp"), "kind").s

proc render(on: bool) =
  el("pg-beams").setAttribute("opacity", if on: "1" else: "0")
  let lamp = el("pg-lamp")
  if on: lamp.classList.add("on") else: lamp.classList.remove("on")
  let svg = el("faro")
  if lampKind() == "oil": svg.classList.add("oil") else: svg.classList.remove("oil")
  el("pg-strip").setText(strip.join(""))
  var rep = v.call("report", v.global("capo")).s
  if link != nil: rep.add "  ·  MetaLink hits: " & $link.hits
  el("pg-report").setText(rep)
  el("pg-insp").setText("capo -> " & v.inspect(v.global("capo")) & "\nspare -> " & v.inspect(v.global("spare")))

proc step() =
  if not playing: return
  let g = v.call("tick", v.global("capo")).s
  strip.add g
  if strip.len > 24: strip.delete(0)
  render(g == "█")

proc markChip(i: int) =
  current = i
  for b in document.querySelectorAll(cstring(".pg-chip")):
    b.setAttribute("aria-pressed", if $b.getAttribute("data-v") == $i: "true" else: "false")
  for p in document.querySelectorAll(cstring(".pg-src")):
    if $p.getAttribute("data-v") == $i: p.removeAttribute("hidden") else: p.setAttribute("hidden", "")

proc accept(i: int) =
  ## The browser can't run Nimony, so the page build ran it: each chip holds the NIF
  ## that `nimony check` wrote for one version of lit. Accepting = one table entry.
  let tree = parseNif(nifOf("variant", i))
  let sym = tree[0].text
  let old = v.img.procs[sym]
  let src = $el("faro").querySelector(cstring(".pg-src[data-v=\"" & $i & "\"]")).textContent
  v.img.procs[sym] = ProcDef(sym: sym, name: old.name, params: old.params, body: tree,
                             source: src, version: old.version + 1)
  v.img.changes.add Change(what: "accepted lit v" & $(old.version + 1) & ": " &
                           $el("faro").querySelector(cstring(".pg-chip[data-v=\"" & $i & "\"]")).textContent,
                           source: src)
  markChip(i)
  showLog()

proc toggleLink(btn: Element) =
  if link == nil:
    link = MetaLink(name: "count flashes", control: after)
    for n in v.assignmentsTo("flashes"): n.install link
    btn.setAttribute("aria-pressed", "true")
    btn.innerHTML = "🔗 MetaLink installed: remove"
  else:
    for n in v.assignmentsTo("flashes"): n.uninstall link
    link = nil
    btn.setAttribute("aria-pressed", "false")
    btn.innerHTML = "🔗 MetaLink: count flashes"

proc boot() =
  v = newVM(loadImage(nifOf("image")))
  el("pg-play").addEventListener("click", proc (e: Event) =
    playing = not playing
    el("pg-play").innerHTML = if playing: "⏸ Pause" else: "▶ Play")
  el("pg-snap").addEventListener("click", proc (e: Event) =
    snapshot = saveImage(v.img)
    el("pg-restore").removeAttribute("disabled")
    el("pg-snap").innerHTML = cstring("📸 Snapshot (" & $snapshot.len & " bytes)"))
  el("pg-restore").addEventListener("click", proc (e: Event) =
    if snapshot.len == 0: return
    v = newVM(loadImage(snapshot))
    link = nil
    let b = el("pg-link")
    b.setAttribute("aria-pressed", "false"); b.innerHTML = "🔗 MetaLink: count flashes"
    # which lit is in the restored image? match its source against the chips
    let src = canonical(v.procNode("lit"))
    for p in document.querySelectorAll(cstring(".pg-nif")):
      if canonical(parseNif($p.textContent)) == src: markChip(parseInt($p.getAttribute("data-v")))
    showLog()
    render(false))
  el("pg-become").addEventListener("click", proc (e: Event) =
    v.img.become(v.field(v.global("capo"), "lamp"), v.global("spare"))
    render(false))
  el("pg-link").addEventListener("click", proc (e: Event) = toggleLink(el("pg-link")))
  proc onChip(i: int): proc (e: Event) =
    result = proc (e: Event) =
      if i != current: accept(i)
  for b in document.querySelectorAll(cstring(".pg-chip")):
    b.addEventListener("click", onChip(parseInt($b.getAttribute("data-v"))))
  showLog()
  render(false)
  discard window.setInterval(step, 450)

boot()
