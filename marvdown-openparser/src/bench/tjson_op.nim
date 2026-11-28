import std/tables
import openparser/json

type
  NbBlock = ref object of RootObj
    kind: string
  NbCode = ref object of NbBlock
    code, output: string
  NbContainer = ref object of NbBlock
    blocks: seq[NbBlock]

var registry: Table[string, proc (node: JsonNode): NbBlock]

method dump(n: NbBlock): string {.base.} = toJson(n[])
proc dumpHook(s: var string, v: NbBlock) = s.add v.dump()

template register(T: typedesc) =
  registry[$T] = proc (node: JsonNode): NbBlock =
    var v: T
    new v
    v[] = fromJson($node, typeof(v[]))   # re-serialize and re-parse: no rewind in openparser's hooks
    v
  method dump(n: T): string = toJson(n[])

proc parseHook(p: var JsonParser, v: var NbBlock) =
  var node: JsonNode
  parseHook(p, node)
  v = registry[node["kind"].getStr](node)

register(NbBlock)
register(NbCode)
register(NbContainer)

let doc = NbContainer(kind: "NbContainer", blocks: @[NbBlock(NbCode(kind: "NbCode", code: "echo 1", output: "1\n")),
  NbBlock(NbContainer(kind: "NbContainer", blocks: @[NbBlock(NbCode(kind: "NbCode", code: "nested"))]))])
let s = toJson(NbBlock(doc))
echo s
let back = fromJson(s, NbBlock)
echo back.kind, " ", NbContainer(back).blocks.len, " ", NbCode(NbContainer(back).blocks[0]).output.len, " ", NbCode(NbContainer(NbContainer(back).blocks[1]).blocks[0]).code
echo toJson(back) == s
