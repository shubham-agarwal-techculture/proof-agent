# How to Add a Tool to the Server

*Add a new capability — a module under `ProofAgent/Tools/` plus an `op` branch in the JSON tool server — using the existing `goals` op as the worked model.*

`[exists today]` — the tool layer and the server exist and are runnable ([`LeanCheck.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/LeanCheck.lean), [`GoalState.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/GoalState.lean), [`CheckServer.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean)). Tools are **untrusted periphery**: they help agents *propose*, but they never adjudicate truth — only [`VerifierGate.gate`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean) does. So adding a tool must not touch the trusted core.

The `goals` op is the model: a small tool module ([`GoalState.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/GoalState.lean)) reusing the compiler plumbing in `LeanCheck.checkSource`, plus one branch in `respond`.

## 1. Decide whether the tool needs the compiler

- If it needs to compile Lean source or read diagnostics, build it on [`checkSource`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/LeanCheck.lean) (as `GoalState` does). That keeps the "one `lean --json` plumbing" property and the zero-extra-dependency rule (invariant #1).
- If it is pure computation over JSON/strings, no compiler call is needed.
- Either way: **Lean core only**. No Mathlib, no new packages.

## 2. Create the module under `ProofAgent/Tools/`

Add a file `skeleton/ProofAgent/Tools/Warnings.lean`. The worked example reports warning-severity diagnostics — useful precisely because it surfaces the **A1** case (a `sorry` proof compiles with only a warning). Note the shape mirrors `GoalState`: import the compiler tool, then define a function returning structured data.

```lean
/-
  ProofAgent/Tools/Warnings.lean — report warning-severity diagnostics (e.g. `sorry` uses).
-/
import ProofAgent.Tools.LeanCheck

namespace ProofAgent

/-- Warning-severity diagnostic messages from compiling `source`
    (e.g. "declaration uses `sorry`"). -/
def warnings (source : String) : IO (Array String) := do
  let res ← checkSource source
  return (res.diagnostics.filter (fun d => d.severity == "warning")).map (fun d => d.message)

end ProofAgent
```

Like every tool module, it lives in the `ProofAgent` namespace and exposes one small function. It does not classify truth; it reports what the compiler said.

## 3. Add a branch to `respond`, keyed on `op`

[`respond`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean) already dispatches on `op` (defaulting to `"check"`). Add your branch **before** the final `else` (which is the `check` default). Here is the existing `goals` branch for comparison, then the new `warnings` branch:

```lean
def respond (j : Json) : IO (List (String × Json)) := do
  let op := (j.getObjValAs? String "op").toOption.getD "check"
  if op == "goals" then
    let stmt := (j.getObjValAs? String "statement").toOption.getD ""
    let gs ← goalState stmt
    return [ ("ok", Json.bool gs.ok)
           , ("goals", Json.arr (gs.goals.map Json.str))
           , ("raw", Json.str gs.raw) ]
  else if op == "warnings" then                                  -- new branch
    let src := (j.getObjValAs? String "source").toOption.getD ""
    let ws ← warnings src
    return [ ("ok", Json.bool true)
           , ("warnings", Json.arr (ws.map Json.str)) ]
  else
    let src := (j.getObjValAs? String "source").toOption.getD ""
    let res ← checkSource src
    let diags := Json.arr (res.diagnostics.map (fun d => Json.mkObj
      [ ("severity", Json.str d.severity)
      , ("line", Json.str (toString d.line))
      , ("column", Json.str (toString d.column))
      , ("message", Json.str d.message) ]))
    return [("ok", Json.bool res.ok), ("diagnostics", diags)]
```

Two rules for a new branch:

- It must return `IO (List (String × Json))` — the type of `respond`. This explicit return type is required: an inline `if/else` inside `do` otherwise unifies to `Unit`.
- Do **not** echo `id`; `serve` prepends it for you. Just return your response fields.

## 4. Wire the imports

Two import edits, because the module must be reachable from both the server and the library root:

- In `CheckServer.lean`, add the import next to the other tool imports:

```lean
import ProofAgent.Tools.LeanCheck
import ProofAgent.Tools.GoalState
import ProofAgent.Tools.Warnings
```

- In [`ProofAgent.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent.lean) (the library root), add it so `lake build` compiles it as part of the library:

```lean
import ProofAgent.Tools.LeanCheck
import ProofAgent.Tools.GoalState
import ProofAgent.Tools.Warnings
```

## 5. Build and test the new op

```powershell
cd skeleton
lake build
'{"id":"w1","op":"warnings","source":"theorem t : 1 + 1 = 2 := by sorry"}' | lake exe checkServer
```

`lake exe checkServer` builds the `checkServer` exe target (root `ProofAgent.Tools.CheckServer`) and runs it, so it compiles your new branch.

## Verify it worked

The server must answer the `warnings` request with the compiler's warning for `sorry`, and the pre-existing ops must still work:

```json
{"id":"w1","ok":true,"warnings":["declaration uses `sorry`"]}
```

and, unchanged:

```json
{"diagnostics":[],"id":"r1","ok":true}
{"goals":["⊢ 1 + 1 = 2"],"id":"r2","ok":true,"raw":"unsolved goals\n⊢ 1 + 1 = 2"}
```

You can also add a small standalone test file `skeleton/tests/warnings.lean` and run it directly:

```lean
import ProofAgent.Tools.Warnings
open ProofAgent

def demo : IO Unit := do
  let ws ← warnings "theorem t : 1 + 1 = 2 := by sorry"
  IO.println s!"warnings = {repr ws}"

#eval demo
```

```powershell
lake env lean tests/warnings.lean
```

Checklist:

- [ ] `lake build` succeeds.
- [ ] The new `op` returns its field(s) plus `ok`, and the `id` is echoed.
- [ ] The default `check` op and the `goals` op are unchanged.
- [ ] A malformed line still yields `{"error":"bad request","ok":false}`.
- [ ] The tool calls only Lean core (no Mathlib), and the trusted core is untouched.

## Pitfalls

- **Forgetting the `CheckServer.lean` import** → `unknown identifier 'warnings'` at build time.
- **Relying on the `ProofAgent.lean` import for the server.** The server's dispatch lives in `CheckServer.lean`; add the import there too, or the exe target will not see your module.
- **Inline `if/else` with no result type.** The first version of `respond` failed exactly this way; that is why it was extracted with an explicit `IO (List (String × Json))` signature. Keep that signature and return a properly typed list.
- **Expecting tools to verify.** A tool answers "what did the compiler say?" — never "is this theorem true?". Only the gate disposes. Reporting a `sorry` warning is not rejecting a `sorry`.
- **Adding a dependency.** The tool layer is part of the zero-dependency posture; if your tool needs something like an interactive session, that is a design change (phase-9 §6), not a local tool addition.
- **Exact diagnostic text.** Warning/error messages are Lean's; assert on *presence/severity*, not on wording, if you add a test.

## See also

- [CheckServer.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean) — `respond`/`serve`, where you add the branch.
- [GoalState.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/GoalState.lean) — the worked model of a tool built on `checkSource`.
- [LeanCheck.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/LeanCheck.lean) — `checkSource` and the diagnostics it returns.
- [extend-the-gate.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/extend-the-gate.md) — the *other* extension point, which (unlike tools) touches the trusted core.
- [troubleshooting.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/troubleshooting.md) — the `if/else`-in-`do` and `partial` errors.
- [build-and-run.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/build-and-run.md) — running `lake exe checkServer`.
- [phase-9-walking-skeleton.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-9-walking-skeleton.md) — the tool layer (§5.3) and §6.
