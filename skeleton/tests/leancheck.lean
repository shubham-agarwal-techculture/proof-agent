/-
  tests/leancheck.lean — exercises the Lean check tool against four sources.

  Expected: `good` compiles; `bad` and `unknown` fail with an error diagnostic; `sorry` *compiles*
  (warning only) — showing why the gate (not the compiler) must reject `sorry` (invariant A1).
-/
import ProofAgent.Tools.LeanCheck

open ProofAgent

def good    := "theorem t1 : 1 + 1 = 2 := rfl"
def bad     := "theorem t2 : 1 + 1 = 3 := rfl"
def sorryT  := "theorem t3 : 1 + 1 = 2 := by sorry"
def unknown := "theorem t4 : 1 + 1 = 2 := by nonexistent_tactic_xyz"

def demo : IO Unit := do
  let r1 ← checkSource good
  let r2 ← checkSource bad
  let r3 ← checkSource sorryT
  let r4 ← checkSource unknown
  IO.println s!"good    ok={r1.ok}   (expect true)"
  IO.println s!"bad     ok={r2.ok}   (expect false)"
  IO.println s!"sorry   ok={r3.ok}   (expect true: compiles, warning only)"
  IO.println s!"unknown ok={r4.ok}   (expect false)"
  IO.println s!"bad     diagnostics = {repr r2.diagnostics}"
  IO.println s!"sorry   diagnostics = {repr r3.diagnostics}"

#eval demo
