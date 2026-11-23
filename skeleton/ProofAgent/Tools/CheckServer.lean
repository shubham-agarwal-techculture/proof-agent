/-
  ProofAgent/Tools/CheckServer.lean — a tiny line-oriented tool server over the Lean tools.

  Reads one JSON request per line on stdin and writes one JSON response per line on stdout.  The
  `op` field selects the tool (default `"check"`):

    check :  {"id": "<any>", "op": "check", "source": "<lean source>"}
          -> {"id": "<any>", "ok": <bool>, "diagnostics": [{"severity","line","column","message"}]}

    goals :  {"id": "<any>", "op": "goals", "statement": "<proposition>"}
          -> {"id": "<any>", "ok": <bool>, "goals": ["<goal block>", ...], "raw": "<raw>"}

  This is the MCP-tool shape in miniature (one long-lived process, many requests) that the prover
  loop's tool layer will use.  Run it with `lake exe checkServer`.
-/
import ProofAgent.Tools.LeanCheck
import ProofAgent.Tools.GoalState

open Lean

namespace ProofAgent

/-- Handle one already-parsed request, returning the response fields (minus `id`). -/
def respond (j : Json) : IO (List (String × Json)) := do
  let op := (j.getObjValAs? String "op").toOption.getD "check"
  if op == "goals" then
    let stmt := (j.getObjValAs? String "statement").toOption.getD ""
    let gs ← goalState stmt
    return [ ("ok", Json.bool gs.ok)
           , ("goals", Json.arr (gs.goals.map Json.str))
           , ("raw", Json.str gs.raw) ]
  else
    let src := (j.getObjValAs? String "source").toOption.getD ""
    let res ← checkSource src
    let diags := Json.arr (res.diagnostics.map (fun d => Json.mkObj
      [ ("severity", Json.str d.severity)
      , ("line", Json.str (toString d.line))
      , ("column", Json.str (toString d.column))
      , ("message", Json.str d.message) ]))
    return [("ok", Json.bool res.ok), ("diagnostics", diags)]

/-- Serve requests until EOF on stdin.  (Runtime loop, so `partial` is appropriate.) -/
partial def serve : IO Unit := do
  let stdin ← IO.getStdin
  let line ← stdin.getLine
  if line.isEmpty then return ()   -- EOF
  match Json.parse line with
  | .error _ =>
    IO.println (Json.compress (Json.mkObj [("ok", Json.bool false), ("error", Json.str "bad request")]))
  | .ok j =>
    let id   := (j.getObjValAs? String "id").toOption
    let base ← respond j
    let fields := match id with
      | some n => ("id", Json.str n) :: base
      | none   => base
    IO.println (Json.compress (Json.mkObj fields))
  serve

end ProofAgent

def main : IO Unit := ProofAgent.serve
