# skill-issues page sources

An interactive explainer of "Skill Issues": Data-Centric Optimization of Lakehouse Agents (Schneider, Ghilardi,
Piccinini, Tagliabue; VLDB 2026 ADS workshop, [arXiv 2606.01185](https://arxiv.org/abs/2606.01185)), for Nim and
nimib people, made with [nimib](https://github.com/pietroppeter/nimib).

- `index.nim`: the nimib document that writes `../index.html`. Build: `sh deps.sh && nim r index.nim` (Nim 2.2, needs `libpcre3`).
- `lib/data.nim`: the paper's Figure 4 read by eye (about ±0.01, the paper does not publish the numbers), its tables,
  and the loaders for the snapshots below; `lib/blocks.nim`: the custom blocks; `lib/style.nim`: every colour and rule.
- `data/bauplan-seeds/`: the seed SKILL.md files of [BauplanLabs/skill-issues](https://github.com/BauplanLabs/skill-issues) (MIT, commit in `COMMIT`).
- `data/pietro-skills/`: SKILL.md files and graded evals of [pietroppeter/skills](https://github.com/pietroppeter/skills) (commit in `COMMIT`).
- The review mode is tabelline's, from `shared/review/` at the root of the repository (`config.nims`).
- `deps.sh`: fetches nimib and its dependencies at pinned commits into `deps/` (not committed).
