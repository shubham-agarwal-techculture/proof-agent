# Contributor Guide

*Where the code lives, which file you are allowed to trust, how to add a test, and the discipline that keeps a "verified" claim honest.*

`[exists today]` — the skeleton builds and all four test suites pass on Lean `leanprover/lean4:v4.35.0`. The full system (agents, independent re-checker, interactive stepping) is **design only**, described in the `docs/phase-*.md` record.

## 1. Read these first

Before changing anything, read — in this order:

1. [phase-1-framing.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-1-framing.md) — assumptions **A1** ("verified" = exported-and-re-checked) and **A2** (the axiom allow-list).
2. [phase-7-red-team.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md) — failure modes **F1–F19**; the skeleton is the executable form of F1/F2/F3/F7.
3. [phase-9-walking-skeleton.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-9-walking-skeleton.md) — exactly what was built vs. designed, and §6 (the "make it real" list).
4. [Level T2 — Practitioner](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md) — the module-by-module walkthrough.

## 2. Repo layout

```
proof-agent/
├─ skeleton/
│  ├─ lean-toolchain              # pins leanprover/lean4:v4.35.0
│  ├─ lakefile.toml               # [[lean_lib]] ProofAgent ; [[lean_exe]] checkServer ; NO deps by design
│  ├─ ProofAgent.lean             # library root — imports the modules
│  ├─ ProofAgent/
│  │  ├─ Spec.lean                # ProblemSpec, Claim            (untrusted input artifacts)
│  │  ├─ VerifierGate.lean        # the trusted gate              (TRUSTED — keep it tiny)
│  │  ├─ Memory.lean              # append-only JSONL store       (untrusted periphery)
│  │  ├─ Orchestrator.lean        # propose → verify → record     (untrusted runtime)
│  │  └─ Tools/
│  │     ├─ LeanCheck.lean        # `lean --json` → diagnostics   (tool)
│  │     ├─ GoalState.lean        # `by skip` probe → goals       (tool)
│  │     └─ CheckServer.lean      # stdin/stdout JSON server      (tool exe)
│  └─ tests/
│     ├─ adversarial.lean         # F1/F2/F3 cheats rejected + honest accepted
│     ├─ memory.lean              # store ops, dedup, gate→persist
│     ├─ leancheck.lean           # good/bad/unknown/sorry compile outcomes
│     └─ goals.lean               # initial goal read-back
└─ docs/                          # the design record (phase-0…9) and the reader's guide
```

## 3. The trust rule — only one file is trusted

