# Troubleshooting the ProofAgent Skeleton

*Symptom → cause → fix, for the errors you actually hit when building, running, or extending this repository.*

`[exists today]` — every row below is an error encountered while building this skeleton (or a direct consequence of its deliberate design choices). Fixes reference the real files.

## Symptom → cause → fix

| Symptom | Cause | Fix |
|---|---|---|
| PowerShell: `The term 'lake' is not recognized as the name of a cmdlet…` (same for `lean`) | elan is not installed, or its shims are not on this session's `PATH`. | Install **elan** (<https://leanprover-community.github.io/get_started.html>), or prepend its shims: `$env:PATH = "$env:USERPROFILE\.elan\bin;$env:PATH"`. |
| `unexpected token 'show'; expected identifier` | `show` is a **reserved keyword** in Lean, so it cannot be a definition/helper name. | Rename the helper — in this repo it became `showGoal` in [`tests/goals.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/goals.lean). |
| `by decide` will not close a fact about `String`s (or the elaborator stalls) | `String.splitOn` is `@[extern]` and does **not** reduce in the kernel, so `decide` cannot see through it. | Show gate verdicts with `#eval`; reserve `by decide` for pure `String`-equality facts like the axiom allow-list (`allowedAxioms.contains "propext" = true`). See [`tests/adversarial.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/adversarial.lean). |
| A "not a proposition" statement still elaborates (e.g. a bare unknown identifier) | Lean **auto-binds** unknown identifiers as implicit variables, so a bare name still forms a type. | Do not treat "it elaborated" as "it is a proposition": [`GoalState.goalState`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/GoalState.lean) sets `ok := true` only when the unsolved-goals report is the **only** error. The ill-typed test case is `List 1`. |
| Inline `if/else` inside a `do` block types as `Unit` | With no result-type hint the branches' type unifies to `Unit`. | Extract a function with an explicit return type — [`respond : IO (List (String × Json))`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean). |
| A recursive loop fails to type-check (termination error) | Lean requires `partial` for a non-terminating runtime loop. | Mark it `partial` — e.g. `partial def serve` in [`CheckServer.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean). |
| `lake build` tries to fetch/clone a dependency (or asks to update the manifest) | Something uncommented the Mathlib `[[require]]` block in [`lakefile.toml`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/lakefile.toml). | Keep it commented: the trusted core needs **no Mathlib**. Uncomment it only when the *pipeline* (not the gate) needs it, per `lakefile.toml`'s note and phase-9 §6 step 1. |
| The check tool returns a diagnostic beginning `toolchain error: …` | The tool spawns `lean` from `PATH`; the child process could not find the pinned `lean`. | Run tools under `lake env …` (or with elan's shims on `PATH`) so the pinned `lean` is on the child's `PATH`. See [`LeanCheck.checkSource`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/LeanCheck.lean). |
| A stray `leancheck_tmp.lean` in the working directory | `checkSource` writes a temp file and removes it, but an interrupted/crashed run can leave one behind. | Delete it; it is regenerated on the next check and is never read as state. |
| `axiom` used as a field/identifier name → error | `axiom` is a reserved keyword in Lean. | Rename the field. The skeleton's structures ([`Spec.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Spec.lean)) use no field named `axiom`. |
| Build error about an unknown module/prefix `ProofAgent` | The library root file is missing or incomplete. | Ensure [`ProofAgent.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent.lean) exists and imports the modules you use. |
| `declaration uses 'sorry'` appears (warning) and the check still says `ok=true` | This is **expected** and is the point of A1: a `sorry` proof *compiles*. | Do not "fix" it in the check tool. Compilation ≠ verification; the gate is what rejects `sorry`. See [`tests/leancheck.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/leancheck.lean). |

## Short notes

- **`compiled ≠ verified` (A1).** Two of the rows above — the `sorry` warning and the "not a proposition" elaboration — are not bugs to squash; they are the separation the design is built around. The compiler answers *"does it build?"*; only [`VerifierGate.gate`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean) answers *"is it verified?"*.
- **Reaching for `PATH` first.** Most "command not found" and "toolchain error" cases are a single root cause: the pinned Lean toolchain is not visible to the current shell or child process. `$env:PATH = "$env:USERPROFILE\.elan\bin;$env:PATH"` and `lake env …` cover nearly all of them.
- **When adding a new banned token or tool, expect the `if/else`-typing and `partial` rows.** They recur at exactly the two extension points; see [extend-the-gate.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/extend-the-gate.md) and [add-a-tool.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/add-a-tool.md).
- **When in doubt, re-run the suites.** `lake env lean tests/adversarial.lean` (and the other three) is the fastest way to tell whether a change broke policy or merely printed differently.

## See also

- [build-and-run.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/build-and-run.md) — the commands these symptoms interrupt.
- [extend-the-gate.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/extend-the-gate.md) — `by decide` vs. `#eval`, and safe policy changes.
- [add-a-tool.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/add-a-tool.md) — the `if/else`-typing and import pitfalls.
- [contributor-guide.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/contributor-guide.md) — conventions that avoid these errors.
- [Level T2 — Practitioner](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md) — the "Gotchas" table this one expands.
- [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md) — "Notes & deliberate choices".
