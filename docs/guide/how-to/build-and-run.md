# How to Build and Run the ProofAgent Skeleton

*Get from a clean machine to "cheats rejected, honest accepted" in a couple of minutes, using the exact commands and outputs this repository actually produces.*

`[exists today]` — everything on this page is real. The skeleton builds and all four test suites pass on the pinned Lean `leanprover/lean4:v4.35.0`. The design docs describe the *full* system; this page is only about the working slice under [`skeleton/`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md).

The one rule to keep in mind the whole way through: **untrusted agents propose; the trusted kernel disposes.** Here the "trusted kernel" is [`VerifierGate.gate`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean), and the propose → verify → record loop lives in [`Orchestrator.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Orchestrator.lean).

## 1. Install elan (the Lean toolchain manager), once

Install **elan** from <https://leanprover-community.github.io/get_started.html>. elan reads the pinned version from [`lean-toolchain`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/lean-toolchain) (`leanprover/lean4:v4.35.0`) and downloads it on first use. You do **not** need Mathlib — the trusted core depends only on Lean core by design (see the commented `[[require]]` block in [`lakefile.toml`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/lakefile.toml)).

## 2. Open the skeleton folder

```powershell
# from the repository root
cd skeleton
```

Absolute equivalent:

```powershell
cd d:\projects-shubham\02.06.2026\personal_projects\proof-agent\skeleton
```

## 3. (Windows) make sure `lake` and `lean` are on `PATH`

If elan's shims are not on your `PATH` for this session, `lake` will not be recognised. Prepend them:

```powershell
$env:PATH = "$env:USERPROFILE\.elan\bin;$env:PATH"
```

## 4. Build the trusted core

```powershell
lake build
```

Expected (takes seconds — no Mathlib to fetch or compile):

```text
Build completed successfully (9 jobs)
```

## 5. Run the four test suites

Each suite is a standalone Lean file run through `lake env` (so it uses the pinned `lean`):

```powershell
lake env lean tests/adversarial.lean
lake env lean tests/memory.lean
lake env lean tests/leancheck.lean
lake env lean tests/goals.lean
```

**What each one proves, and what it prints.**

`tests/adversarial.lean` — the six cheat claims must be `rejected`, the honest claim `verified`, and only the honest one enters memory. Recorded output (exit code `0`):

```text
ProofAgent.Verdict.rejected (ProofAgent.RejectReason.sorryFound)
ProofAgent.Verdict.rejected (ProofAgent.RejectReason.nativeDecideFound)
ProofAgent.Verdict.rejected (ProofAgent.RejectReason.unsafeFound)
ProofAgent.Verdict.rejected (ProofAgent.RejectReason.kernelBypassOption)
ProofAgent.Verdict.rejected (ProofAgent.RejectReason.statementMismatch "H_signed" "H_differs")
ProofAgent.Verdict.rejected (ProofAgent.RejectReason.forbiddenAxiom "MyAxiom")
ProofAgent.Verdict.verified
ProofAgent.Verdict.rejected (ProofAgent.RejectReason.sorryFound)
[{ hash := "H_signed", statement := "∀ n : Nat, n + 0 = n", producer := "agent-02", status := "verified" }]
```

Read it as: F1 (kernel bypass) rejects `sorry`/`native_decide`/`unsafe`/kernel-bypass options; F2 (statement drift) rejects the hash mismatch; F3 (axiom inflation) rejects `MyAxiom`; the honest `by simp` with only `propext` is `verified`; and the end-to-end `step` shows the rejected claim leaves the store untouched while the honest one appends exactly one entry.

`tests/memory.lean` — store ops, dedup, and "gate then persist". Recorded output (exit code `0`):

```text
--- direct store ops ---
insert#1 = true   (expect true)
insert#2 = false   (expect false: deduped by content key)
size      = 1     (expect 1)
--- end-to-end: gate, then persist ---
cheat  verdict = ProofAgent.Verdict.rejected (ProofAgent.RejectReason.sorryFound)   (expect rejected)
honest verdict = ProofAgent.Verdict.verified   (expect verified)
size      = 2     (expect 2: cheat NOT persisted)
--- reload from disk (JSONL round-trip) ---
  { hash := "H1", statement := "a + 0 = a", producer := "agent-02", status := "verified" }
  { hash := "H_signed", statement := "∀ n : Nat, n + 0 = n", producer := "agent-02", status := "verified" }
```

`size = 2` (not 3) is the point: the cheat was **never** written. This is F7 (memory poisoning) prevented by construction.

`tests/leancheck.lean` — good / bad / unknown-tactic / `sorry` compile outcomes. Recorded output (exit code `0`):

```text
good    ok=true   (expect true)
bad     ok=false   (expect false)
sorry   ok=true   (expect true: compiles, warning only)
unknown ok=false   (expect false)
```

`sorry ok=true` is the **A1** lesson in one line: a `sorry` proof *compiles*. The compile tool accepts it; the gate is what rejects it. Compilation is not verification.

`tests/goals.lean` — initial goal read-back. Recorded output (exit code `0`):

```text
--- simple goal ---
  statement : ∀ n : Nat, n + 0 = n
  ok        = true
  #goals    = 1
  goal      : ⊢ ∀ (n : Nat), n + 0 = n
--- arithmetic ---
  statement : 1 + 1 = 2
  ok        = true
  #goals    = 1
  goal      : ⊢ 1 + 1 = 2
--- false (still a goal) ---
  statement : 1 + 1 = 3
  ok        = true
  #goals    = 1
  goal      : ⊢ 1 + 1 = 3
--- ill-typed statement ---
  statement : List 1
  ok        = false
  #goals    = 1
  goal      : ⊢ List sorry
```

Note the third case: the **false** statement `1 + 1 = 3` still reads back a goal (`ok = true`). Reading a goal is not establishing truth — the gate remains the only judge.

## 6. Exercise the JSON tool server

[`CheckServer.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean) reads one JSON request per line on stdin and writes one JSON response per line on stdout. Run it with `lake exe checkServer`:

```powershell
'{"id":"r1","op":"check","source":"theorem a : 1 + 1 = 2 := rfl"}' | lake exe checkServer
'{"id":"r2","op":"goals","statement":"1 + 1 = 2"}' | lake exe checkServer
```

Recorded output (one JSON object per line, keys alphabetically ordered by `Json.compress`):

```json
{"diagnostics":[],"id":"r1","ok":true}
{"goals":["⊢ 1 + 1 = 2"],"id":"r2","ok":true,"raw":"unsolved goals\n⊢ 1 + 1 = 2"}
```

The `op` field selects the tool (it defaults to `"check"` when absent). A malformed line is answered with a structured error, never a crash:

```powershell
'not json' | lake exe checkServer
```

```json
{"error":"bad request","ok":false}
```

An ill-typed statement is answered with `ok:false` but still reports the degenerate goal it produced:

```json
{"goals":["⊢ List sorry"],"id":"g2","ok":false,"raw":"unsolved goals\n⊢ List sorry"}
```

## 7. Read the persisted memory

`tests/memory.lean` writes an append-only JSONL log named `memory_demo.jsonl` in the current directory (it deletes any previous copy at the start of the run). After a run it holds exactly the two verified entries — the direct insert and the honest proof — and **no** line for the rejected cheat:

```json
{"hash":"H1","producer":"agent-02","statement":"a + 0 = a","status":"verified"}
{"hash":"H_signed","producer":"agent-02","statement":"∀ n : Nat, n + 0 = n","status":"verified"}
```

Every line carries provenance (`producer`) and a `status`. Entries are never mutated; [`Memory.insert`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean) only ever appends, and a second identical insert is a no-op (dedup by content key).

## Verify it worked

Tick every box; each one is an observable signal from the commands above.

- [ ] `lake build` prints `Build completed successfully (9 jobs)`.
- [ ] `tests/adversarial.lean` prints **six** `rejected` lines, then `verified`, then one `verified` `MemEntry`, and exits `0`.
- [ ] `tests/memory.lean` prints `insert#2 = false`, `size = 2` after the end-to-end block, and two lines on reload.
- [ ] `tests/leancheck.lean` prints `sorry ok=true` (compiles) and `bad ok=false` (does not).
- [ ] `tests/goals.lean` prints `ok = true` for the **false** statement `1 + 1 = 3` and `ok = false` for `List 1`.
- [ ] `lake exe checkServer` answers the `r1` request with `"ok":true` and the `r2` request with `"goals":["⊢ 1 + 1 = 2"]`.
- [ ] A malformed server request yields `{"error":"bad request","ok":false}`.
- [ ] `memory_demo.jsonl` exists with exactly two `"status":"verified"` lines and no `sorry` line.

If every box is ticked, the trusted boundary is doing its job on your machine: proposals are checked, cheats are refused, and only verified results are recorded.

## Gotchas

- **PowerShell quoting.** Wrap JSON request lines in **single** quotes (`'{"id":"r1",...}'`). Double quotes let PowerShell mangle the inner quotes and the server answers `{"error":"bad request","ok":false}`.
- **Run tools under `lake env`.** The check tool spawns `lean` from `PATH`. `lake env lean …` (and `lake env` around anything that calls the tool) guarantees the pinned `lean` is found; without it you get a `toolchain error` diagnostic. See [troubleshooting.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/troubleshooting.md).
- **The server loops until EOF.** Piping a single line closes stdin, so the process exits after one response. To send several requests, pipe a multi-line stream (e.g. from a file) rather than one line at a time expecting a persistent session.
- **`memory_demo.jsonl` is regenerated each run** and lives in whatever directory you ran the test from; run from `skeleton/` to match the recorded paths.
- **A passing `lake build` is not a `verified` theorem.** "Verified" means the gate said `.verified` — and in the full system it would additionally mean an *independent* re-check (design A1). See [extend-the-gate.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/extend-the-gate.md).

## See also

- [extend-the-gate.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/extend-the-gate.md) — change the trusted policy safely.
- [add-a-tool.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/add-a-tool.md) — add a new op to the tool server.
- [troubleshooting.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/troubleshooting.md) — symptom → cause → fix table.
- [contributor-guide.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/contributor-guide.md) — repo layout and contribution rules.
- [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md) — the authoritative recorded outputs.
- [Level T2 — Practitioner](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md) — the module-by-module walkthrough.
- [phase-9-walking-skeleton.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-9-walking-skeleton.md) — what was built vs. designed.
