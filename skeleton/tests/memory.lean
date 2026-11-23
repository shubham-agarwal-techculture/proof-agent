/-
  tests/memory.lean — exercises the append-only, content-addressed JSONL store and the
  end-to-end "gate then persist" path.

  Expected: direct insert once, dedup on the second insert, cheat rejected (NOT persisted),
  honest proof verified and persisted, clean JSONL round-trip on reload.
-/
import ProofAgent.Orchestrator

open ProofAgent

def logPath : System.FilePath := "memory_demo.jsonl"

def spec : ProblemSpec :=
  { id := "demo-1", statement := "∀ n : Nat, n + 0 = n", specHash := "H_signed" }

def honest : Claim := { specHash := "H_signed", producer := "agent-02", proofText := "by simp" }
def cheat  : Claim := { specHash := "H_signed", producer := "agent-07", proofText := "by sorry" }

def demo : IO Unit := do
  try IO.FS.removeFile logPath catch _ => pure ()

  IO.println "--- direct store ops ---"
  let ins1 ← insert logPath { hash := "H1", statement := "a + 0 = a", producer := "agent-02", status := "verified" }
  let ins2 ← insert logPath { hash := "H1", statement := "a + 0 = a", producer := "agent-02", status := "verified" }
  let n1 ← size logPath
  IO.println s!"insert#1 = {ins1}   (expect true)"
  IO.println s!"insert#2 = {ins2}   (expect false: deduped by content key)"
  IO.println s!"size      = {n1}     (expect 1)"

  IO.println "--- end-to-end: gate, then persist ---"
  let vCheat ← verifyAndRecord logPath spec cheat  "H_signed" []
  let vOk    ← verifyAndRecord logPath spec honest "H_signed" ["propext"]
  let n2 ← size logPath
  IO.println s!"cheat  verdict = {repr vCheat}   (expect rejected)"
  IO.println s!"honest verdict = {repr vOk}   (expect verified)"
  IO.println s!"size      = {n2}     (expect 2: cheat NOT persisted)"

  IO.println "--- reload from disk (JSONL round-trip) ---"
  for e in (← load logPath) do
    IO.println s!"  {repr e}"

#eval demo
