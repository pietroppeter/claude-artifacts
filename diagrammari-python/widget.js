// diagrammari editor widget (anywidget): draw Mermaid with Pele, drag boxes, shape arrows,
// and keep the personal layer in sync with Python (`layer` trait). The Pele bundle is put in
// front of this file by widget.py, so `pele` is in scope. Same geometry as layer.nim.

const THEMES = {
  pele: { font: "sans-serif", vars: {} },
  tufte: { font: '"Crimson Pro", Georgia, serif', vars: { "--pele-bg": "#fffff8", "--pele-fg": "#111", "--pele-surface": "#fffff8", "--pele-border": "#111", "--pele-line": "#111", "--pele-accent": "#a4161a", "--pele-radius": "0px" } },
  isotype: { font: "Jost, Futura, sans-serif", vars: { "--pele-bg": "#f1ead9", "--pele-fg": "#1c1b19", "--pele-surface": "#e2a52a", "--pele-border": "#1c1b19", "--pele-line": "#1c1b19", "--pele-accent": "#c8402b", "--pele-radius": "0px" } },
  blueprint: { font: '"IBM Plex Mono", monospace', vars: { "--pele-bg": "#1d4f7a", "--pele-fg": "#f4f8fb", "--pele-surface": "#1d4f7a", "--pele-border": "#f4f8fb", "--pele-line": "#f4f8fb", "--pele-accent": "#ffd166", "--pele-radius": "0px", "--pele-muted": "#bcd" } },
  mari: { font: "Archivo, Helvetica, sans-serif", vars: { "--pele-bg": "#fbfaf6", "--pele-fg": "#161616", "--pele-surface": "#e3c48c", "--pele-border": "#161616", "--pele-line": "#161616", "--pele-accent": "#d2361f", "--pele-radius": "0px" } },
};
const ARROWS = ["pele", "straight", "elbow", "curve"];
const ROUTES = ["auto", "straight", "elbow", "curve", "bezier"];
const FILLS = ["#c8402b", "#2d5d8c", "#4c7a47", "#e2a52a", ""];
const CSS = `
.mari-w{font:13px system-ui,sans-serif;border:1px solid #ccc;border-radius:6px;overflow:hidden;background:#fff;color:#222}
.mari-w .bar{display:flex;flex-wrap:wrap;gap:6px;align-items:center;padding:6px 8px;border-bottom:1px solid #ddd;background:#fafafa}
.mari-w .bar select,.mari-w .bar button{font:inherit;padding:2px 6px;border:1px solid #bbb;border-radius:4px;background:#fff;color:#222;cursor:pointer}
.mari-w .bar button[aria-pressed=true]{background:#222;color:#fff}
.mari-w .sw{width:18px;height:18px;border:1px solid #888;border-radius:3px;padding:0}
.mari-w .stage{display:grid;place-items:center;padding:16px;min-height:160px;touch-action:none}
.mari-w svg{overflow:visible;max-width:100%;height:auto;user-select:none}
.mari-w .pele-node{cursor:grab}
.mari-w .pele-node.sel>:not(text){stroke:#d2361f!important;stroke-width:2.5px}
.mari-w .hit{stroke:transparent;stroke-width:14;fill:none;pointer-events:stroke;cursor:pointer}
.mari-w .pele-edge.sel path:not(.hit):not(.pele-marker){stroke:#d2361f}
.mari-w .handles line{stroke:#d2361f;stroke-dasharray:3 3}
.mari-w .handles circle{fill:#fff;stroke:#d2361f;stroke-width:2;cursor:move}
.mari-w .err{color:#b00;padding:6px 8px;font-family:monospace;white-space:pre}`;

