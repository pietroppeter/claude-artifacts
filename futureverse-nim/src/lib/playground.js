{
  // 12 tasks of different lengths (in "seconds"); element i goes to worker i mod n, like fv's threads.
  const dur = [3, 1, 2, 4, 2, 1, 3, 2, 1, 4, 2, 1];
  const $ = id => document.getElementById(id);
  let perElement = true;
  // a small seeded generator (mulberry32) and fv's splitmix-style mixing of (seed, i)
  const rng = s => () => { s |= 0; s = s + 0x6D2B79F5 | 0; let t = Math.imul(s ^ s >>> 15, 1 | s);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; };
  const mix = (seed, i) => Math.imul(seed ^ (i + 1) * 0x9E3779B1, 0x85EBCA6B) ^ (i * 0xC2B2AE35);
  const die = r => 1 + Math.floor(r() * 6);
  function roll(n) {
    const out = new Array(dur.length);
    if (perElement) { dur.forEach((_, i) => out[i] = die(rng(mix(42, i)))); return out; }
    for (let w = 0; w < n; w++) {           // one stream per worker, used in the worker's order
      const r = rng(mix(42, 1000 + w));
      for (let i = w; i < dur.length; i += n) out[i] = die(r);
    }
    return out;
  }
  const faces = ["", "⚀", "⚁", "⚂", "⚃", "⚄", "⚅"];
  function draw() {
    const n = +$("pg-workers").value;
    $("pg-n").textContent = n;
    const total = dur.reduce((a, b) => a + b, 0);
    let lanes = "", wall = 0;
    for (let w = 0; w < n; w++) {
      let row = "", t = 0;
      for (let i = w; i < dur.length; i += n) {
        row += `<span class="pg-task" style="flex:${dur[i]} 0 0">${i + 1}</span>`; t += dur[i];
      }
      wall = Math.max(wall, t);
      lanes += `<div class="pg-lane"><span class="pg-who">w${w + 1}</span><div class="pg-bar" style="width:${(t / total * 100).toFixed(1)}%">${row}</div></div>`;
    }
    $("pg-lanes").innerHTML = lanes;
    $("pg-time").innerHTML = `wall time <b>${wall} s</b> instead of ${total} s: ${(total / wall).toFixed(1)}× faster` +
      (n > 1 && wall > Math.ceil(total / n) ? ` (an ideal split would take ${Math.ceil(total / n)} s: the longest lane decides)` : "");
    const base = roll(1), now = roll(n);
    $("pg-dice").innerHTML = now.map((d, i) => `<span class="pg-die${d !== base[i] ? " moved" : ""}" title="element ${i + 1}">${faces[d]}</span>`).join("");
    const moved = now.filter((d, i) => d !== base[i]).length;
    $("pg-verdict").textContent = perElement
      ? "Same dice for any number of workers: each element has its own stream."
      : moved ? `${moved} of 12 dice changed: the results depend on how many workers you had.` : "Same as 1 worker, but only by luck of this plan: try another.";
  }
  function seedMode(e) {
    perElement = e;
    $("pg-elem").setAttribute("aria-pressed", e); $("pg-work").setAttribute("aria-pressed", !e);
    draw();
  }
  $("pg-workers").addEventListener("input", draw);
  $("pg-elem").addEventListener("click", () => seedMode(true));
  $("pg-work").addEventListener("click", () => seedMode(false));
  draw();
}
