# nimanim-affinity page sources

- `scene.nim`: the [nimanim](https://github.com/himanshm/nimanim) scene that renders
  `../affinity_propagation.mp4` (`../poster.jpg` is the frame at 44 s).
- `index.nim`: the [nimib](https://github.com/pietroppeter/nimib) document that writes
  `../index.html`; its code blocks run at build time.
- `deps.sh`: fetches nimanim, cairo, nimib and nimib's dependencies at pinned commits into
  `deps/` (not committed) and applies `patches/nimanim-write-fix.patch`, which fixes
  nimanim's `write()` animation. `config.nims` puts them on the path.

Needs Nim 1.6 or later, the Cairo and FreeType dev libraries, and ffmpeg. From the page folder:

```sh
sh src/deps.sh
nim c -r -d:release src/scene.nim   # writes affinity_propagation.mp4 to the current dir
ffmpeg -ss 44 -i affinity_propagation.mp4 -frames:v 1 -q:v 4 poster.jpg
nim c -r src/index.nim              # writes index.html
```