// ---------- geometry (as in layer.nim) ----------
const P = (x, y) => ({ x, y }), add = (a, b) => P(a.x + b.x, a.y + b.y), sub = (a, b) => P(a.x - b.x, a.y - b.y), mul = (a, k) => P(a.x * k, a.y * k);
const len = (a) => Math.hypot(a.x, a.y) || 1, unit = (a) => mul(a, 1 / len(a)), f = (n) => Math.round(n * 100) / 100;
function boundary(n, t) {
  const d = sub(t, n), hw = n.w / 2, hh = n.h / 2;
  if (!d.x && !d.y) return P(n.x, n.y);
  let s;
  if (n.shape === "circle") s = hw / len(d);
  else if (n.shape === "diam") s = 1 / (Math.abs(d.x) / hw + Math.abs(d.y) / hh);
  else s = Math.min(d.x ? hw / Math.abs(d.x) : Infinity, d.y ? hh / Math.abs(d.y) : Infinity);
  return add(n, mul(d, s));
}
function ports(A, B) {
  const d = sub(B, A), hz = Math.abs(d.x) >= Math.abs(d.y);
  if (hz) { const s = Math.sign(d.x) || 1; return { hz, s, a: P(A.x + s * A.w / 2, A.y), b: P(B.x - s * B.w / 2, B.y) }; }
  const s = Math.sign(d.y) || 1; return { hz, s, a: P(A.x, A.y + s * A.h / 2), b: P(B.x, B.y - s * B.h / 2) };
}
const cubic = (p0, c1, c2, p1, t) => { const u = 1 - t; return P(u*u*u*p0.x + 3*u*u*t*c1.x + 3*u*t*t*c2.x + t*t*t*p1.x, u*u*u*p0.y + 3*u*u*t*c1.y + 3*u*t*t*c2.y + t*t*t*p1.y); };
function curveCtl(pr) {
  const k = Math.max(36, Math.abs(pr.hz ? pr.b.x - pr.a.x : pr.b.y - pr.a.y) / 2);
  return pr.hz ? [P(pr.a.x + pr.s * k, pr.a.y), P(pr.b.x - pr.s * k, pr.b.y)] : [P(pr.a.x, pr.a.y + pr.s * k), P(pr.b.x, pr.b.y - pr.s * k)];
}
function tri(tip, dir) {
  const u = unit(dir), n = P(-u.y, u.x), b = sub(tip, mul(u, 8));
  return `M${f(tip.x)},${f(tip.y)}L${f(b.x + n.x * 3.36)},${f(b.y + n.y * 3.36)}L${f(b.x - n.x * 3.36)},${f(b.y - n.y * 3.36)}Z`;
}
const nums = (s) => (s.match(/-?\d*\.?\d+/g) || []).map(Number);
function sizeOf(g) {
  for (const c of g.children) {
    if (c.tagName === "text" || c.classList.contains("pele-label")) continue;
    if (c.tagName === "rect") return [+c.getAttribute("width"), +c.getAttribute("height")];
    if (c.tagName === "circle") return [2 * c.getAttribute("r"), 2 * c.getAttribute("r")];
    if (c.tagName === "ellipse") return [2 * c.getAttribute("rx"), 2 * c.getAttribute("ry")];
    if (c.tagName === "polygon" || c.tagName === "path") {
      const v = nums(c.getAttribute(c.tagName === "polygon" ? "points" : "d")), xs = v.filter((_, i) => i % 2 === 0), ys = v.filter((_, i) => i % 2 === 1);
      if (xs.length) return [Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys)];
    }
  }
  return [0, 0];
}

// ---------- draw and apply ----------
let uid = 0;
function draw(stage, src, layer) {
  const th = THEMES[layer.theme] || THEMES.pele;
  for (const [k, v] of Object.entries(THEMES.blueprint.vars)) stage.style.removeProperty(k);
  for (const [k, v] of Object.entries(th.vars)) stage.style.setProperty(k, v);
  stage.style.background = th.vars["--pele-bg"] || "#fff";
  const pre = "w" + uid++ + "-";
  const r = pele.render(src, { fontFamily: th.font, idPrefix: pre });
  stage.innerHTML = r.svg;
  const svg = stage.querySelector("svg");
  const st = { svg, type: r.type, nodes: new Map(), edges: [], vb0: svg.getAttribute("viewBox").split(/\s+/).map(Number) };
  if (r.type !== "flowchart") return st;
  const ends = new Map(pele.parse(src).edges.map((e) => [e.id, [e.start, e.end]]));
  svg.querySelectorAll("g.pele-node[data-id]").forEach((g) => {
    const m = nums(g.getAttribute("transform") || ""); if (m.length < 2) return;
    const shapes = [...g.children].filter((e) => e.tagName !== "text" && !e.classList.contains("pele-label"));
    const [w, h] = sizeOf(g), cls = g.getAttribute("class");
    const shape = /circle|ellipse/.test(cls) ? "circle" : /diam|hex/.test(cls) ? "diam" : "rect";
    st.nodes.set(g.dataset.id, { id: g.dataset.id, g, shapes, fill0: shapes.map((s) => s.getAttribute("fill")), cx: m[0], cy: m[1], w, h, shape, x: m[0], y: m[1] });
  });
  svg.querySelectorAll("g.pele-edge[data-id]").forEach((g) => {
    const id = g.dataset.id, se = ends.get(id); if (!se) return;
    const path = g.querySelector("path:not(.pele-marker)"); if (!path) return;
    const d0 = path.getAttribute("d"), v = nums(d0), S = P(v[0], v[1]), E = P(v[v.length - 2], v[v.length - 1]);
    const markers = [...g.querySelectorAll("path.pele-marker")].map((el) => { const q = nums(el.getAttribute("d")), tip = P(q[0], q[1]); return { el, d0: el.getAttribute("d"), atEnd: len(sub(tip, E)) <= len(sub(tip, S)) }; });
    const lab = svg.querySelector(`g.pele-edge-label[data-id="${id}"]`);
    let label = null; if (lab) { const rc = lab.querySelector("rect"); label = { g: lab, c0: rc ? P(+rc.getAttribute("x") + +rc.getAttribute("width") / 2, +rc.getAttribute("y") + +rc.getAttribute("height") / 2) : null }; }
    const hit = document.createElementNS("http://www.w3.org/2000/svg", "path"); hit.setAttribute("class", "hit"); hit.dataset.edge = id; g.appendChild(hit);
    st.edges.push({ id, g, path, d0, markers, label, hit, from: se[0], to: se[1] });
  });
  const h = document.createElementNS("http://www.w3.org/2000/svg", "g"); h.setAttribute("class", "handles"); svg.appendChild(h); st.handles = h;
  return st;
}

