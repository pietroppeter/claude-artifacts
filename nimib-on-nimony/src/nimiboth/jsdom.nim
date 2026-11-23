## The few DOM bindings a nbJs block needs, for both JS back ends: Nimony's (`nimony j`)
## and Nim 2's (`nim js`). nbJsFromCode puts `import jsdom` in front of every block.
when defined(nimony):
  import std/syncio
  export syncio
  type Element* = distinct pointer         ## a JS object handle, bridged by `importjs`
  proc toNim*(c: cstring): string {.importjs: "#".}   ## a JS string becomes a Nim string
  template toJs*(s: string): cstring =
    (var tmp = s; toCString(tmp))
  template sync*(body: untyped) =
    ## a callback that touches a global: Nimony asks for it to be said
    {.cast(assumeSync).}:
      body
else:
  type Element* {.importc.} = ref object
  proc toNim*(c: cstring): string = $c
  template toJs*(s: string): cstring = cstring(s)
  template sync*(body: untyped) = body

proc byId*(id: cstring): Element {.importjs: "document.getElementById(#)".}
proc textContent*(e: Element): cstring {.importjs: "#.textContent".}
proc setHtml*(e: Element; html: cstring) {.importjs: "#.innerHTML = #".}
proc setAttr*(e: Element; name, value: cstring) {.importjs: "#.setAttribute(#, #)".}
proc onClick*(e: Element; cb: proc () {.nimcall.}) {.importjs: "#.addEventListener('click', #)".}
proc queryAll*(sel: cstring; attr: cstring; value: cstring) {.importjs: "document.querySelectorAll(#).forEach(function (d) { d.setAttribute(#, #) })".}
proc removeAll*(sel: cstring; attr: cstring) {.importjs: "document.querySelectorAll(#).forEach(function (d) { d.removeAttribute(#) })".}
proc addClassAll*(sel, cls: cstring) {.importjs: "document.querySelectorAll(#).forEach(function (d) { d.classList.add(#) })".}
proc removeClassAll*(sel, cls: cstring) {.importjs: "document.querySelectorAll(#).forEach(function (d) { d.classList.remove(#) })".}
proc toggleParentOnClick*(e: Element; sel, cls: cstring) {.importjs: "#.addEventListener('click', function (ev) { var t = ev.target.closest(#); if (t) t.parentNode.classList.toggle(#) })".}
  ## one listener for many elements: a click on an element matching `sel` toggles `cls` on its parent
