// qjs.nim: appended to Pele's bundle, the one function Nim calls
globalThis.__mari = function (line) {
  const q = JSON.parse(line);
  const r = pele.render(q.source, q.options || {});
  const a = { ok: true, svg: r.svg, type: r.type, ends: {} };
  if (r.type === 'flowchart') for (const e of pele.parse(q.source).edges) a.ends[e.id] = [e.start, e.end];
  return JSON.stringify(a);           // errors: {ok: false, code, message, line, column, snippet}
};