function apply(st, layer, sel) {
  if (st.type !== "flowchart") return;
  const pts = [], ln = layer.nodes || {}, le = layer.edges || {}, arrows = layer.arrows || "pele";
  for (const n of st.nodes.values()) {
    const o = ln[n.id] || {};
    n.x = n.cx + (+o.dx || 0); n.y = n.cy + (+o.dy || 0); n.moved = !!(+o.dx || +o.dy);
    n.g.setAttribute("transform", `translate(${f(n.x)},${f(n.y)})`);
    n.shapes.forEach((s, i) => { if (n.fill0[i] != null) s.setAttribute("fill", o.fill && n.fill0[i] !== "none" ? o.fill : n.fill0[i]); });
    n.g.classList.toggle("sel", !!sel && sel.node === n.id);
    pts.push(P(n.x - n.w / 2, n.y - n.h / 2), P(n.x + n.w / 2, n.y + n.h / 2));
  }
  st.handles.innerHTML = "";
  for (const e of st.edges) {
    const A = st.nodes.get(e.from), B = st.nodes.get(e.to), o = le[e.id] || {};
    const mode = o.route && o.route !== "auto" ? o.route : (A && A.moved) || (B && B.moved) ? (arrows === "pele" ? "curve" : arrows) : arrows;
    e.g.classList.toggle("sel", !!sel && sel.edge === e.id);
    if (!A || !B || A === B || !["straight", "elbow", "curve", "bezier"].includes(mode)) {
      e.path.setAttribute("d", e.d0); e.markers.forEach((m) => m.el.setAttribute("d", m.d0)); if (e.label) e.label.g.removeAttribute("transform"); e.hit.setAttribute("d", e.d0); continue;
    }
    let a, b, c1, c2, mid, dA, dB, d;
    const hasS = e.markers.some((m) => !m.atEnd), hasE = e.markers.some((m) => m.atEnd);
    if (mode === "straight") { a = boundary(A, B); b = boundary(B, A); dA = sub(a, b); dB = sub(b, a); mid = mul(add(a, b), 0.5); }
    else {
      const pr = ports(A, B); a = pr.a; b = pr.b;
      if (mode === "elbow") {
        if (pr.hz) { const mx = (a.x + b.x) / 2; mid = P(mx, (a.y + b.y) / 2); c1 = P(mx, a.y); c2 = P(mx, b.y); }
        else { const my = (a.y + b.y) / 2; mid = P((a.x + b.x) / 2, my); c1 = P(a.x, my); c2 = P(b.x, my); }
      } else {
        [c1, c2] = curveCtl(pr);
        if (mode === "bezier") { if (o.c1) c1 = P(a.x + o.c1[0], a.y + o.c1[1]); if (o.c2) c2 = P(b.x + o.c2[0], b.y + o.c2[1]); }
        mid = cubic(a, c1, c2, b, 0.5); pts.push(cubic(a, c1, c2, b, 0.25), cubic(a, c1, c2, b, 0.75));
      }
      dA = sub(a, c1); dB = sub(b, c2);
    }
    const a2 = hasS ? sub(a, mul(unit(dA), 7)) : a, b2 = hasE ? sub(b, mul(unit(dB), 7)) : b;
    if (mode === "straight") d = `M${f(a2.x)},${f(a2.y)}L${f(b2.x)},${f(b2.y)}`;
    else if (mode === "elbow") d = `M${f(a2.x)},${f(a2.y)}L${f(c1.x)},${f(c1.y)}L${f(c2.x)},${f(c2.y)}L${f(b2.x)},${f(b2.y)}`;
    else d = `M${f(a2.x)},${f(a2.y)}C${f(c1.x)},${f(c1.y)} ${f(c2.x)},${f(c2.y)} ${f(b2.x)},${f(b2.y)}`;
    e.path.setAttribute("d", d); e.hit.setAttribute("d", d);
    e.markers.forEach((m) => m.el.setAttribute("d", m.atEnd ? tri(b, dB) : tri(a, dA)));
    if (e.label && e.label.c0) { const t = sub(mid, e.label.c0); e.label.g.setAttribute("transform", `translate(${f(t.x)},${f(t.y)})`); pts.push(P(mid.x - 20, mid.y - 12), P(mid.x + 20, mid.y + 12)); }
    if (sel && sel.edge === e.id && mode === "bezier") {
      st.handles.innerHTML = `<line x1="${a.x}" y1="${a.y}" x2="${c1.x}" y2="${c1.y}"/><line x1="${b.x}" y1="${b.y}" x2="${c2.x}" y2="${c2.y}"/><circle data-h="c1" cx="${c1.x}" cy="${c1.y}" r="6"/><circle data-h="c2" cx="${c2.x}" cy="${c2.y}" r="6"/>`;
      st.handles.anchor = { a, b };
    }
  }
  const [x0, y0, w0, h0] = st.vb0; let x1 = x0, y1 = y0, x2 = x0 + w0, y2 = y0 + h0;
  pts.forEach((p) => { x1 = Math.min(x1, p.x - 12); y1 = Math.min(y1, p.y - 12); x2 = Math.max(x2, p.x + 12); y2 = Math.max(y2, p.y + 12); });
  st.svg.setAttribute("viewBox", `${f(x1)} ${f(y1)} ${f(x2 - x1)} ${f(y2 - y1)}`);
  st.svg.setAttribute("width", f(x2 - x1)); st.svg.setAttribute("height", f(y2 - y1));
}

