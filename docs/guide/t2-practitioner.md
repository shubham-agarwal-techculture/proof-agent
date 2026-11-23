# Level T2 — Practitioner (Build, Run, Extend)

*Assumes you can read code and have met Lean at least once. This tier is **hands-on**: we walk the
actual files in [`skeleton/`](../../skeleton), then show the build/run/verify loop and how to extend
the trusted core safely. File references are clickable.*

> **Status:** the skeleton **builds and all four test suites pass** on Lean `leanprover/lean4:v4.35.0`.
> Everything below is real code in this repository, not aspirational.

---

## 1. Prerequisites and the 60-second build

The project needs only the Lean toolchain manager (**elan**) and the pinned Lean version in
[lean-toolchain](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/lean-toolchain)
(`leanprover/lean4:v4.35.0`). There is **no Mathlib dependency by design** — see the commented
`[[require]]` block in
[lakefile.toml](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/lakefile.toml#L9-L12) —
so the trusted core stays small and the build takes seconds.

```powershell
# once: install elan from https://leanprover-community.github.io/get_started.html
cd skeleton
lake build                                     # builds the trusted core (seconds)
lake env lean tests/adversarial.lean           # cheats rejected + honest accepted
lake env lean tests/memory.lean                # store ops, dedup, gate→persist
lake env lean tests/leancheck.lean             # good/bad/unknown/sorry compile outcomes
lake env lean tests/goals.lean                 # initial goal read-back
```

If `lean`/`lake` are not on your `PATH`, prepend elan's shim directory for the session (Windows
PowerShell):

```powershell
$env:PATH = "$env:USERPROFILE\.elan\bin;$env:PATH"
```

