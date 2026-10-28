# State of NimibLand: the nimib ecosystem and the unfinished move

Research date: 2026-10-28. Covers the 9 repos in this project, the other nimib repos on GitHub, the nim-lang/packages registry, live docs sites, and the Nim forum. Detailed notes with file:line references are in `/mnt/project-files/ecosystem-research/` (`core.md`, `satellites.md`, `web.md`).

---

## 1. Summary

nimib is in better shape than its repos suggest. Hugo shipped the long-awaited block refactor as **v0.4.0 (2026-05-29)**, followed by 0.4.1–0.4.3 (the last on 2026-10-27). nimibook and nimiSlides are ported to 0.4, and nimibex finally has a working extension (Chat Bubbles, July–Aug 2026). Tests pass (66/66 on Nim 2.2.6, both code-capture modes).

What is behind is everything around the code:

- **The move to nimib-land is about a third done.** nblog, nimiBoost and nimibex live in the org; **nimib, nimibook and nimiSlides do not**. nimib #137 ("moving to nimib organization", 2023H1 milestone) is still open.
- **The public docs are stale.** The nimib docs deploy has failed since 0.4.2, so pietroppeter.github.io/nimib stops at 0.4.1, and its prose still describes the mustache-era API. I opened [nimib#263](https://github.com/pietroppeter/nimib/pull/263) to fix the deploy.
- **Old links are already broken.** `pietroppeter.github.io/nblog/...` returns 404 since nblog moved (nblog #19). Moving nimib and nimibook the same way would break `pietroppeter.github.io/nimib` (linked in the footer of every page nimib has ever generated) and `/nimibook`.
- **The SSG was started and stalled, and its blocker is now gone.** nblog draft PR #16 (Feb–Mar 2023) built nim → json → html for blog posts but needed blocks that survive a JSON round trip. nimib 0.4 now has exactly that.
- **The issue trackers are frozen in 2023–2024.** nimib has 60 open issues, none touched since mid-2024; several are done by 0.4. The `2023H1/2023H2` labels and milestone are leftovers.
- **No AI tooling exists yet** (no AGENTS.md / CLAUDE.md, no nimib skill anywhere). Models will default to the pre-0.4 API, which the stale docs reinforce.

**Top five actions**, in order:

1. Merge #263 so the 0.4.x docs go live, then fix the README/index.nim drift (#141) and rewrite the pre-0.4 API text.
2. Pilot the redirect approach on nblog (fix nblog #19), then use it to move nimibook, then nimib.
3. Triage: close the ~12 issues that are done, retire dated labels/milestones, delete stale branches.
4. Restart the SSG as a small library on top of the 0.4 JSON backend, with nblog as first user.
5. Add AGENTS.md files and a tested nimib skill set (the "Build and test Nimib skills" thread is on this).

---

## 2. Ecosystem at a glance

| Project | Lives at | Version / nimib | Last real activity | CI | Site | Open issues / PRs |
|---|---|---|---|---|---|---|
| **nimib** | pietroppeter | 0.4.3 | 2026-10-27 | tests ✅, netlify previews ✅, **docs ❌ since 0.4.2** | pietroppeter.github.io/nimib (stale, last deploy 2026-06-04) | 60 / 3 (+#263) |
| **nimibook** | pietroppeter | 0.4.0, nimib ≥ 0.4.1 | 2026-06-18 | tests, docs, netlify previews ✅ | pietroppeter.github.io/nimibook | 23 / 0 |
| **nimiSlides** | HugoGranstrom | ported to 0.4 | 2026-07 | (not in scope) | hugogranstrom.com/nimiSlides | – |
| **nimibex** | nimib-land | 0.1.0, nimib ≥ 0.4.1 | 2026-08-08 | docs build + gh-pages PR previews ✅ (no unit tests) | nimib.land/nimibex | 14 / 0 |
| **nblog** | nimib-land | none (posts built with nimib 0.3) | 2024-05-01 | none | nimib.land/nblog (old URLs 404) | 18 / 1 (draft SSG PR #16) |
| **nimiBoost** (VS Code) | nimib-land | 0.4.3 | 2022-09-18 | none | Marketplace `hugogranstrom.nimiboost` (156 installs) | 0 / 0 |
| **nimib-land.github.io** | nimib-land | – | 2024-03-23 | none | **nimib.land** (Jekyll placeholder) | 0 / 0 |
| **nimib.py** | nimib-land | uses nimib 0.3 internals, won't build on 0.4 | 2024-01-18 | none | nimib.land/nimib.py | 1 / 0 |
| **nimibland-for-explorables** | nimib-land | nimiSlides deck, nimib 0.3 era | 2024-01-17 | Pages deploy | nimib.land/nimibland-for-explorables | 1 / 0 |
| **adventofnim** | pietroppeter | nimib ≥ 0.2.4 | 2022-12-31 | none | pietroppeter.github.io/adventofnim | 2 / 0 |

Other repos in the org: nimconf24 (NimConf 2024 talk), assets (logos), redirect-pages (stub, "avoid 404 after moving"), groviglio (Tangle experiment), `.github` (profile: "work in progress! we are moving nimib repos here!"). Public members: pietroppeter, HugoGranstrom.

Other nimib repos still under pietroppeter: p5nim (62★), paramidib, feedo (static RSS reader), nascondino ("A static site generator for nimib", 2022–23, private), animibis (hugo-theme port), nimconf22-nimib, nimconf2021, nobe and uv-add-nimlang (the Python/uv direction), blog.

**Dependents.** GitHub code search finds 66 public repos that depend on nimib, nimibook or nimiSlides (31 third-party, 35 of our own; full list below). nimibook has the most third-party adoption (enu, owlkettle, Norm, SciNim getting-started, qex and 8 more); nimiSlides is used for NimConf 2024 and 2026 talks by others; direct nimib users include libnimib (C API), nimitheme, wordle-it, blogs and experiments. Stars: nimib 204, nimibook 88, nimiSlides 88.

### Dependents (31 third-party, 35 our own)

Found on 2026-10-28 by GitHub code search for `import nimib`, `import nimislides`, `nbook.nim`, `[nimibook]` in `nimib.toml` and the three package names in `.nimble` files, plus nimibook's README. Vendored copies and the `penguinite/everything` meta-package are left out. Sorted by stars; the 'uses' column says nimibook or nimiSlides when the repo depends on them (both pull in nimib), otherwise plain nimib.

**Third-party repos (31).** Libraries that document with nimibook, plus talks, blogs and experiments.

| Repo | Uses | ★ | Site | Last push | What it is |
|---|---|---|---|---|---|
| [getenu/enu](https://github.com/getenu/enu) | nimibook | 486 | [getenu.com/docs/intro.html](https://getenu.com/docs/intro.html) | 2026-10-08 | A Logo-like 3D environment, implemented in Nim |
| [can-lehmann/owlkettle](https://github.com/can-lehmann/owlkettle) | nimibook | 459 | [can-lehmann.github.io/owlkettle/README.html](https://can-lehmann.github.io/owlkettle/README.html) | 2026-09-14 | A declarative user interface framework based on GTK 4 |
| [moigagoo/norm](https://github.com/moigagoo/norm) | nimibook | 417 | [norm.nim.town](https://norm.nim.town) | 2026-08-05 | A Nim ORM for SQLite and Postgres |
| [SciNim/getting-started](https://github.com/SciNim/getting-started) | nimibook | 64 | [scinim.github.io/getting-started](https://scinim.github.io/getting-started/) | 2024-11-22 | Getting started with Nim for Scientific Computing |
| [jcosborn/qex](https://github.com/jcosborn/qex) | nimibook | 60 | [jcosborn.github.io/qex](http://jcosborn.github.io/qex/) | 2026-10-22 | Quantum EXpressions lattice field theory framework |
| [PhilippMDoerner/Snorlogue](https://github.com/PhilippMDoerner/Snorlogue) | nimibook | 27 | [philippmdoerner.github.io/Snorlogue/bookCompiled](https://philippmdoerner.github.io/Snorlogue/bookCompiled/) | 2023-10-27 | An plugin for the prologue web-framework of the nim-language. Provides an admin  |
| [moigagoo/karkas](https://github.com/moigagoo/karkas) | nimibook | 19 | [karkas.nim.town](https://karkas.nim.town/) | 2026-01-09 | Layout helpers and syntactic sugar for Karax |
| [PhilippMDoerner/mapster](https://github.com/PhilippMDoerner/mapster) | nimibook | 17 | [philippmdoerner.github.io/mapster/index.html](https://philippmdoerner.github.io/mapster/index.html) | 2025-12-29 | A simple way to generate mapping functions at compile-time without having to wri |
| [neroist/nova](https://github.com/neroist/nova) | nimibook | 14 | [neroist.github.io/nova](https://neroist.github.io/nova/) | 2026-05-03 | Nova is a CLI for controlling Govee light strips, inspired by Bandev's Lux. |
| [neroist/nimitheme](https://github.com/neroist/nimitheme) | nimib | 11 | [neroist.github.io/nimitheme](https://neroist.github.io/nimitheme/) | 2024-06-28 | Make nimib look beautiful with nimitheme |
| [chutter/FrogCap-Sequence-Capture](https://github.com/chutter/FrogCap-Sequence-Capture) | nimibook | 10 | – | 2024-08-02 | Probe set files and pipeline for the analysis of data acquired from the Hutter e |
| [BontaVlad/NimDrake](https://github.com/BontaVlad/NimDrake) | nimibook | 8 | – | 2026-08-25 | Nim wrapper for the DuckDB high-performance analytical database system |
| [PhilippMDoerner/ThreadButler](https://github.com/PhilippMDoerner/ThreadButler) | nimibook | 7 | [philippmdoerner.github.io/ThreadButler/bookCompiled/index.html](https://philippmdoerner.github.io/ThreadButler/bookCompiled/index.html) | 2024-07-08 | Use threads as if they were servers/microservices to enable multi-threading with |
| [moigagoo/nimconf2024](https://github.com/moigagoo/nimconf2024) | nimiSlides | 6 | [moigagoo.github.io/nimconf2024/nimconf2024.html](https://moigagoo.github.io/nimconf2024/nimconf2024.html) | 2024-10-17 | Slides for my NimConf 2024 talk. |
| [haxscramper/hack](https://github.com/haxscramper/hack) | nimib | 5 | – | 2026-10-16 |  |
| [enthus1ast/nimTermbin](https://github.com/enthus1ast/nimTermbin) | nimib | 4 | – | 2023-07-11 | A termbin clone in Nim |
| [ajusa/binarylang-fun](https://github.com/ajusa/binarylang-fun) | nimib | 4 | [ajusa.github.io/binarylang-fun/intro.html](https://ajusa.github.io/binarylang-fun/intro.html) | 2021-05-05 | Fun with using binarylang to parse stuff in Nim |
| [beef331/libnimib](https://github.com/beef331/libnimib) | nimib | 3 | – | 2024-06-15 | This builds ontop of nimib allowing any language to use it. |
| [dlesnoff/nimProgramming-blog](https://github.com/dlesnoff/nimProgramming-blog) | nimib | 3 | [dlesnoff.github.io/nimProgramming-blog](https://dlesnoff.github.io/nimProgramming-blog/) | 2026-10-28 | Documentation and code about metaprogramming in Nim |
| [xTrayambak/nimconf2026](https://github.com/xTrayambak/nimconf2026) | nimiSlides | 3 | – | 2026-06-20 | My presentation slides for NimConf 2026 |
| [Kiloneie/kiloneie.github.io](https://github.com/Kiloneie/kiloneie.github.io) | nimibook, nimiSlides | 1 | [kiloneie.github.io](https://kiloneie.github.io/) | 2025-09-11 | Github page for all my nimib styled offline tutorials of my Nim Tutorial Videos. |
| [lordcris/wordle-bg-turbo](https://github.com/lordcris/wordle-bg-turbo) | nimib | 1 | – | 2022-02-02 |  |
| [ConnectedSystems/ihacres_nim](https://github.com/ConnectedSystems/ihacres_nim) | nimib | 1 | – | 2021-10-16 | IHACRES ported to nim-lang |
| [x3C49/x3C49.github.io](https://github.com/x3C49/x3C49.github.io) | nimiSlides | 1 | [x3c4.club](https://x3c4.club/) | 2026-04-18 |  |
| [RowDaBoat/henka-nimconf-26](https://github.com/RowDaBoat/henka-nimconf-26) | nimiSlides | 1 | – | 2026-06-20 | Henka slides and demos for nimconf-26 |
| [ScriptsPython-ISM/wordello](https://github.com/ScriptsPython-ISM/wordello) | nimib | 0 | – | 2025-05-30 | wordle clone for italian class |
| [epistrephein/wordle-it-endless](https://github.com/epistrephein/wordle-it-endless) | nimib | 0 | [epistrephein.github.io/wordle-it-endless](https://epistrephein.github.io/wordle-it-endless/) | 2026-06-28 | Italian version of Wordle, endless. |
| [njh888/njh8888](https://github.com/njh888/njh8888) | nimib | 0 | [njh888.github.io/njh8888/rpn_manual.html](https://njh888.github.io/njh8888/rpn_manual.html) | 2025-10-23 |  |
| [beef331/beef331.github.io](https://github.com/beef331/beef331.github.io) | nimib | 0 | – | 2026-06-20 |  |
| [lbartoletti/lbartoletti.github.io](https://github.com/lbartoletti/lbartoletti.github.io) | nimib | 0 | – | 2025-01-20 |  |
| [Abathargh/avrio_nimconf24](https://github.com/Abathargh/avrio_nimconf24) | nimiSlides | 0 | – | 2024-10-11 | Slides for the avr_io presentation in nimconf24 |

**Our own repos (35).** pietroppeter, HugoGranstrom and nimib-land, excluding nimib, nimibook and nimiSlides themselves.

| Repo | Uses | ★ | Site | Last push | What it is |
|---|---|---|---|---|---|
| [pietroppeter/wordle-it](https://github.com/pietroppeter/wordle-it) | nimib | 146 | [pietroppeter.github.io/wordle-it](https://pietroppeter.github.io/wordle-it/) | 2023-08-20 | Italian version of Wordle |
| [HugoGranstrom/nimiSlides](https://github.com/HugoGranstrom/nimiSlides) | nimib | 88 | [hugogranstrom.com/nimiSlides](https://hugogranstrom.com/nimiSlides) | 2026-07-21 | A Reveal.js theme for nimib for making slideshow presentations in Nim |
| [pietroppeter/p5nim](https://github.com/pietroppeter/p5nim) | nimib | 62 | [pietroppeter.github.io/p5nim](https://pietroppeter.github.io/p5nim/) | 2023-06-09 | 🌸👑 p5nim: processing for nim through p5js |
| [pietroppeter/adventofnim](https://github.com/pietroppeter/adventofnim) | nimib | 28 | [pietroppeter.github.io/adventofnim](https://pietroppeter.github.io/adventofnim/) | 2024-12-10 | 🎄👑 adventofnim - nim solutions for advent of code |
| [pietroppeter/nim-for-pythonistas](https://github.com/pietroppeter/nim-for-pythonistas) | nimiSlides | 24 | [pietroppeter.github.io/nim-for-pythonistas](https://pietroppeter.github.io/nim-for-pythonistas/) | 2025-02-05 | me introducing nim to pythonistas |
| [pietroppeter/paramidib](https://github.com/pietroppeter/paramidib) | nimib | 14 | [pietroppeter.github.io/paramidib](https://pietroppeter.github.io/paramidib/) | 2023-03-15 | 🎶🐳 paramidi with nimib |
| [nimib-land/nblog](https://github.com/nimib-land/nblog) | nimib | 12 | [nimib.land/nblog](https://nimib.land/nblog/) | 2024-05-01 | ✍️🐳👑 blog about nimib and nim ecosystem |
| [pietroppeter/naffprop](https://github.com/pietroppeter/naffprop) | nimib | 8 | – | 2026-10-08 | Affinity Propagation in Nim for Python |
| [pietroppeter/nimconf22-nimib](https://github.com/pietroppeter/nimconf22-nimib) | nimiSlides | 8 | [pietroppeter.github.io/nimconf22-nimib](https://pietroppeter.github.io/nimconf22-nimib/) | 2022-10-24 | slides for nimib presentation at nimconf 2022 |
| [nimib-land/nimibex](https://github.com/nimib-land/nimibex) | nimibook | 6 | [nimib.land/nimibex](https://nimib.land/nimibex/) | 2026-08-08 | 🐐 nimibex - extensions, experiments and extras for nimib ecosystem |
| [pietroppeter/domain-driven-data-science](https://github.com/pietroppeter/domain-driven-data-science) | nimiSlides | 4 | [pietroppeter.github.io/domain-driven-data-science](https://pietroppeter.github.io/domain-driven-data-science/) | 2025-06-12 | talk about the importance of domain expertise in data science |
| [pietroppeter/pymi-timeseries-forecasting-nixtla](https://github.com/pietroppeter/pymi-timeseries-forecasting-nixtla) | nimiSlides | 3 | – | 2023-05-22 | repo for presentation at Python Milano (May 2023) on timeseries forecasting with |
| [pietroppeter/nim-ib-lightning-tcp](https://github.com/pietroppeter/nim-ib-lightning-tcp) | nimiSlides | 3 | [pietroppeter.github.io/nim-ib-lightning-tcp](https://pietroppeter.github.io/nim-ib-lightning-tcp/) | 2024-04-18 | Lightning Talk (10') on Nim and Nimib with a Tech/Culture/People point of view ( |
| [pietroppeter/blog](https://github.com/pietroppeter/blog) | nimib | 2 | [blog.pietroppeter.xyz](http://blog.pietroppeter.xyz/) | 2026-10-14 | my personal blog |
| [pietroppeter/feedo](https://github.com/pietroppeter/feedo) | nimib | 2 | [pietroppeter.github.io/feedo](https://pietroppeter.github.io/feedo/) | 2024-11-03 | 🐶 minimalistic static rss reader built with nim(ib) |
| [pietroppeter/adventofcode2023](https://github.com/pietroppeter/adventofcode2023) | nimib | 2 | [pietroppeter.github.io/adventofcode2023](https://pietroppeter.github.io/adventofcode2023/) | 2024-01-16 | My solutions for advent of code 2023 |
| [nimib-land/nimconf24](https://github.com/nimib-land/nimconf24) | nimibook, nimiSlides | 1 | [nimib.land/nimconf24](http://nimib.land/nimconf24/) | 2024-10-26 | NimibLand presentation for NimConf 2024 |
| [HugoGranstrom/AdventOfNim](https://github.com/HugoGranstrom/AdventOfNim) | nimib | 1 | – | 2025-12-12 | My Advent of Code solutions written in Nim |
| [pietroppeter/programma101](https://github.com/pietroppeter/programma101) | nimib | 1 | [pietroppeter.github.io/programma101/p5gui.html](https://pietroppeter.github.io/programma101/p5gui.html) | 2023-06-20 | programma 101 emulator in nim |
| [pietroppeter/time-circles](https://github.com/pietroppeter/time-circles) | nimib | 1 | [pietroppeter.github.io/time-circles](https://pietroppeter.github.io/time-circles/) | 2024-11-09 | circles changing through time |
| [pietroppeter/diventa-avventore-del-codice](https://github.com/pietroppeter/diventa-avventore-del-codice) | nimiSlides | 1 | [pietroppeter.github.io/diventa-avventore-del-codice](https://pietroppeter.github.io/diventa-avventore-del-codice/) | 2024-06-17 | Elogio del calendario dell'avvento del codice (Advent of Code) |
| [pietroppeter/ai-a-blast-from-the-past](https://github.com/pietroppeter/ai-a-blast-from-the-past) | nimiSlides | 1 | [pietroppeter.github.io/ai-a-blast-from-the-past](https://pietroppeter.github.io/ai-a-blast-from-the-past/) | 2025-04-25 | ⚡🤖 Lightning talk "AI, a blast from the past", a condensed and opinionated histo |
| [nimib-land/groviglio](https://github.com/nimib-land/groviglio) | nimib | 1 | – | 2024-01-22 | An experiment in wrapping Bret Victor's Tangle framework for NimibLand |
| [pietroppeter/soscin22](https://github.com/pietroppeter/soscin22) | nimiSlides | 1 | [pietroppeter.github.io/soscin22](https://pietroppeter.github.io/soscin22/) | 2022-01-11 | State Of Scientific Computing In Nim 2022 - repo for my Fosdem presentation |
| [pietroppeter/pyscript-python-dovunque-perchiunque](https://github.com/pietroppeter/pyscript-python-dovunque-perchiunque) | nimiSlides | 1 | [pietroppeter.github.io/pyscript-python-dovunque-perchiunque](https://pietroppeter.github.io/pyscript-python-dovunque-perchiunque/) | 2024-08-30 | presentazione su pyscript |
| [pietroppeter/nanuq](https://github.com/pietroppeter/nanuq) | nimib | 0 | – | 2026-10-28 | nim bindings for pola-rs |
| [pietroppeter/japps](https://github.com/pietroppeter/japps) | nimib | 0 | – | 2023-12-15 | tracking effort for job applications |
| [pietroppeter/penlp](https://github.com/pietroppeter/penlp) | nimiSlides | 0 | [pietroppeter.github.io/penlp](https://pietroppeter.github.io/penlp/) | 2024-04-04 | Philosophy, Emotions, NLP: an explorable |
| [pietroppeter/nimyverse](https://github.com/pietroppeter/nimyverse) | nimib | 0 | – | 2020-05-22 |  |
| [pietroppeter/rc23winter1](https://github.com/pietroppeter/rc23winter1) | nimib | 0 | – | 2024-02-04 | main repo for public activities during recurse center (2023 Winter 1 batch) |
| [pietroppeter/tgml-journey](https://github.com/pietroppeter/tgml-journey) | nimiSlides | 0 | – | 2024-05-21 | A short presentation on how a Data Scientist got in love with putting ML in prod |
| [pietroppeter/nimconf2021](https://github.com/pietroppeter/nimconf2021) | nimib | 0 | – | 2021-06-28 | slides for my presentation of nimib at NimConf2021 |
| [pietroppeter/git-matrioska](https://github.com/pietroppeter/git-matrioska) | nimiSlides | 0 | [pietroppeter.github.io/git-matrioska](https://pietroppeter.github.io/git-matrioska/) | 2023-09-18 | a normcore git worklfow for maintaining production (ML) repos |
| [pietroppeter/hola-talk](https://github.com/pietroppeter/hola-talk) | nimiSlides | 0 | – | 2025-11-08 | a talk about holacracy |
| [pietroppeter/talk-sailing-seas-scientific-nim](https://github.com/pietroppeter/talk-sailing-seas-scientific-nim) | nimiSlides | 0 | [pietroppeter.github.io/talk-sailing-seas-scientific-nim](https://pietroppeter.github.io/talk-sailing-seas-scientific-nim/) | 2026-10-28 | Slides for Talk "Sailing Seas of Scientific Nim" |

---

## 3. The move to nimib-land

### What's done
- Org created 2023-01-29 as `nimib-org`, renamed `nimib-land` by April 2023 (github.com/nimib-org now 404s, still linked from the Feb 2023 Nim blog post).
- Moved: nblog and nimiBoost (Nov 2023, discussion #221), nimibex (created there). New repos created there since.
- Custom domain **nimib.land** on the org Pages repo, so every org project site is served at `nimib.land/<repo>/`. After the move, nimib docs become `nimib.land/nimib/` and nimibook `nimib.land/nimibook/`.

### The lesson from nblog
GitHub redirects git and web URLs for a transferred repo, but **not GitHub Pages URLs**. The proposed fix in #221 was to recreate `pietroppeter/nblog` holding redirect pages. That has a catch: **creating any repo at the old name cancels GitHub's repo redirect** (git clones, issue links, jsDelivr `gh/` URLs, nimble lock files that pin the old URL).

**Recommended approach (to verify on nblog first):** put the redirect pages in a *user site* repo, `pietroppeter/pietroppeter.github.io`, under folders `nblog/`, `nimib/`, `nimibook/`. A user site serves any path that no project site claims, so after a transfer `pietroppeter.github.io/nimib/...` would fall through to these redirect pages while `github.com/pietroppeter/nimib` keeps redirecting to the org. I found no such repo today. One condition: the user site must not set a custom domain, or project URLs would start redirecting to it. This is cheap and reversible, so nblog #19 is the ideal pilot.

### Checklist per repo (nimibook first, then nimib)

**Before the transfer**
- [ ] Redirect pages ready in the user site (one HTML per published page, meta-refresh plus canonical link to `nimib.land/<repo>/...`; a small script can generate them from the gh-pages file list).
- [ ] Update hardcoded URLs (full list with lines in `core.md` §2 and `satellites.md` §2):
  - nimib `src/nimib/themes.nim:32` footer link → `nimib.land/nimib/`.
  - nimib `themes.nim:125,126,128` jsDelivr `gh/pietroppeter/nimib/assets/...` → `gh/nimib-land/nimib@<version>/assets/...` (pin a version; two are unpinned today). Already-published pages keep the old URLs, so they rely on the GitHub redirect; this is another reason not to recreate a repo at the old name.
  - nimib `gits.nim:55,61` self-test asserts the remote URL.
  - nimib `docsrc/index.nim:13-14` repo and docs constants (README links derive from them), `hello.nim:9`, `mostaccio.nim:15`, CONTRIBUTING links.
  - nimibook `nimib.toml:9-10` (repo URL and Plausible domain), README links, Netlify preview URL.
  - nimibex `nimble.lock` entries for nimib and nimibook.
- [ ] Decide on PR previews: nimib and nimibook use Netlify (needs `NETLIFY_AUTH_TOKEN`/`NETLIFY_SITE_ID` re-created after transfer); nimibex has a secret-free gh-pages preview (rossjrw/pr-preview-action) that could replace them.

**The transfer** (irreversible-ish; Pietro's call)
- [ ] Transfer the repo to nimib-land (issues, stars, releases, discussions come along).
- [ ] Enable Pages on the new repo; check `nimib.land/<repo>/` works.
- [ ] Move or recreate repo secrets.

**After the transfer**
- [ ] PR to nim-lang/packages updating `url`/`web` for nimib and nimibook. While at it, fix `nimiSlides` which still points at the old `HugoGranstrom/nimib-reveal` name.
- [ ] Update Plausible site domains.
- [ ] Update links in dependents you control (nimiSlides docs, nimibex, nblog, adventofnim) and the README "showcase" lists.
- [ ] Update the org profile README and nimib-land.github.io landing page; close nimib #137.
- [ ] Optional: enable org-level Discussions (one of the original goals) and post an announcement on the forum.

**Not moving (suggested):** adventofnim (personal), nimconf talk repos, p5nim and paramidib unless you want them as nimibex members. **Hugo's call:** nimiSlides and the nimiBoost Marketplace publisher (`hugogranstrom`), which can only publish from his account unless a new org publisher is created (which would be a new extension ID).

---

## 4. nimibex

**Intent** (discussion #147, Oct 2022; issue #1): one shared repo for extensions too small or too dependency-heavy for core: Mermaid, Plotly, Vega-Lite, the Juxtapose before/after slider, Karax widgets, jsplot, a quiz block, paramidib, and moving `nbPython` out of nimib. Design went back and forth (monorepo with sub-packages and an installer, Atlas, copy-paste microlibraries) until **Hugo settled it in Jan 2026: one package, one module per block** (`import nimibex/chat_bubbles`).

**What exists:** one extension, `chat_bubbles` (a `newNbBlock … of NbContainer` block with a character type), a nimibook docs site at nimib.land/nimibex, API docs, and the best CI scaffolding in the ecosystem (docs on gh-pages, PR previews without secrets). No unit tests, no release tag, not in the nimble registry.

**Backlog:** issues #2–#10 are porting jobs; most prototypes already exist as nblog drafts written against nimib 0.3. #11 (chat elements) is done but open; #1 is decided but open. Third-party extensions (nimitheme, nimipdf) use the GitHub topic `nimibex-extension`.

**Suggested next steps:** close #1 and #11; add one real test per block (render a tiny doc, assert on HTML); tag v0.1.0 and register in nim-lang/packages; port mermaid (also wanted by nimibook #88) and plotly next as they have the most demand; decide whether nbPython actually leaves core (a breaking change for nimib).

---

## 5. nblog and the SSG

**The plan.** Oct 2022: "I do plan to work on a site generator with nimib with main use case blogs (and this blog will move there)" (nblog #12). The Feb 2023 "This Month with Nim" post and discussion #162 put an SSG in 2023H1: render each doc to JSON, then JSON to HTML, with nimibook refactored onto it later (nimibook #65). A private repo `pietroppeter/nascondino` ("A static site generator for nimib", Nov 2022–Feb 2023) is an earlier attempt I could not read.

**What was built.** nblog draft PR #16 "implementing Basic theme" (branch `basic-theme`, 18 commits):
- `posts/` → `docs/` layout, `templates/`
- `src/nblog.nim`: `useNblog` theme, `title`, `subtitle`, `pubDate`, hand-written jsony hooks to dump/load a doc, `nbSaveJson`, `nbJsonToHtml`
- an `nblog init / build [--json]` CLI (climate)
- two posts converted (city_in_a_bottle, arraymancer_tutorial)

**What's missing** (nblog #5 checklist and PR #16 todo): index page built from the collected JSON, about page, redirects from `drafts/`, deploy workflow, tags, RSS (nimib #49), front matter (nimib #30), SEO title/description.

**Why it stalled.** The JSON round trip needed real block objects; nbJs blocks in particular didn't survive it. That needed the NbBlock refactor, which took until nimib 0.4.0 (May 2026). Its changelog names "a static site generator built with Nimib" as a motivation for the new JSON backend. Hugo's 2024 nblog post on jsony OOP serialization was groundwork for this.

**Competition and demand.** dlesnoff asked for a blog-oriented nimib tool (forum t/13751, Feb 2026). moigagoo, the most active nimibook user, wants site-wide search and Markdown-first authoring, and in mid-2026 added a Markdown-book mode to `nim doc` instead (t/14008). A nimib SSG's edge is executed, compile-checked content and JS interactivity; plain Markdown sites now have a stdlib option.

**Suggested restart** (small, shippable in steps):
1. A library module (in nblog `src/` or nimibex, or revive the nascondino name) on top of nimib 0.4: `buildSite(srcDir, outDir)` that runs each post with `nim r … --nbJson`-style output, loads JSON, renders with a site theme.
2. Index page + post metadata (title, date, tags) stored in the doc JSON.
3. Port the 25 nblog drafts to 0.4 (or freeze the old HTML and only build new posts), add redirects from `drafts/`, a deploy workflow, RSS.
4. Then consider nimibook #65 (nimibook on the same core) and site-wide search (which benefits both).

Dependency in nimib: issue #245 (compile a doc to a string instead of a file) is the API an SSG wants; worth adding to core.

---

## 6. What managing nimib involves (recurring work)

| Area | Today | What would help |
|---|---|---|
| **Releases** | Manual: squash-merge, bump `nimib.nimble` and `nimibVersion`, changelog, tag, auto release notes, optional discussion post. No announcement for 0.4.3. | A release checklist file or skill; a CI check that the tag matches the nimble version. |
| **CI** | 3 different preview setups (Netlify ×2, gh-pages); old action versions (checkout@v2, peaceiris@v3); libpcre3 dependency forces ubuntu-24.04. | Unify on the nimibex preview workflow; bump actions; `workflow_dispatch` (#228). The libpcre3 dependency comes from nim-markdown's `std/re`; worth tracking upstream before 24.04 ages out. |
| **Docs** | README generated from `docsrc/index.nim` but hand-edited (#141); API/Rendering/CONTRIBUTING text describes pre-0.4. | Fix #141; rewrite the "how it works" and "add a block" docs for 0.4 (also closes #223). |
| **Registry** | nimib, nimibook, nimiSlides point at personal repos; nimibex not registered. | Update after the move. |
| **Issue hygiene** | 60 + 23 + 18 + 14 open, mostly 2021–2023. | One triage pass (list in §7), then a label for "good first issue" that is actually current. |
| **Community** | Monthly speaking hours Oct 2022–Apr 2024, none since; forum announcements for 0.3, 0.4.0, 0.4.2. | Decide whether to resume; announce 0.4.3 + docs. |
| **Ecosystem compatibility** | nblog, adventofnim, nimib.py, explorables deck are on 0.3 and won't rebuild on 0.4. | Port nblog with the SSG; leave the rest frozen or archive. |
| **AI** | Claude already used for #260–#263; no AGENTS.md; no skills. | AGENTS.md per repo (build/test recipe, conventions); skills tested against real builds (see §8). |

---

## 7. Housekeeping list (low risk, each a few minutes)

**nimib:** close #168, #102, #111 (done by #235), #62 (fixed by vendored pathutils in 0.4.2), probably #28 (nbRawHtml); re-check #117, #134, #166, #33 against 0.4; close or rebase PR #177 (superseded by NbContainer); PRs #220 and #210 need porting to 0.4; close milestone 2023H1 and retire `2023H1`/`2023H2` labels; delete ~23 stale branches.
**nimibook:** close #93 (CI green); file the site-wide search request from t/13944; relabel #65 once the SSG plan is set.
**nimibex:** close #1, #11.
**nblog:** close #9 (slider post exists), #20 (answered by serialize_oop post); fix the Plausible domain in `head_other.mustache`.
**nimiBoost:** `package.json` repository still points at `HugoGranstrom/nimiBoost`.
**nimib.py, nimibland-for-explorables, groviglio, redirect-pages:** decide archive vs. keep. nimib.py's "uvx nimib" vision seems to have moved to `nobe` / `uv-add-nimlang`.

I'm happy to do any of these; closing issues is visible to watchers, so I'd want your go-ahead.

---

## 8. AI and nimib skills (handed to the skills thread)

- No nimib skill exists anywhere; models know nimib 0.3 (mustache partials, `newNbSlimBlock`, `nb.blk.context`) and the live docs still teach it.
- Prior art worth copying: planetis's verified Nim skills (forum t/14221, github.com/planetis-m/skills). Every claim in a skill is backed by a program the compiler runs, agents are benchmarked on unseen tasks with and without the skill, and everything is re-run on each compiler release. The nim-code plugin (t/14033) got pushback for shipping without evidence. The Nim community will judge nimib skills by tests.
- A working sandbox recipe exists: `pip install nimlang` (Nim 2.2.6 from PyPI), clone fusion/nim-markdown/parsetoml/jsony and pass `--path`, `apt install libpcre3`. The full nimib suite runs in ~3 minutes with no nimble.
- Candidate skills: writing a nimib doc; custom blocks and containers in 0.4; migrating a 0.3 custom block; nimibook setup and CI deploy; nimiSlides decks; maintainer workflows (release, registry, org move).

---

## 9. Prioritized action plan

**Now (this week, low risk)**
1. Merge [nimib#263](https://github.com/pietroppeter/nimib/pull/263); docs for 0.4.3 go live.
2. Fix #141 (README drift) and rewrite the 0.4 "how it works / add a block" docs.
3. Triage pass from §7.
4. Add AGENTS.md to nimib, nimibook, nimibex.

**Next (the move)**
5. Create the `pietroppeter.github.io` user site with redirects for nblog; confirm `pietroppeter.github.io/nblog/drafts/plant_app.html` redirects. Closes nblog #19.
6. Move nimibook (fewer inbound links), following §3. Then nimib. Then ask Hugo about nimiSlides.
7. Registry PR; landing page at nimib.land listing the ecosystem; close #137.

**Then (building)**
8. SSG restart on 0.4 JSON with nblog as first site (§5).
9. nimibex: tests, v0.1.0 tag and registration, mermaid and plotly ports.
10. nimibook site-wide search.
11. Skills with evals, re-run on each nimib release.

## 10. Decisions for you

- **Redirect strategy:** user-site redirects (recommended) vs. recreating repos at the old names (breaks GitHub's repo redirects).
- **Order and timing** of nimibook and nimib transfers, and whether to ask Hugo to move nimiSlides.
- **SSG home:** nblog `src/`, a nimibex module, or a new repo (nascondino?).
- **nbPython:** move to nimibex (breaking) or keep in core.
- **Archive** nimib.py, nimibland-for-explorables, groviglio?
- **Speaking hours:** resume or retire.