// ---------- the widget ----------
const clone = (o) => JSON.parse(JSON.stringify(o || {}));
const norm = (l) => ({ theme: "pele", arrows: "pele", ...clone(l), nodes: clone(l && l.nodes), edges: clone(l && l.edges) });

function render({ model, el }) {
  // The style goes inside the widget: marimo puts widgets in a shadow root.
  el.innerHTML = `<style>${CSS}</style><div class="mari-w"><div class="bar"></div><div class="stage"></div><div class="err"></div></div>`;
  const bar = el.querySelector(".bar"), stage = el.querySelector(".stage"), err = el.querySelector(".err");
  let layer = norm(model.get("layer")), sel = null, st = null, drag = null;
  const save = () => { model.set("layer", clone(layer)); model.set("svg", st ? st.svg.outerHTML : ""); model.save_changes(); };
  function toolbar() {
    let h = `theme <select data-k="theme">${Object.keys(THEMES).map((t) => `<option ${t === layer.theme ? "selected" : ""}>${t}</option>`).join("")}</select>
      arrows <select data-k="arrows">${ARROWS.map((t) => `<option ${t === layer.arrows ? "selected" : ""}>${t}</option>`).join("")}</select>`;
    if (sel && sel.node) h += ` · <code>${sel.node}</code> ${FILLS.map((c) => `<button class="sw" data-fill="${c}" style="background:${c || "#fff"}" title="${c || "default"}"></button>`).join("")} <button data-act="home">reset box</button>`;
    if (sel && sel.edge) { const cur = (layer.edges[sel.edge] || {}).route || "auto"; h += ` · <code>${sel.edge}</code> ${ROUTES.map((r) => `<button data-route="${r}" aria-pressed="${r === cur}">${r}</button>`).join("")}`; }
    h += ` <button data-act="clear" style="margin-left:auto">clear layer</button>`;
    bar.innerHTML = h;
  }
  bar.addEventListener("change", (ev) => { const k = ev.target.dataset.k; if (!k) return; layer[k] = ev.target.value; k === "theme" ? full() : refresh(); save(); });
  bar.addEventListener("click", (ev) => {
    const b = ev.target.closest("button"); if (!b) return;
    if (b.dataset.act === "clear") { layer = norm({ theme: layer.theme }); sel = null; full(); save(); return; }
    if (!sel) return;
    if (b.dataset.fill !== undefined) { const o = (layer.nodes[sel.node] ||= {}); if (b.dataset.fill) o.fill = b.dataset.fill; else delete o.fill; }
    else if (b.dataset.act === "home") { const o = layer.nodes[sel.node]; if (o) { delete o.dx; delete o.dy; } }
    else if (b.dataset.route) {
      const r = b.dataset.route;
      if (r === "auto") delete layer.edges[sel.edge];
      else { const o = (layer.edges[sel.edge] = { route: r }); if (r === "bezier") { const e = st.edges.find((x) => x.id === sel.edge), A = st.nodes.get(e.from), B = st.nodes.get(e.to), pr = ports(A, B), [c1, c2] = curveCtl(pr); o.c1 = [f(c1.x - pr.a.x), f(c1.y - pr.a.y)]; o.c2 = [f(c2.x - pr.b.x), f(c2.y - pr.b.y)]; } }
    }
    for (const [k, o] of Object.entries(layer.nodes)) if (!Object.keys(o).length) delete layer.nodes[k];
    refresh(); save();
  });
  function refresh() { if (st) apply(st, layer, sel); toolbar(); }
  async function full() {
    const th = THEMES[layer.theme] || THEMES.pele;
    try { await document.fonts.load("16px " + th.font); } catch (e) {}
    try { st = draw(stage, model.get("source"), layer); err.textContent = ""; }
    catch (e) { err.textContent = (e.code ? e.code + ": " : "") + (e.message || e) + (e.snippet ? "\n" + e.snippet : ""); st = null; }
    if (sel && sel.node && st && !st.nodes.has(sel.node)) sel = null;
    refresh();
  }
  const svgPt = (ev) => { const p = st.svg.createSVGPoint(); p.x = ev.clientX; p.y = ev.clientY; return p.matrixTransform(st.svg.getScreenCTM().inverse()); };
  stage.addEventListener("pointerdown", (ev) => {
    if (!st || st.type !== "flowchart") return;
    const h = ev.target.closest(".handles circle"), hit = ev.target.closest(".hit"), node = ev.target.closest("g.pele-node"), p = svgPt(ev);
    if (h) drag = { kind: "h", h: h.dataset.h, p0: p };
    else if (hit) { sel = { edge: hit.dataset.edge }; refresh(); return; }
    else if (node && st.nodes.has(node.dataset.id)) { const id = node.dataset.id, o = layer.nodes[id] || {}; sel = { node: id }; drag = { kind: "n", id, p0: p, dx: +o.dx || 0, dy: +o.dy || 0 }; refresh(); }
    else { sel = null; refresh(); return; }
    stage.setPointerCapture(ev.pointerId); ev.preventDefault();
  });
  stage.addEventListener("pointermove", (ev) => {
    if (!drag) return; const p = svgPt(ev);
    if (drag.kind === "n") {
      const dx = Math.round((drag.dx + p.x - drag.p0.x) / 4) * 4, dy = Math.round((drag.dy + p.y - drag.p0.y) / 4) * 4;
      const o = (layer.nodes[drag.id] ||= {}); if (dx) o.dx = dx; else delete o.dx; if (dy) o.dy = dy; else delete o.dy;
      if (!Object.keys(o).length) delete layer.nodes[drag.id];
    } else { const o = layer.edges[sel.edge], an = st.handles.anchor; if (!o || !an) return; const base = drag.h === "c1" ? an.a : an.b; o[drag.h] = [Math.round(p.x - base.x), Math.round(p.y - base.y)]; }
    apply(st, layer, sel);
  });
  const end = () => { if (drag) { drag = null; refresh(); save(); } };
  stage.addEventListener("pointerup", end); stage.addEventListener("pointercancel", end);
  model.on("change:source", () => full());
  model.on("change:layer", () => { const l = norm(model.get("layer")); if (JSON.stringify(l) !== JSON.stringify(layer)) { const re = l.theme !== layer.theme; layer = l; re ? full() : refresh(); } });
  full();
}

export default { render };
