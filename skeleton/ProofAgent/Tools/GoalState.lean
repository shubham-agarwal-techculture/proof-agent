/-
  ProofAgent/Tools/GoalState.lean — the Lean *goal-state* tool (design §5.3, "read the goals").

  Where `LeanCheck` answers "does this compile?", this answers "what must be proved?".  It probes a
  *statement* by wrapping it in a proof that makes no progress:

      example : <statement> := by
        skip

  Lean then reports the untouched goal(s) as a `Tactic.unsolvedGoals` diagnostic, and we parse that
  into structured goals.  This is genuine (if one-shot) goal introspection with **no extra
  dependency** — no `leanprover-community/repl`, no LSP session — so the trusted base stays Lean-core
  only (invariant #1).

  Scope / honesty: this reads the *initial* goal of a statement.  It does not step a proof forwards
  interactively (that needs the REPL/LSP); see phase-9 §6.  Multi-goal output is split on blank lines,
  which matches Lean's `case …` block format.
-/
import ProofAgent.Tools.LeanCheck

namespace ProofAgent

/-- The initial goal state of a statement, as read back from Lean. -/
structure GoalState where
  /-- `true` iff the statement elaborated cleanly (the *only* error being the unsolved-goals report)
      and at least one goal was read back. -/
  ok    : Bool
  /-- One pretty-printed goal block per element (hypotheses + `⊢` target, or a `case` block). -/
  goals : Array String
  /-- The raw `unsolved goals` payload from Lean, for fidelity. -/
  raw   : String
  deriving Repr, Inhabited

/-- Wrap a bare proposition (e.g. `∀ n : Nat, n + 0 = n`) as a no-progress proof so Lean reports its
    goal(s).  Keep the body on its own line so the `unsolved goals` position is well-defined. -/
def probeSource (statement : String) : String :=
  s!"example : {statement} := by\n  skip\n"

/-- Split a `Tactic.unsolvedGoals` payload into individual goals.  The payload looks like
    `"unsolved goals\na b : Nat\nh : a = b\n⊢ a + 0 = b"` (single goal) or
    `"unsolved goals\ncase left\n⊢ 1 = 1\n\ncase right\n⊢ 2 = 2"` (multi goal).  We drop the header
    line and split the remainder on blank lines. -/
def parseGoals (data : String) : Array String :=
  let lines := data.splitOn "\n"
  let body := match lines with
    | h :: t => if h == "unsolved goals" then t else lines
    | []     => []
  let joined := String.intercalate "\n" body
  ((joined.splitOn "\n\n").filter (fun b => b ≠ "")).toArray

/-- Read the initial goal state of a statement by compiling `probeSource statement` with the pinned
    `lean --json` and parsing the `unsolved goals` diagnostic.  `ok` is `true` only when the statement
    elaborated cleanly: the unsolved-goals report is the *only* error.  A statement that itself carries
    an error (e.g. an ill-typed subterm) still yields a degenerate goal, so we refuse to call that a
    clean goal read.  Returns `ok := false` with no goals when no goal was reported at all. -/
def goalState (statement : String) : IO GoalState := do
  let res ← checkSource (probeSource statement)
  let errors := res.diagnostics.filter (fun d => d.severity == "error")
  match res.diagnostics.find? (fun d => d.message.startsWith "unsolved goals") with
  | some d =>
      let clean := errors.size == 1 && errors.all (fun e => e.message.startsWith "unsolved goals")
      return { ok := clean, goals := parseGoals d.message, raw := d.message }
  | none => return { ok := false, goals := #[], raw := "" }

end ProofAgent
