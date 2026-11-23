/-
  ProofAgent/Tools/LeanCheck.lean — the Lean *check* tool (design §5.3, the compile oracle).

  This spawns the pinned `lean` binary on a candidate source, reads `lean --json` diagnostics, and
  returns a structured result: did it compile, and what did Lean say?  It is the "compile" half of
  the trusted boundary — the VerifierGate still separately rejects `sorry`/wrong statements/extra
  axioms, so a compiling proof is NOT yet a verified one (invariant A1).

  No external deps: this uses only Lean core (`Lean.Data.Json` + `IO.Process`).

  NOTE (scope): this tool reports *diagnostics* only.  Initial goal states are read by the companion
  tool `ProofAgent.Tools.GoalState` (same `lean --json` plumbing).  Stepping a proof forwards
  interactively still needs the REPL/LSP server (see phase-9 §6).
-/
import Lean.Data.Json

open Lean

namespace ProofAgent

/-- A single Lean diagnostic (message) as reported by `lean --json`. -/
structure Diagnostic where
  severity : String   -- "error" | "warning" | "information"
  line     : Nat
  column   : Nat
  message  : String
  deriving Repr, Inhabited

/-- Result of checking one source snippet. -/
structure CheckResult where
  /-- `true` iff Lean exited 0 AND reported no error-severity diagnostics. -/
  ok          : Bool
  diagnostics : Array Diagnostic
  deriving Repr, Inhabited

/-- Parse the line-delimited JSON diagnostic stream emitted by `lean --json`.  Malformed lines are
    skipped (tolerant), so a stray banner never breaks a check. -/
def parseDiagnostics (s : String) : Array Diagnostic :=
  ((s.splitOn "\n").filter (fun l => l ≠ "")).foldl (fun acc l =>
    match Json.parse l with
    | .error _ => acc
    | .ok j =>
      let sev := (j.getObjValAs? String "severity").toOption.getD "information"
      let msg := (j.getObjValAs? String "data").toOption.getD ""
      let pos := (j.getObjVal? "pos").toOption
      let line := pos.bind (fun p => (p.getObjValAs? Nat "line").toOption) |>.getD 0
      let col  := pos.bind (fun p => (p.getObjValAs? Nat "column").toOption) |>.getD 0
      acc.push { severity := sev, line := line, column := col, message := msg }) #[]

/-- Check a source string by compiling it with the pinned `lean`.  Writes a temp file, runs
    `lean --json <file>`, removes the temp file, and parses diagnostics. -/
def checkSource (source : String) : IO CheckResult := do
  let tmp : System.FilePath := "leancheck_tmp.lean"
  IO.FS.writeFile tmp source
  try
    let out ← IO.Process.output { cmd := "lean", args := #["--json", tmp.toString] }
    IO.FS.removeFile tmp
    let diags := parseDiagnostics out.stdout
    let errors := diags.filter (fun d => d.severity == "error")
    -- Fall back to stderr text if Lean failed but produced no JSON diagnostics.
    let diags :=
      if errors.isEmpty && out.exitCode != 0 && diags.isEmpty then
        diags.push { severity := "error", line := 0, column := 0, message := out.stderr }
      else diags
    let errors := diags.filter (fun d => d.severity == "error")
    return { ok := out.exitCode == 0 && errors.isEmpty, diagnostics := diags }
  catch e =>
    try IO.FS.removeFile tmp catch _ => pure ()
    return { ok := false,
             diagnostics := #[{ severity := "error", line := 0, column := 0,
                                message := s!"toolchain error: {e}" }] }

end ProofAgent
