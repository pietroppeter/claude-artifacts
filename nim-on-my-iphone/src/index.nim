## A nimib explainer: the fastest path from Nim source to an app on *your own* iPhone.
## Build from the page folder:  sh src/deps.sh && nim r src/index.nim   (writes ../index.html)
import std/[os, osproc, strutils, strformat, times, json]
import nimib

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
# scratch files (core.nim, ioscache/) go to a temp folder, not the repo
let work = getTempDir() / "nim-on-my-iphone"
createDir(work)
setCurrentDir(work)
nb.title = "Nim on My iPhone"

# ---------------------------------------------------------------- theme ---
# Replace water.css + remote highlight assets with an inline "Platinum" theme.
const
  platinumCss = staticRead("platinum.css")
  pipelineHtml = staticRead("pipeline.html")
  calendarHtml = staticRead("calendar.html")
  checklistHtml = staticRead("checklist.html")
nb.doc.context["stylesheet"] = %("""
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=Pixelify+Sans:wght@400;600&display=swap" rel="stylesheet">
<style>""" & platinumCss & "</style>")
nb.doc.context["highlight"] = %""
nb.doc.context["highlightJs"] = %"""
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
<script>document.querySelectorAll('pre code:not(.nohighlight)').forEach(function(el){ if(!/language-|hljs/.test(el.className)) el.classList.add('nohighlight'); }); hljs.highlightAll();</script>
"""

func menuBar(blk: JsonNode, nb: Nb): string =
  """<header class="menubar" role="banner">
  <span class="mb-logo" aria-hidden="true">&#x2318;</span>
  <span class="mb-item"><b>File</b></span><span class="mb-item">Edit</span><span class="mb-item">View</span><span class="mb-item">Special</span>
  <span class="mb-spacer"></span>
  <span class="mb-item mb-title">Nim on My iPhone</span>
</header>"""
nb.backend.partials["header"] = menuBar

# Helpers: a classic window around a group of blocks.
var winCount = 0
template window(title: string, body: untyped) =
  inc winCount
  nbRawHtml("<section class=\"win\" aria-labelledby=\"w" & $winCount & "\"><div class=\"titlebar\"><span class=\"closebox\" aria-hidden=\"true\"></span><h2 id=\"w" & $winCount & "\" class=\"wtitle\">" & title & "</h2><span class=\"zoombox\" aria-hidden=\"true\"></span></div><div class=\"win-body\">")
  body
  nbRawHtml("</div></section>")

