---
name: easy-review
description: Use whenever you hand work back to Pietro (a PR, a page, a release, a change he must check), so he can review and act on it from his phone in a tap or two.
metadata:
  status: draft
---

# Make every result easy to review from the phone

Assume Pietro is on his phone, always. He can tap links, look at pictures and press buttons; he cannot run commands, open local paths or read long diffs comfortably. Every reply that delivers work gives him what he needs to review it and act on it without a laptop.

## Links, always clickable
- A PR: link it. A pushed change to an open PR: link the PR again, not just "pushed".
- Anything rendered (a page, a docs site, a nimib explainer): publish it as an artifact (publish-artifact skill) and link that. Until then, a rendered preview link, e.g. `https://raw.githack.com/<owner>/<repo>/<branch>/<path>.html`.
- A file: link it on GitHub (`https://github.com/<owner>/<repo>/blob/<branch>/<path>`), never a bare local path.
- Settings he must change: the direct settings URL (e.g. `https://github.com/<owner>/<repo>/settings/pages`), with what to pick.

## Releases: one tap to create, notes to paste
When a release is due, do not tell him to create it. Give him two things:

1. A link to GitHub's new-release form with only the tag, target and title filled in:

   ```text
   https://github.com/<owner>/<repo>/releases/new?tag=v0.4.4&target=main&title=v0.4.4
   ```

2. The release notes in their own ` ```markdown ` block, so he can copy them into the form.

Do not put the notes in the link: tested 2026-11-08 from the phone, a link with a one-line `body` works, but one with full notes (about 1100 characters) breaks. After the release exists, link the release page.

## Show, don't describe
- A visual change: attach a phone-width (390px) screenshot, before and after when it fixes something.
- A rule or decision: one line of evidence (a check's output, a number), not a paragraph.

## Keep it skimmable
- Lead with the result and the one thing he needs to do, if any.
- One link per thing, named by what it is ("PR #3", "the docs page"), not "here".