Expected outcome: `lake build` prints `Build completed successfully (9 jobs)`, and each test suite
exits `0`. Recorded outputs are in the [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md#L82-L175)
and Phase 9 (§7, §7b, §7c, §7d).

---

## 2. Module map

```
skeleton/
├─ lean-toolchain              # pins Lean 4.35.0
├─ lakefile.toml               # [[lean_lib]] ProofAgent ; [[lean_exe]] checkServer
├─ ProofAgent.lean             # library root — imports the modules below
├─ ProofAgent/
│  ├─ Spec.lean                # ProblemSpec, Claim            (untrusted artifacts)
│  ├─ VerifierGate.lean        # the trusted gate              (TRUSTED)
│  ├─ Memory.lean              # append-only JSONL store       (storage)
│  ├─ Orchestrator.lean        # propose→verify→record         (runtime)
│  └─ Tools/
│     ├─ LeanCheck.lean        # `lean --json` → diagnostics    (tool)
│     ├─ GoalState.lean        # `by skip` probe → goals        (tool)
│     └─ CheckServer.lean      # stdin/stdout JSON server       (tool exe)
└─ tests/
   ├─ adversarial.lean  · memory.lean  · leancheck.lean  · goals.lean
```

Trust hierarchy: only `VerifierGate.lean` is *trusted*. `Spec`/`Memory`/`Orchestrator`/`Tools` are
ordinary code that *surrounds* it.

---

## 3. `Spec.lean` — the two artifacts on either side of the boundary

[Spec.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Spec.lean)
defines exactly two structures:

- `ProblemSpec` — the **signed statement**: `id`, a human-readable `statement`, a `specHash` (the hash
  of the *elaborated* goal type — the reference the gate trusts), plus `safetyCritical : Bool := false`
  and `domain : String := "mathematics"`.
- `Claim` — an **untrusted proposal**: `specHash` (what the agent *claims* it proved), `producer`
  (provenance), `proofText` (the Lean source), and `derivesFrom : List String := []` (the memory
  artifacts it relies on — used for poisoning analysis).

Notice the design intent baked into the defaults: `statement` is explicitly *"never used for trust
decisions"*, and `Claim` is *"assumed hostile."* The types themselves remind you which side you're on.

---

## 4. `VerifierGate.lean` — the trusted core (read this file twice)

[VerifierGate.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean)
is the whole trusted policy. It is deliberately tiny and *total*.

**4.1 The cheat surface is data.** `RejectReason` enumerates every way a proposal can be refused:

| Constructor | Meaning |
|---|---|
| `sorryFound` | contains `sorry` |
| `nativeDecideFound` | uses `native_decide` (evaluates outside the kernel) |
| `unsafeFound` / `implementedByFound` | `unsafe` / `implemented_by` escapes |
| `partialFound` | `partial` definition |
| `kernelBypassOption` | e.g. `debug.skipKernelTC` |
| `statementMismatch (signed claimed)` | proved statement ≠ signed statement |
| `forbiddenAxiom (axiomName)` | a `#print axioms` entry outside the allow-list |

**4.2 The allow-list and banned list are data too.**
[`allowedAxioms`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean#L31-L32)
is `["propext", "Classical.choice", "Quot.sound"]`; the banned constructs live in
[`bannedTokens`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean#L35-L41).
Because they are plain data, the audited surface can be read, diffed, and extended with sign-off.

**4.3 The gate itself.** [`gate`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean#L61-L71)
is a 10-line match that implements the policy in a fixed order:

```
scanBanned proofText          →  some r  ⇒ rejected r          (F1)
provedHash ≠ spec.specHash    →            rejected statementMismatch (F2)
axiomsUsed contains a bad one →            rejected forbiddenAxiom     (F3)
otherwise                                  verified
```

Two subtleties the comments call out, and that you should internalize:

- **String scan vs. elaborated `Expr`.** The skeleton scans `proofText` with a substring test
  ([`hasToken`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean#L44))
  as a *stand-in* for the real design's inspection of the **elaborated expression** plus `#print
  axioms` plus an **independent re-check**. Source text can be defeated by tricks (comments, macro
  expansion, computed names); the elaborated form cannot be fooled that way.
- **Statement matching is by content hash, never by string.** `provedHash` is the hash of what the
  kernel *actually accepted*; comparing it to `spec.specHash` is what stops statement drift.

> **Why `hasToken` uses `splitOn`:** a reminder of a real Lean gotcha — `String.splitOn` returns a
> list of pieces, so "contains" is `(src.splitOn tok).length > 1`. (The more obvious `contains`
> substring helper isn't a stable core API here.)

---

## 5. `Memory.lean` — append-only, content-addressed, deduped

[Memory.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean)
is the store. Key pieces:

- `MemEntry { hash, statement, producer, status }` — `status` is `"verified"` or `"candidate"`
  (quarantined). This is invariant #3 (provenance) in four fields.
- [`contentHash`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean#L31-L37)
  — FNV-1a over the string. **Non-cryptographic on purpose** (skeleton only); production uses SHA-256
  over canonical artifact bytes. The comment says so explicitly.
- [`MemEntry.key`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean#L40-L41)
  — the content address used for dedup.
- [`toJson`/`ofJson?`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean#L44-L54)
  — canonical JSONL encoding/decoding; `ofJson?` fails on any missing/ill-typed field.
- [`appendLine`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean#L57-L59)
  / [`load`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean#L63-L72)
  — open in append mode; skip blank lines; **drop malformed lines** (a real store would quarantine them).
- [`insert`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean#L76-L82)
  — dedup by key: if an entry with the same content key exists, return `false` and **do not append**;
  otherwise append and return `true`. This is the **Phase-5 dedup lever** and the **append-only**
  discipline (entries are never mutated) in two lines.

The JSONL format on disk is one object per line:

```json
{"hash":"H_signed","producer":"agent-02","statement":"∀ n : Nat, n + 0 = n","status":"verified"}
```

---

## 6. `Orchestrator.lean` — propose → verify → record

[Orchestrator.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Orchestrator.lean)
holds the *runtime* (control flow is **not** trusted — only the gate's policy is):

- [`step`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Orchestrator.lean#L19-L27)
  — the pure version: on `.verified`, append a `verified` `MemEntry`; on any rejection, return the
  rejection and leave `store` unchanged.
- [`verifyAndRecord`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Orchestrator.lean#L31-L40)
  — the IO version: run the gate, and **only** on `.verified` call `insert` on the JSONL path. Returns
  the `Verdict` either way.

This is where failure mode **F7 (memory poisoning)** is structurally prevented: there is simply no code
path from a rejection to verified memory.

---

## 7. `Tools/` — the tool layer (design §5.3)

Three tools, all built on the same zero-dependency `lean --json` plumbing.

**7.1 [`LeanCheck.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/LeanCheck.lean) — the compile oracle.**
`checkSource` writes a temp file, runs `IO.Process.output { cmd := "lean", args := #["--json", tmp] }`,
parses the line-delimited JSON diagnostics, and returns `CheckResult { ok, diagnostics }`. `ok` is
`true` **iff** Lean exited 0 **and** reported no error-severity diagnostics. `parseDiagnostics` is
tolerant (malformed lines are skipped). There's a stderr fallback if Lean fails without emitting JSON.
Crucially, this tool reports **compilation, not verification** — a `sorry` proof compiles here and is
rejected by the gate later (the **A1** division of labour).

**7.2 [`GoalState.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/GoalState.lean) — read the goals.**
Where `LeanCheck` answers *"does it compile?"*, this answers *"what must be proved?"*. It probes a
statement by wrapping it in a no-progress proof ([`probeSource`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/GoalState.lean#L36-L37)):

```lean
example : <statement> := by
  skip
```

Lean then emits a `Tactic.unsolvedGoals` diagnostic carrying the untouched goal(s);
[`parseGoals`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/GoalState.lean#L43-L49)
drops the `unsolved goals` header and splits the remainder on blank lines (which matches Lean's
`case …` block format). `goalState` sets `ok := true` **only** when the unsolved-goals report is the
*only* error — see the note below on why that strictness is needed.

**7.3 [`CheckServer.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean) — the long-lived tool server.**
A line-oriented JSON request/response loop (`lake exe checkServer`), the **MCP-tool shape in
miniature**: one process, many requests. `op` selects the tool (default `"check"`); `respond`
dispatches; `partial serve` reads a line, parses, answers, and recurses until EOF.

**Protocol:**

```
{"id":"r1","op":"check","source":"theorem a : 1 + 1 = 2 := rfl"}
  → {"id":"r1","ok":true,"diagnostics":[]}

{"id":"r2","op":"goals","statement":"1 + 1 = 2"}
  → {"id":"r2","ok":true,"goals":["⊢ 1 + 1 = 2"],"raw":"unsolved goals\n⊢ 1 + 1 = 2"}

garbage
  → {"ok":false,"error":"bad request"}
```

The `id` is echoed for request/response correlation (absent `id` ⇒ omitted); malformed JSON is
answered with a structured error, never a crash.

---

## 8. The test suites (this is the executable proof the policy works)

| Suite | What it pins down |
|---|---|
| [adversarial.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/adversarial.lean) | The honest form of F1/F2/F3: six cheat claims `#eval` to `rejected`; one honest claim is `verified`; `step` shows only the honest one enters memory. Ends with machine-checked `by decide` examples on the axiom allow-list. |
| [memory.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/memory.lean) | Direct insert/dedup/size, gate→persist end-to-end (a cheat is **not** persisted), and a JSONL round-trip from disk. |
| [leancheck.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/leancheck.lean) | good / bad / unknown-tactic / `sorry` compile outcomes — demonstrating **A1**: `sorry` compiles (`ok=true`, warning only). |
| [goals.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/goals.lean) | Initial goal read-back, including a **false** statement (still a goal — goal-reading ≠ truth) and an **ill-typed** statement (`List 1` ⇒ `ok=false`). |

Read `adversarial.lean` first: it is the design's red-team modes F1/F2/F3 turned into executable tests.

---

## 9. Extending the trusted core (do this carefully)

The gate is *policy as data*, so extensions are small and reviewable. Two safe extensions:

**(a) Ban another construct.** Add a pair to [`bannedTokens`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean#L35-L41) and a matching `RejectReason` constructor. Then add an `#eval` in `adversarial.lean` proving it's rejected.

**(b) Change the axiom allow-list.** Edit [`allowedAxioms`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean#L31-L32) — but note the design's rule: any addition is a **policy exception that must be signed and logged, never silent.** Adding an axiom weakens F3; treat it as a security change.

**(c) Add a tool op.** Add a branch to [`respond`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean#L24-L40) keyed on `op`, and a small tool module under `Tools/` reusing `checkSource` if it needs the compiler.

---

## 10. Gotchas (learned by building this — save yourself the time)

These are real errors encountered while writing the skeleton; each shaped the final code:

| Symptom | Cause | Fix in this repo |
|---|---|---|
| `unexpected token 'show'; expected identifier` | `show` is a **reserved keyword** in Lean. | Helper renamed to `showGoal` in `tests/goals.lean`. |
| `by decide` can't close a `String`-based fact | `String.splitOn` is `@[extern]` and does **not** reduce in the kernel. | Gate verdicts are shown with `#eval`; only the pure `String`-equality allow-list is `by decide`-provable. |
| A "not a proposition" statement still elaborated | Unknown identifiers **auto-bind** as implicit variables in Lean, so a bare unknown name still forms a type. | `GoalState.ok` requires the unsolved-goals report be the *only* error; the ill-typed test case is `List 1`. |
| Inline `if/else` in a `do` block typed as `Unit` | The branches' result type unified to `Unit` without a hint. | Extracted `respond (j : Json) : IO (List (String × Json))` with an explicit return type. |
| Recursive server loop wouldn't type-check | Lean wants `partial` for a non-terminating runtime loop. | `partial serve`. |

---

## 11. What this skeleton deliberately does *not* do

Straight from the code's own notes — do not mistake the skeleton for the system:

- **Statement matching is textual-hash, not elaborated-`Expr`.** The real gate inspects the elaborated
  term and runs `#print axioms`.
- **No independent re-checker.** "verified" here means "gate said yes," not "a second kernel agreed."
- **Goal reading is one-shot, not interactive.** `GoalState` reads the *initial* goal; stepping a proof
  tactic-by-tactic needs the REPL/LSP session (Phase 9 §6).
- **FNV-1a, not SHA-256**, and **no retrieval / no agents / no Mathlib**.

To turn the skeleton into the system, follow Phase 9 §6; the [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md#L202-L207)
"Scope & honesty" section states the same.

---

## 12. Where to go next

- **The full design argument →** [Level T3 — Expert](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md).
- **The design record for this code →** [phase-9-walking-skeleton.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-9-walking-skeleton.md) and the [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md).
- **Any term →** [Glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
