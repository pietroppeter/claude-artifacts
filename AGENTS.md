# claude-artifacts

Static pages made with Claude, served by GitHub Pages from `main` (root). No build step.

## Adding a page
- One folder per page, kebab-case slug: `<slug>/index.html`.
- `index.html` must be a complete standalone document (`<!doctype html>`, `<html lang>`, `<head>` with charset + viewport meta, `<title>`, `<body>`).
  claude.ai artifact sources are fragments (no doctype/head/body) — wrap them; include the small reset the artifact skeleton provides
  (`body{margin:0}`, `[hidden]{display:none!important}`, safe-area padding on `:root`).
- No runtime dependency on claude.ai: no `window.claude.*` capabilities. If a page relied on them, replace with static data or drop the feature.
- Put any scripts/data used to generate the page in `<slug>/src/` so it can be regenerated.
- Add an entry (newest first) to both the root `index.html` list and the `README.md` table.
- Pages here are public: check with Pietro before adding anything with personal or private data.

## Sharing a page with Pietro
- Every reply that delivers or updates a page links to it, rendered. Don't send only the PR.
- Publish the built `<slug>/index.html` as a claude.ai Artifact, and republish to the same artifact whenever the page changes.
  Put the artifact link in the reply, along with the PR and the GitHub Pages URL
  (`https://pietroppeter.github.io/claude-artifacts/<slug>/`, which is live after merge).
- If the artifact can't be published, link a branch preview instead:
  `https://raw.githack.com/pietroppeter/claude-artifacts/<branch>/<slug>/index.html`.

## Page style
- Pick a visual style that fits each explainer's subject: palette, typefaces, motifs. Don't reuse the previous page's theme by default.
- Keep code small: about 12.5–13px for code blocks and outputs, smaller than body text. nimib's theme sets
  `pre > code {font-size:1.2em}`, so override it with a selector at least as specific (`body pre > code`). Set
  `-webkit-text-size-adjust:100%` on `html` so iOS Safari doesn't inflate text in blocks that scroll sideways.
  Check a phone-width screenshot before publishing.

## When a source can't be read
- If a site is blocked by the environment's network policy, tell Pietro what couldn't be read and give him a copy-pastable
  list of the hosts to allow, one per line in a code block. He decides whether to add them.
