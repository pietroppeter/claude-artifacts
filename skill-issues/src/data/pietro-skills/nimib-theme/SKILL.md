---
name: nimib-theme
description: Use when writing or changing the theme (CSS) of a nimib page, so code blocks and outputs stay small, scroll inside their box and are highlighted, also on a phone.
metadata:
  status: personal
---

# Theming a nimib page without breaking code blocks

Code blocks and outputs are the part of a themed nimib page that breaks, mostly on phones. Why each rule is here, with screenshots: the devlog post ["nimib-theme: does each rule earn its place?"](https://pietroppeter.github.io/skills/devlog/2026-11-08-nimib-theme.html).

## 1. Build with a nimib that has #267
nimib PR #267 makes nimib's own style rules lose to any theme rule (they use `:where()`), makes `pre`, `pre > code` and `.nb-output` scroll sideways, and highlights markdown fences tagged `nim` at build time.

On an older nimib (0.4.3 or before), nimib's `pre > code {font-size:1.2em}` comes after the theme and wins over a plain `pre code` rule (13px became 20.4px). There, write code rules as `body pre > code` and `body pre.nb-output`, and put `overflow-x: auto` on both `pre` and `pre > code`.

## 2. Theme rules
- Code blocks and outputs: 12.5 to 13px, smaller than the body text.
- Style `pre.nb-output` too. Outputs have no `<code>` inside, so a `pre code` rule never reaches them (they stayed at 17px).
- If the theme replaces nimib's highlight CSS, it must colour the `hljs-*` classes (keyword, string, comment, number, type, built_in, literal, meta, title).

## 3. Check
Run the phone check on the built page (needs Playwright with Chromium). It ships in `scripts/` next to this file; if it is missing, fetch it from [the skills repo](https://github.com/pietroppeter/skills/tree/main/plugins/nimib/skills/nimib-theme/scripts).

```sh
node <this skill's folder>/scripts/phonecheck.js path/to/page.html
```

It must print only ✓: the page is not wider than 390px, code is 11 to 14px, every block scrolls inside its box, every code block is highlighted. Then look at a 390px-wide screenshot of one long code block.

If the page will be published as a claude.ai artifact, also follow the publish-artifact skill (phone-first plugin).
