import json, subprocess, time, quickjs
bundle = open("pele.global.js").read()
sources = json.load(open("cmp_src.json"))   # a flowchart, a sequence, a pie, a class diagram
node = json.loads(subprocess.run(["node", "-e", """
const vm=require('vm'),fs=require('fs');vm.runInThisContext(fs.readFileSync('pele.global.js','utf8'));
console.log(JSON.stringify(JSON.parse(fs.readFileSync('cmp_src.json')).map(s=>pele.render(s,{idPrefix:'p-'}).svg)))"""],
  capture_output=True, text=True).stdout)
t = time.perf_counter(); ctx = quickjs.Context(); ctx.eval(bundle); load = time.perf_counter() - t
render = ctx.eval("(s) => pele.render(s, {idPrefix: 'p-'}).svg")
t = time.perf_counter(); qjs = [render(s) for s in sources]; each = (time.perf_counter() - t) / len(sources)
print("same SVG as Node:", [a == b for a, b in zip(qjs, node)])
print(f"QuickJS: load Pele {load*1000:.0f} ms, then {each*1000:.2f} ms a diagram")