template code(lang, src: string) =
  # highlight.js from cdnjs has no Nim grammar, so Nim is highlighted at build time like nbCode blocks.
  if lang == "nim":
    nbRawHtml("<pre><code class=\"nohighlight nim hljs\">" & highlightNim(src) & "</code></pre>")
  else:
    nbRawHtml("<pre><code class=\"language-" & lang & "\">" & src.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;")) & "</code></pre>")

# ----------------------------------------------------------------- intro ---
nbRawHtml """<section class="hero">
<div class="hero-icon" aria-hidden="true"><div class="phone"><div class="screen"><span>N</span></div></div></div>
<div>
<p class="eyebrow">An explorable explanation · written in nimib</p>
<h1>Nim on My iPhone</h1>
<p class="lede">What it really takes to build a Nim app and keep it running on your own phone, with no App Store and no distribution.</p>
</div>
</section>"""

window "Read Me First":
  nbText """
**The short answer.** You do **not** need the paid Apple Developer Program to put an app on your own iPhone.
A free Apple ID gives you a *Personal Team* in Xcode, and Xcode signs the app for your device.
The catch is that the signature lasts **7 days**: after that the app refuses to launch until you plug in and press Run again.

What you cannot avoid is **a Mac with Xcode**. Nim itself is happy anywhere (it writes C), but the iOS SDK,
the Apple linker and code signing only exist inside Xcode.

**The fastest route** I would take, in one sentence: make a plain SwiftUI app from Xcode's template, compile your Nim code
into a static library with one build-phase script, call it from Swift, and run it on your phone with your free Apple ID.
Budget an afternoon, most of it waiting for Xcode to download.
"""
  nbRawHtml """<div class="verdict-row">
<div class="chip ok"><b>Free Apple ID</b><span>Own device · 7-day signature · enough to start</span></div>
<div class="chip warn"><b>$99 / year program</b><span>1-year signature · TestFlight · only if re-signing annoys you</span></div>
<div class="chip need"><b>Mac + Xcode</b><span>Not optional for a native app</span></div>
</div>"""

# ------------------------------------------------------------- pipeline ---
window "The Pipeline: from .nim to a tap on the home screen":
  nbText """
Every native iOS app, whatever language it starts in, goes through the same stations. Nim only owns the first two.
**Click a station** to see what happens there, and flip the target between your iPhone and the Simulator to watch the flags change.
"""
  nbRawHtml pipelineHtml

# ------------------------------------------------------- proof on Linux ---
window "Proof: Nim already speaks iOS (even on Linux)":
  nbText """
This page was rendered on a Linux box with no Apple software at all. The block below really ran while the page was built:
it asks the Nim compiler to *generate* the C for an iOS arm64 static library, then lists what came out.
The Mac is only needed for the next step, turning that C into ARM machine code against Apple's SDK.
"""
  writeFile("core.nim", """
proc fib*(n: cint): cint {.exportc, cdecl.} =
  if n < 2: n else: fib(n - 1) + fib(n - 2)

proc nimVersion*(): cstring {.exportc, cdecl.} = NimVersion
""")
  nbCode:
    let cmd = "nim c --os:ios --cpu:arm64 --app:staticlib --noMain:on " &
              "-d:release --compileOnly --nimcache:ioscache --hints:off core.nim"
    let (output, exitCode) = execCmdEx(cmd)
    echo "exit code: ", exitCode, output.strip
    for f in walkFiles("ioscache/*.c"):
      echo "  generated ", f.extractFilename.replace("@m", "").split("@s")[^1]
    let main = readFile("ioscache/@mcore.nim.c")
    echo "exports NimMain: ", "N_CDECL(void, NimMain)(void)" in main
    echo "exports fib:     ", "fib" in main
  nbText """
`--os:ios` flips on `defined(ios)` everywhere in the standard library, `--app:staticlib` produces a `.a` instead of
a program, and `--noMain` stops Nim from writing a C `main()`, because on iOS **UIKit owns `main`**.
Your Nim code is a library that the app calls into; you call `NimMain()` once at startup to initialise Nim's globals.
"""

# ----------------------------------------------------------- signing ---
window "The Apple Part: signing, explained with a calendar":
  nbText """
iOS runs only code signed by a certificate Apple issued, for a device Apple knows about, in an app ID Apple registered.
Xcode bundles all three into a **provisioning profile** and does it for you when *Automatically manage signing* is on.
The only difference between free and paid that you will feel day to day is **how long that profile lives**.

**Click days** on the calendar to mark when you plugged in and pressed *Run* in Xcode. Green days the app opens; red days it shows
*"…is no longer available"* and refuses to launch. Your data inside the app survives a re-sign.
"""
  nbRawHtml calendarHtml
  nbText """
| | Free Apple ID (Personal Team) | Apple Developer Program |
|---|---|---|
| Cost | €0 | $99 / year (€99 in the eurozone) |
| Signature lifetime | 7 days | 1 year (profile), as long as membership is active |
| Devices | the ones you plug into Xcode | up to 100 iPhones per year |
| Apps at once | 3 free-signed apps per device | no practical limit |
| New app IDs | 10 per 7 days | unlimited |
| Capabilities | basics only: no push notifications, iCloud, Apple Pay, Sign in with Apple | all |
| Share with friends | no | TestFlight (builds last 90 days) or App Store |
| Approval needed | none | none for your own devices |

Two settings on the iPhone itself trip up everyone the first time. Since iOS 16 you must turn on
**Developer Mode** (*Settings → Privacy & Security → Developer Mode*, then restart), and the first launch of a free-signed app needs
**trusting your certificate** (*Settings → General → VPN & Device Management → your Apple ID → Trust*).
"""

# ------------------------------------------------------- the 3 shapes ---
window "Three Ways to Shape a Nim iOS App":
  nbText """
Nim cannot draw an iOS screen on its own; something has to talk to UIKit. These are the three realistic options, from easiest to most Nim-pure.
"""
  nbRawHtml """<div class="shapes">
<article class="shape pick"><h3>A. SwiftUI shell + Nim core</h3><p class="tag">Recommended to start</p>
<p>Xcode's template gives you a working app. Nim compiles to <code>libnimcore.a</code>; Swift calls your <code>{.exportc.}</code> procs through a one-file C header. You write a few lines of Swift for the UI and keep all logic in Nim.</p>
<p class="meta">Swift you write: ~20 lines · Risk: low</p></article>
<article class="shape"><h3>B. WebView shell + Nim (the wiish way)</h3><p class="tag">Great if you think in HTML</p>
<p>A tiny Objective-C app hosts a <code>WKWebView</code>. The UI is HTML/JS (could even be a nimib page or Nim compiled to JS) and messages pass between JavaScript and Nim. Same signing story as A.</p>
<p class="meta">Native code you write: ~100 lines of ObjC, or use wiish · Risk: medium</p></article>
<article class="shape"><h3>C. Pure Nim talking to UIKit</h3><p class="tag">For later, for fun</p>
<p>Call the Objective-C runtime from Nim (<code>nim objc</code>, <code>{.emit.}</code>, <code>objc_msgSend</code>) and build views in Nim. Possible, but you are writing bindings before you write your app.</p>
<p class="meta">Native code you write: all of it · Risk: high</p></article>
</div>"""
  nbText """
**And the no-Mac escape hatch.** If what you really want is *something made in Nim on your home screen*, a web app gets there
with zero Apple process: compile Nim to JavaScript (`nim js`, or nimib's `nbJsFromCode`), host the page, open it in Safari and
choose *Share → Add to Home Screen*. No Mac, no account, no 7-day clock. It is not native (no App Store APIs, limited background work),
but it is the honest fastest answer to the literal question.
"""

# --------------------------------------------------------- the code ---
window "Route A, in Full: the files you add to Xcode's template":
  nbText """
Create *File → New → Project → iOS → App*, Interface **SwiftUI**, Language **Swift**, Team **(Personal Team)**.
Then add these four things. The Nim file is the one proven above.

**1. `nim/core.nim`**: your Nim. Every proc Swift should see gets `{.exportc, cdecl.}`.
"""
  code("nim", readFile("core.nim").strip)
  nbText """
**2. `NimApp/nimcore.h`**: the C signatures Swift will import. Set *Build Settings → Objective-C Bridging Header* to this path.
`cint` becomes Swift `Int32`, `cstring` becomes `UnsafePointer<CChar>`.
"""
  code("c", """#pragma once
void NimMain(void);
int fib(int n);
const char* nimVersion(void);""")
  nbText """
**3. A Run Script build phase** (*Target → Build Phases → + → New Run Script Phase*, dragged above *Compile Sources*).
It uses the variables Xcode already sets, so the same script builds for the Simulator and the phone.
"""
  nbCode:
    # This block runs at page-build time: it renders the exact script for the
    # current choices, so the flags on this page cannot drift from the prose.
    proc xcodeRunScript(nimFile = "nim/core.nim", lib = "nimcore"): string =
      let nimFlags = @[
        "--os:ios", "--cpu:arm64", "--app:staticlib", "--noMain:on",
        "--mm:orc", "--threads:on", "--tlsEmulation:off", "-d:release",
        "--cc:clang", "--passC:\"$FLAGS\"", "--passL:\"$FLAGS\"",
        "--nimcache:\"$DERIVED_FILE_DIR/nimcache\"",
        &"--out:\"$PROJECT_DIR/build/$PLATFORM_NAME/lib{lib}.a\""]
      result = """set -e
export PATH="/opt/homebrew/bin:$HOME/.nimble/bin:$PATH"   # Xcode's PATH has no Homebrew
if [ "$PLATFORM_NAME" = "iphonesimulator" ]; then
  MIN="-mios-simulator-version-min=$IPHONEOS_DEPLOYMENT_TARGET"
else
  MIN="-mios-version-min=$IPHONEOS_DEPLOYMENT_TARGET"
fi
FLAGS="-isysroot $SDKROOT -arch arm64 $MIN"
nim c """ & nimFlags.join(" \\\n      ") & &" \\\n      \"$PROJECT_DIR/{nimFile}\""
    echo xcodeRunScript()
  nbText """
Then in *Build Settings*: **Library Search Paths** `$(PROJECT_DIR)/build/$(PLATFORM_NAME)`, **Other Linker Flags** `-lnimcore`,
and **User Script Sandboxing = No** (Xcode 15+ sandboxes build scripts, and this one writes outside its declared outputs).

**4. Swift that calls Nim.** Replace the template's two files with this:
"""
  code("swift", """import SwiftUI

@main
struct NimApp: App {
    init() { NimMain() }            // initialise Nim once, before any Nim call
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    @State private var n = 20
    var body: some View {
        VStack(spacing: 16) {
            Text("Hello from Nim \(String(cString: nimVersion()))")
            Stepper("n = \(n)", value: $n, in: 0...35)
            Text("fib(n) = \(fib(Int32(n)))").font(.largeTitle.monospacedDigit())
        }
        .padding()
    }
}""")

# ------------------------------------------------------------ wiish ---
window "What wiish Learned the Hard Way":
  nbText """
The library you were thinking of is **[wiish](https://github.com/iffy/wiish)**, *"Why Is It So Hard"*, by Matt Haggard (**iffy**),
who builds the Buckets budgeting app. It aims at one Nim codebase for macOS, Windows, Linux, iOS and Android using a WebView UI.
It describes itself as **alpha**, the last commit is from March 2024, and its own support table marks iOS **Simulator** builds as working while
**real-device** builds are *planned*. So I would read it rather than depend on it. Reading `wiish/plugins/webview.nim` and the iOS template gives five lessons:
"""
  nbRawHtml """<ol class="lessons">
<li><b>Nim is a static library, Xcode is the app.</b> wiish compiles with <code>nim objc --os:ios --app:staticlib -d:ios</code>, then hands the <code>.a</code> to a template Xcode project and runs <code>xcodebuild</code>. Route A above is the same shape with Swift instead of Objective-C.</li>
<li><b>Pass the SDK flags to both compiler and linker.</b> Its <code>linkAndCompile</code> helper adds <code>-arch arm64</code>, <code>-isysroot &lt;iPhoneOS.sdk&gt;</code> and <code>-mios-version-min</code> to <em>both</em> <code>--passC</code> and <code>--passL</code>. Forget one and you get baffling link errors.</li>
<li><b>UIKit owns the main loop.</b> <code>main.m</code> calls <code>UIApplicationMain</code>, and Nim's async loop is pumped by an <code>NSTimer</code> every 10 ms (the source itself says "this polling is terrible"). If your Nim code is synchronous, as in Route A, you skip this problem entirely.</li>
<li><b>Let Xcode do the signing.</b> wiish passes <code>-allowProvisioningUpdates</code> and only overrides the bundle ID and team. Automatic signing is the one part of Apple's process that already works well.</li>
<li><b>Simulator flags have moved on.</b> wiish builds the Simulator slice with <code>--cpu:amd64</code>, which was right for Intel Macs. On Apple Silicon the Simulator is arm64 too, and the platform (iphoneos vs iphonesimulator SDK) is what differs, which is why the script above keys off <code>$PLATFORM_NAME</code>.</li>
</ol>
<p>If you want to try it anyway: <code>nimble install https://github.com/iffy/wiish.git</code>, then <code>wiish doctor</code>, <code>wiish init hello</code>, <code>cd hello</code>, <code>wiish run --os ios-simulator</code>.</p>"""

# --------------------------------------------------------- checklist ---
window "The Checklist":
  nbText """
Every step in order, with rough times. Tick them as you go; the bar shows where your afternoon stands.
The ticks stay in this browser only.
"""
  nbRawHtml checklistHtml

# ------------------------------------------------------------ re-sign ---
window "Living with the 7-Day Clock":
  nbText """
If you install today, these are the dates the app stops launching unless you press Run again. Computed when this page was built:
"""
  nbCode:
    let installed = dateTime(2026, mNov, 7, zone = utc())
    for week in 1..4:
      let expiry = installed + initDuration(days = 7 * week)
      echo &"re-sign #{week}: before {expiry.format(\"ddd d MMM\")}"
  nbText """
Three things make it bearable. After the first cable install, Xcode can install **over Wi-Fi** when both are on the same network
(*Window → Devices and Simulators → Connect via network*). Re-running only re-signs, it does not wipe data. And if the clock really annoys you after a few weeks,
that is exactly the moment the $99 program earns its price; nothing you built has to change except the Team dropdown.
"""

nbRawHtml """<p class="sources">Sources: the wiish repository (README support matrix, <code>wiish/plugins/webview.nim</code>, <code>build_ios.nim</code>, iOS template <code>main.m</code>), Apple's documentation on free provisioning and the Developer Program, and a Nim 1.6 compile run on this page. Apple's limits change between Xcode releases; if Xcode shows a different number, believe Xcode.</p>"""

nbSave
