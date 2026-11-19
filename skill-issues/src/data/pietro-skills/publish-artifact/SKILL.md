---
name: publish-artifact
description: Use when you build an HTML page for Pietro (a nimib page, an explainer, docs), to publish it as a claude.ai artifact he can read on his phone, and to keep its link stable.
metadata:
  status: personal
---

# Publishing a page as a claude.ai artifact

Pietro reads what we build on his phone, so every HTML page we make for him (nimib pages, explainers, docs sites) is also published as a claude.ai artifact, even when it also lives in a repo or on GitHub Pages.

## 1. Make the page self-contained
Artifacts run under a content security policy:
- Stylesheets from any CDN are blocked, except Google Fonts. Inline them.
- Scripts load only from a few CDNs (cdnjs.cloudflare.com, cdn.jsdelivr.net/npm/, unpkg.com, ...), not from `cdn.jsdelivr.net/gh/`. Inline the rest.
- Remote images do not load: use data: URIs, or publish the images as files of the artifact.
- nimib pages: call `nb.inlineAssets` after `nbInit` (needs nimib with #267). Without it there is no water.css, no highlight colours and no highlight.js.

## 2. Check at phone width
Look at a 390px-wide screenshot. For pages with code blocks, run the phone check from the nimib nimib-theme skill ([phonecheck.js](https://github.com/pietroppeter/skills/tree/main/plugins/nimib/skills/nimib-theme/scripts)); it works on any HTML page and must print only ✓.

## 3. Publish
- Publish the built HTML as an artifact and give Pietro the link, along with any PR.
- When the page changes, republish to the same artifact (same slug), so his link keeps working. Note the slug somewhere durable (the repo's CLAUDE.md or project memory).
- A site of several HTML files (an index and posts) goes up as one artifact with the same relative paths.
- If the artifact holds files you did not build (another session published there), do not overwrite or remove them without asking.
