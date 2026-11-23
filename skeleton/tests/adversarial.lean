/-
  tests/adversarial.lean — cheat proofs that MUST be rejected, plus one honest proof that MUST pass.

  Run:  lake env lean tests/adversarial.lean
  Each `#eval` prints a verdict.  Expected outputs are given in comments.  This is the executable
  form of Phase 7 modes F1 (kernel bypass), F2 (statement drift), F3 (axiom inflation).
-/
import ProofAgent.Orchestrator

open ProofAgent

/-- The "human-signed" spec.  Its hash is the reference the gate compares against. -/
def spec : ProblemSpec :=
  { id := "demo.add_zero", statement := "∀ n : Nat, n + 0 = n", specHash := "H_signed" }

/- ------------------------------- MUST BE REJECTED ------------------------------- -/

/-- F1 — `sorry`: the classic cheat. -/
def cSorry : Claim :=
  { specHash := "H_signed", producer := "agent-01", proofText := "theorem t : ∀ n, n + 0 = n := by sorry" }

/-- F1 — `native_decide`: evaluates outside the kernel; not a proof term. -/
def cNative : Claim :=
  { specHash := "H_signed", producer := "agent-01", proofText := "by native_decide" }

/-- F1 — `unsafe` / `implemented_by`: escapes the logic. -/
def cUnsafe : Claim :=
  { specHash := "H_signed", producer := "agent-01", proofText := "unsafe def cheat := ... implemented_by ..." }

/-- F1 — kernel-bypass option. -/
def cSkip : Claim :=
  { specHash := "H_signed", producer := "agent-01", proofText := "set_option debug.skipKernelTC true in by rfl" }

/-- F2 — statement drift: a valid proof of a *different* statement (here: weaker goal). -/
def cWrong : Claim :=
  { specHash := "H_signed", producer := "agent-01", proofText := "by rfl" }

/-- F3 — axiom inflation: the proof rests on an axiom outside the allow-list. -/
def cAxiom : Claim :=
  { specHash := "H_signed", producer := "agent-01", proofText := "by exact myHandWavedLemma" }

/- ------------------------------- MUST BE ACCEPTED ------------------------------- -/

/-- Honest proposal: correct statement, only allow-listed axioms. -/
def cOk : Claim :=
  { specHash := "H_signed", producer := "agent-02", proofText := "by simp" }

/- `#eval`s.  Expected: rejected x6, then verified.  (See comments per line.) -/
#eval gate spec cSorry  "H_signed" []                     -- rejected (sorryFound)
#eval gate spec cNative "H_signed" []                     -- rejected (nativeDecideFound)
#eval gate spec cUnsafe "H_signed" []                     -- rejected (unsafeFound)
#eval gate spec cSkip   "H_signed" []                     -- rejected (kernelBypassOption)
#eval gate spec cWrong  "H_differs" []                    -- rejected (statementMismatch ...)
#eval gate spec cAxiom  "H_signed" ["propext", "MyAxiom"] -- rejected (forbiddenAxiom "MyAxiom")
#eval gate spec cOk     "H_signed" ["propext"]            -- verified

/- End-to-end: only the honest proposal may enter *verified* memory. -/
def store : Store := []
#eval (step store spec cSorry "H_signed" []).2            -- rejected; store unchanged
#eval (step store spec cOk    "H_signed" ["propext"]).1   -- one `verified` MemEntry

/-
  Machine-checked assertions.

  NOTE on scope: the full `gate` verdicts above are shown with `#eval` rather than `by decide`
  because the textual scan uses `String.splitOn`, which is `@[extern]` and does not reduce in the
  kernel.  The real gate (design §6 step 2) inspects the *elaborated* `Expr` — kernel-reducible —
  instead of source text; that upgrade is what makes `decide`-level proofs of the gate possible.
  The axiom allow-list logic below IS pure `String` equality and therefore kernel-reduces. -/
example : allowedAxioms.contains "propext" = true := by decide
example : allowedAxioms.contains "Quot.sound" = true := by decide
example : allowedAxioms.contains "RiemannHypothesis" = false := by decide
