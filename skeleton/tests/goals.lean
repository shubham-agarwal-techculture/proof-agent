/-
  tests/goals.lean — the goal-state tool reads back the *initial* goal(s) of a statement.

  Run:  lake env lean tests/goals.lean

  It shows that goal extraction is independent of truth: a false-but-well-formed proposition still
  yields a goal (goal reading is not verification — the gate is what adjudicates truth).
-/
import ProofAgent.Tools.GoalState

open ProofAgent

/-- Collapse a multi-line goal block onto one line for compact printing. -/
def oneLine (s : String) : String :=
  String.intercalate " / " (s.splitOn "\n")

/-- Read and print the goal state of one statement. -/
def showGoal (label : String) (statement : String) : IO Unit := do
  let gs ← goalState statement
  IO.println s!"--- {label} ---"
  IO.println s!"  statement : {statement}"
  IO.println s!"  ok        = {gs.ok}"
  IO.println s!"  #goals    = {gs.goals.size}"
  for g in gs.goals do
    IO.println s!"  goal      : {oneLine g}"

def demo : IO Unit := do
  showGoal "simple goal"     "∀ n : Nat, n + 0 = n"
  showGoal "arithmetic"      "1 + 1 = 2"
  showGoal "false (still a goal)" "1 + 1 = 3"
  showGoal "ill-typed statement"  "List 1"

  IO.println "--- parseGoals on a multi-case payload (unit) ---"
  let raw := "unsolved goals\ncase left\n⊢ 1 = 1\n\ncase right\n⊢ 2 = 2"
  for g in parseGoals raw do
    IO.println s!"  block : {oneLine g}"

#eval demo
