// The race: who knows the dependency graph, and when.
// Clone-first (nimble, atlas, nimby): the registry only maps names to git URLs, so the graph is
// discovered level by level, by listing tags and cloning each package to read its .nimble file.
// Index-first (conda, pixi): the channel's repodata already holds every edge, so one fetch gives
// the whole graph, the solve is local, and every package is downloaded at once.
(function () {
  const data = JSON.parse(document.getElementById("rc-data").textContent);
  const $ = (id) => document.getElementById(id);
  let pkg = Object.keys(data)[0], step = 0, timer = null, plans = null;

  function levels(deps, root) {
    const depth = { [root]: 0 }, q = [root];
    while (q.length) {
      const n = q.shift();
      for (const d of deps[n] || []) if (!(d in depth)) { depth[d] = depth[n] + 1; q.push(d); }
    }
    const out = [];
    for (const [n, l] of Object.entries(depth)) (out[l] = out[l] || []).push(n);
    return out;
  }

  // Each plan is a list of frames: {log, st: {name: state}, m: {meter: value}}.
  function clonePlan(deps, root) {
    const names = Object.keys(deps), st = {}, m = { "round trips": 0, "git ops": 0, ".nimble read": 0 };
    names.forEach((n) => (st[n] = "unknown"));
    const frames = [{ log: "nothing known yet", st: { ...st }, m: { ...m } }];
    const snap = (log) => frames.push({ log, st: { ...st }, m: { ...m } });
    m["round trips"]++; st[root] = "known";
    snap("GET packages.json (2.9 MB): " + root + " → its git URL. No versions, no dependencies.");
    let frontier = [root];
    const seen = new Set([root]);
    while (frontier.length) {
      m["round trips"]++; m["git ops"] += frontier.length;
      frontier.forEach((n) => (st[n] = "busy"));
      snap("git ls-remote --tags, " + frontier.length + " repo" + (frontier.length > 1 ? "s" : "") + " in parallel: which versions exist?");
      m["round trips"]++; m["git ops"] += frontier.length; m[".nimble read"] += frontier.length;
      const next = [];
      for (const n of frontier) {
        st[n] = "got";
        for (const d of deps[n]) if (!seen.has(d)) { seen.add(d); next.push(d); st[d] = "known"; }
      }
      snap("git clone at the tag, read " + frontier.map((n) => n + ".nimble").join(", ") +
        (next.length ? " → found " + next.join(", ") : " → no new dependencies"));
      frontier = next;
    }
    frames[frames.length - 1].done = true;
    return frames;
  }

  function indexPlan(deps, root) {
    const names = Object.keys(deps), st = {}, m = { "round trips": 0, "downloads": 0, ".nimble read": 0 };
    names.forEach((n) => (st[n] = "unknown"));
    const frames = [{ log: "nothing known yet", st: { ...st }, m: { ...m } }];
    const snap = (log) => frames.push({ log, st: { ...st }, m: { ...m } });
    m["round trips"]++; names.forEach((n) => (st[n] = "known"));
    snap("GET repodata (noarch + linux-64): every package, version and dependency edge is in it.");
    names.forEach((n) => (st[n] = "busy"));
    snap("solve locally (resolvo, a SAT solver in Rust): no network. Picks " + names.length + " packages.");
    m["round trips"]++; m["downloads"] = names.length; names.forEach((n) => (st[n] = "got"));
    snap("download " + names.length + " .conda files at once, hard-link them into the env. Done.");
    frames[frames.length - 1].done = true;
    return frames;
  }

  function lane(el, title, sub, frames, versions, lv) {
    const f = frames[Math.min(step, frames.length - 1)];
    let g = "";
    lv.forEach((names, i) => {
      g += '<div class="rc-level"><span class="rc-level-n">' + (i === 0 ? "root" : "dep " + i) + "</span>";
      for (const n of names) {
        const s = f.st[n];
        const label = s === "unknown" ? "?" : s === "got" ? n + " " + versions[n] : n;
        g += '<span class="rc-node ' + s + '">' + label + "</span>";
      }
      g += "</div>";
    });
    const meters = Object.entries(f.m).map(([k, v]) => "<span><b>" + v + "</b> " + k + "</span>").join("");
    el.innerHTML = "<h4>" + title + '</h4><p class="rc-sub">' + sub + '</p><div class="rc-meters">' + meters +
      '</div><div class="rc-graph">' + g + '</div><p class="rc-log">' + (f.done && step >= frames.length - 1 ? "✓ " : "") + f.log + "</p>";
  }

  function render() {
    const d = data[pkg], lv = levels(d.deps, pkg);
    lane($("rc-clone"), "Clone-first: nimble, atlas, nimby", "the registry maps names to git URLs; the graph lives in the .nimble files",
      plans.clone, d.versions, lv);
    lane($("rc-index"), "Index-first: conda, pixi", "the channel's repodata already holds every edge", plans.index, d.versions, lv);
    const last = Math.max(plans.clone.length, plans.index.length) - 1;
    $("rc-step").disabled = step >= last;
    const c = plans.clone[plans.clone.length - 1].m, i = plans.index[plans.index.length - 1].m;
    $("rc-verdict").innerHTML = step >= last
      ? "<b>" + pkg + "</b>: clone-first needed <b>" + c["round trips"] + "</b> round trips, one after the other, and <b>" +
        c["git ops"] + "</b> git operations. Index-first needed <b>" + i["round trips"] +
        "</b>, whatever the depth of the tree. The difference grows with every level of dependencies."
      : step >= plans.index.length - 1
        ? "conda is done. Clone-first still cannot see the bottom of the tree."
        : "Press <b>Next round trip</b>: both sides make one network round trip per press.";
  }

  function reset() {
    stop(); step = 0;
    plans = { clone: clonePlan(data[pkg].deps, pkg), index: indexPlan(data[pkg].deps, pkg) };
    render();
  }
  function stop() { if (timer) { clearInterval(timer); timer = null; $("rc-play").textContent = "▶ Play"; } }
  function next() {
    const last = Math.max(plans.clone.length, plans.index.length) - 1;
    if (step < last) { step++; render(); }
    if (step >= last) stop();
  }

  const chips = $("rc-pkgs");
  for (const name of Object.keys(data)) {
    const b = document.createElement("button");
    b.type = "button"; b.className = "rc-chip"; b.textContent = name;
    b.setAttribute("aria-pressed", String(name === pkg));
    b.onclick = () => {
      pkg = name;
      chips.querySelectorAll("button").forEach((x) => x.setAttribute("aria-pressed", String(x === b)));
      reset();
    };
    chips.appendChild(b);
  }
  $("rc-step").onclick = () => { stop(); next(); };
  $("rc-reset").onclick = reset;
  $("rc-play").onclick = () => {
    if (timer) return stop();
    const last = Math.max(plans.clone.length, plans.index.length) - 1;
    if (step >= last) reset();
    $("rc-play").textContent = "⏸ Pause";
    timer = setInterval(next, 1100);
  };
  reset();
})();
