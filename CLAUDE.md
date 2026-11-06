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