**Only [`VerifierGate.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean) is trusted.** Everything else — `Spec`, `Memory`, `Orchestrator`, `Tools` — is ordinary code that *surrounds* the gate. The rule the whole project rests on:

> **Untrusted agents propose; the trusted kernel disposes.**

Consequences for the gate (invariant #1):

- **Keep it small.** It fits in a screen; every added line enlarges the trusted base and must earn its place.
- **Keep it total.** For every input it must return a `Verdict` — no exceptions, no partial functions, no `Option` the caller can mishandle.
- **Keep it deterministic.** The same inputs must always produce the same verdict; no clocks, no I/O, no runtime configuration.
- **Keep it data-driven.** The cheat surface lives in `bannedTokens` and `allowedAxioms` as plain data, so the audited surface is readable and diffable.

Changes to the gate are **security changes**: go through [extend-the-gate.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/extend-the-gate.md), and add an executable test.

## 4. Coding conventions

- **Lean core only, in the trusted core.** No Mathlib, no third-party packages in `VerifierGate.lean`. Keep the `[[require]]` block in [`lakefile.toml`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/lakefile.toml) commented; add Mathlib only where the *pipeline* needs it. This keeps the build in seconds and the trusted base auditable.
- **Namespace everything under `ProofAgent`;** tools live in `ProofAgent/Tools/`.
- **Derive what you print.** Types that the tests `#eval` derive `Repr` (and `Inhabited`; add `DecidableEq` where equality matters, as `RejectReason` does).
- **One clear function per tool.** Mirror `GoalState`: a small module that reuses `checkSource` and returns a structured result — no hidden global state.
- **Header comment states scope and honesty.** Every source file opens with a comment saying what it does *and what it deliberately does not do* (see the headers in `GoalState.lean` and `LeanCheck.lean`).
- **Policy as data, not branches.** Prefer extending a list to adding an `if` — especially in the gate.

## 5. Add a test suite

The suites are standalone Lean files under `skeleton/tests/`, each run with `lake env lean`. There is **no test-runner registration** — adding a suite means adding the file and running it.

```lean
/-
  tests/my_additions.lean — what this pins down and why.
  Run:  lake env lean tests/my_additions.lean
-/
import ProofAgent.Orchestrator      -- or whichever module you exercise

open ProofAgent

def demo : IO Unit := do
  -- print observables with the expected value in the message
  IO.println s!"gate = {repr (gate spec claim "H_signed" [])}   (expect verified)"

#eval demo
```

For policy facts, add **machine-checked** examples rather than prints, where the kernel can reduce them:

```lean
example : allowedAxioms.contains "propext" = true := by decide
```

Run everything:

```powershell
cd skeleton
lake build
lake env lean tests/my_additions.lean
lake env lean tests/adversarial.lean
lake env lean tests/memory.lean
lake env lean tests/leancheck.lean
lake env lean tests/goals.lean
```

## 6. The "compiled ≠ verified" discipline (A1)

Internalize A1 before you touch anything: **a successful compile is `compiled`, not `verified`.**

- A `sorry` proof *compiles* — with only a warning ([`LeanCheck.checkSource`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/LeanCheck.lean) reports `ok=true`). The **gate** is what rejects it.
- In the full system, `verified` additionally means an **independent** kernel re-checked the exported proof (design A1). The skeleton's `verified` means "the gate said yes" — no more.
- Never let a compile result be reported as verification. That gap is deliberate and load-bearing.

## 7. What NOT to do

- **Never let a rejection reach verified memory.** In [`Orchestrator.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Orchestrator.lean), only `gate = .verified` appends a `verified` entry — rejections leave the store unchanged (F7). Do not add a code path around this.
- **Never add an axiom silently.** The allow-list `{propext, Classical.choice, Quot.sound}` is the F3 boundary; any exception is a **signed, logged policy event, never silent** (A2; phase-9 §6 step 3).
- **Never make the gate partial, non-deterministic, or dependent on I/O/config.**
- **Never add Mathlib (or any dependency) to the trusted core.**
- **Never mutate a memory entry.** The store is **append-only**; [`Memory.insert`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean) appends or dedups, and never rewrites a line.
- **Never treat a tool's output as a verdict.** Tools answer "what did Lean say?"; only the gate disposes.
- **Never let tests silently pass.** A test that asserts nothing, or asserts via a print nobody checks, is untested policy.

## 8. Honesty rule for docs and comments

State **built vs. designed**, always:

- The skeleton is **real and tested**; the full system (agents, independent re-checker, interactive goal stepping, retrieval, Mathlib pipeline) is **design only**.
- Use the status tags `[exists today]` / `[near-term]` / `[frontier]` / `[speculative]` when a claim's maturity matters (see the [guide README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/README.md)).
- **No invented facts.** Reproduce numbers from the design docs with their "back-of-envelope" caveat attached; do not present ranges as measurements.
- Say what is **not** true yet. Do not let a passing build read as a `verified` theorem.

## Verify it worked

Before you consider a change done:

- [ ] `lake build` succeeds (`Build completed successfully (9 jobs)`).
- [ ] All four suites exit `0` with their expected lines — run each with `lake env lean tests/<name>.lean`.
- [ ] If you touched the gate, the adversarial suite still shows six cheats rejected and exactly one `verified`.
- [ ] If you touched memory/orchestrator, `tests/memory.lean` still shows `size = 2` (cheat not persisted) and rejections unchanged.
- [ ] Your change kept the trusted core small, total, deterministic, and dependency-free.
- [ ] Any new policy fact has a test (`#eval` for verdicts, `by decide` for pure `String`-equality facts).
- [ ] Docs/comments describe what is **built**, and label what is only **designed**.

## Pitfalls

- **Editing the gate to make a test pass.** Fix the test or the policy, never the invariant; if a cheat now passes, that is a blocking failure, not a passing test.
- **Assuming `lake env` is optional.** Tools spawn `lean` from `PATH`; without `lake env` you get a `toolchain error`. See [troubleshooting.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/troubleshooting.md).
- **Adding a dependency "just for the test".** Tests must run under the same zero-dependency posture; a dependency sneaks into the trusted base's supply chain.
- **Writing docs that overclaim.** "verified the system" is wrong if you only built the skeleton; use the status tags.

## See also

- [build-and-run.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/build-and-run.md) — the build/run/test loop.
- [extend-the-gate.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/extend-the-gate.md) — the review procedure for trusted-core changes.
- [add-a-tool.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/add-a-tool.md) — extending the untrusted tool layer.
- [troubleshooting.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/troubleshooting.md) — symptom → cause → fix.
- [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md) — how to run + "Scope & honesty".
- [docs/README.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/README.md) — the design-set index.
- [glossary.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md) — terms used here and across the guide.
