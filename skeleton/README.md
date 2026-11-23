# ProofAgent — Phase 9 Walking Skeleton

A minimal, runnable Lean 4 project that demonstrates the design's **trusted core**: a verifier gate
that rejects cheating proofs and admits only honest, on-statement, allow-listed-axiom results, wrapped
in a propose → verify → record loop with content-addressed memory.

> **Build status: NOT VERIFIED IN THE AUTHORING ENVIRONMENT.**
> The design was authored on a machine **without** a Lean toolchain installed (`elan`/`lake`/`lean`
> were not found; see `../docs/phase-9-walking-skeleton.md`). The code below is authored to be correct
> in intent but has **not** been compiled. Treat every version pin (`v4.35.0`) as **unverified**.

## Layout

```
skeleton/
├─ lean-toolchain              # pinned Lean version (UNVERIFIED)
├─ lakefile.toml               # depends on Mathlib (UNVERIFIED rev)
├─ ProofAgent/
│  ├─ Spec.lean                # ProblemSpec, Claim  (untrusted artifacts)
│  ├─ VerifierGate.lean        # the trusted gate: banned tokens, statement match, axiom audit
│  └─ Orchestrator.lean        # propose → verify → record; verified-only memory
└─ tests/
   └─ adversarial.lean         # cheat proofs that MUST be rejected + one honest proof that passes
```

## What it demonstrates

| Concept (design ref) | In this skeleton |
|---|---|
| Invariant #1 (trusted core) | `VerifierGate.gate` is total & deterministic; agents only *propose* |
| F1 kernel bypass | rejects `sorry`, `native_decide`, `unsafe`, `implemented_by`, `partial`, `skipKernelTC` |
| F2 statement drift | `statementMismatch` when `provedHash ≠ spec.specHash` |
| F3 axiom inflation | `forbiddenAxiom` outside `{propext, Classical.choice, Quot.sound}` |
| A1 compiled ≠ verified | only `gate = .verified` writes a `verified` memory entry |
| F7 memory poisoning | rejections never enter verified memory (`Orchestrator.step`) |
| Invariant #3 provenance | `MemEntry` carries hash, producer, status |

## How to run (once a toolchain is available)

```powershell
# from skeleton/
elan toolchain install leanprover/lean4:v4.35.0   # pin from lean-toolchain
lake exe cache get                                # fetch Mathlib oleans
lake build                                        # build the ProofAgent library
lake env lean tests/adversarial.lean              # run the adversarial cases
```

Expected output of `tests/adversarial.lean`: six `rejected (...)` verdicts, then `verified`, then a
memory store containing exactly one `verified` entry.

## Scope & honesty

- This is a **skeleton**, not the system. The syntactic scan here stands in for the real design's
  elaborated-`Expr` inspection + `#print axioms` + **independent re-check** (nanoda/con-leche/
  lean4lean-class), which is what actually makes a result `verified` (Phase 1 A1).
- The `lakefile.toml` and `lean-toolchain` pins are **illustrative**; align them with your installed
  toolchain before building.
- If `by decide` cannot kernel-reduce a `String` primitive in your Lean version, rely on the `#eval`
  lines (same expected verdicts).
