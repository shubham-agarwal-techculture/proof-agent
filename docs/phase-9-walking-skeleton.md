# Phase 9 — Walking Skeleton

> Design-team phase 9 of the Master Prompt brief (optional, "if you can execute code"). This file
> describes the prototype under [`/skeleton`](../skeleton) and states **exactly what was built,
> compiled and run vs. what is design-only**. Status tags:
> `[exists today]` / `[near-term]` / `[frontier]` / `[speculative]`.

## 1. What the brief asked for

A pinned Lean + Mathlib project, an orchestrator, a Lean REPL tool, a memory store, one prover loop,
and a **verifier gate with axiom audit and statement matching**, plus **adversarial cheating proofs
that must be rejected**.

## 2. Environment reality (honesty first)

The execution plan's Step 0 initially found **no** Lean toolchain (`elan`/`lake`/`lean` absent). The
skeleton was therefore first authored *unverified*. It has since been **built and run**:

- Installed **elan 4.4.0** and the pinned toolchain **`leanprover/lean4:v4.35.0`** — confirming the
  Phase-0 version pin is a real release (Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`).
- `lake build` → **success** (6 jobs).
- `lake env lean tests/adversarial.lean` → **exit 0**, all six cheat cases rejected, honest case
  verified (output in §7).

Remaining environment facts:
- The machine is **not a git repository**.
- **Mathlib is deliberately not a dependency** of this project (see §5): the trusted gate needs only
  Lean core, so the trusted base stays small (invariant #1) and the build is seconds, not hours.
- There is still **no Lean REPL tool server** in the skeleton (it needs a running session); that
  remains design-only (§5).

## 3. What was actually built (files)

| File | Role | Trust |
|---|---|---|
| `skeleton/lean-toolchain` | pin Lean `v4.35.0` (**verified real**) | config |
| `skeleton/lakefile.toml` | no external deps; commented Mathlib require | config |
| `skeleton/ProofAgent.lean` | library root (imports the four modules) | — |
| `skeleton/ProofAgent/Spec.lean` | `ProblemSpec`, `Claim` — the untrusted input artifacts | untrusted |
| `skeleton/ProofAgent/VerifierGate.lean` | banned-token scan, statement match, axiom allow-list; total `gate` | **trusted core** |
| `skeleton/ProofAgent/Memory.lean` | append-only, content-addressed **JSONL** store + dedup `insert`, `load`, `size` | untrusted periphery |
| `skeleton/ProofAgent/Orchestrator.lean` | propose→verify→record; `verifyAndRecord` persists only on `.verified` | untrusted periphery |
| `skeleton/tests/adversarial.lean` | 6 cheat proofs (must reject) + 1 honest proof (must pass) + machine-checked axiom tests | test |
| `skeleton/tests/memory.lean` | store ops, dedup, and gate→persist end-to-end | test |
| `skeleton/README.md` | how to run + scope/honesty | doc |

**Build/run result:** compiled with Lean 4.35.0; tests pass (see §7).

## 4. Design mapping (what the skeleton proves about the design)

The skeleton is a *thin slice through the trusted boundary*, chosen because Phase 1/Phase 5/Phase 7
identify the gate as the load-bearing part.

```mermaid
flowchart LR
    A["untrusted agent<br/>(proposes Claim)"] --> G["VerifierGate.gate<br/>(trusted core)"]
    G -->|reject| F["failure memory<br/>(F1-F3 guarded)"]
    G -->|verify| M[("verified<br/>MemEntry<br/>+ provenance")]
    style G fill:#fdd,stroke:#900,stroke-width:2px
    style M fill:#dfd,stroke:#090
```

It concretely exercises these design claims (each now demonstrated by a passing run):

- **Invariant #1** — the gate is total and deterministic; agents never adjudicate truth.
- **F1 (kernel bypass)** — rejected by the data-driven banned-token scan (`bannedTokens`).
- **F2 (statement drift)** — rejected by content-hash comparison against the signed `ProblemSpec`.
- **F3 (axiom inflation)** — rejected by the `{propext, Classical.choice, Quot.sound}` allow-list.
- **A1 (compiled ≠ verified)** — only `gate = .verified` appends a `verified` memory entry.
- **F7 (memory poisoning)** — `verifyAndRecord` persists only `gate = .verified` entries; rejections
  never reach the store.
- **Invariant #3 (provenance / append-only)** — `MemEntry` carries hash, producer, status; the store is
  an append-only JSONL log and `insert` never mutates existing lines.
- **Phase-5 dedup lever** — `insert` dedups by content key (a second identical insert is a no-op).

## 5. What the skeleton deliberately does NOT include (and why)

| Missing piece | Reason | Where designed |
|---|---|---|
| Lean REPL tool server | needs a live session; out of scope for a static skeleton | Phase 3 §5.3; Phase 2 |
| Elaborated-`Expr` inspection | the textual scan is a stand-in; the real gate inspects the elaborated expression | Phase 3 §5.8 |
| **Independent re-check** (nanoda/con-leche/lean4lean) | external tools + export pipeline; is what upgrades `compiled`→`verified` (A1) | Phase 3 §5.8; Phase 5 §3.3 |
| Content-addressed store: **index / sharding** | the JSONL log + dedup exist; the content-addressed *index* and sharding are not yet built | Phase 3 §5.5; Phase 5 §3.5 |
| Mathlib integration | not needed by the gate; added when the pipeline imports it | Phase 2, Phase 6 |
| Swarm / portfolio scheduler | MVP is one loop; scaling is Phase 5/6 | Phase 2 diagram F |
| Human gates, sensor bridge, actuators | later stages (v2–v4) | Phase 6 |

## 6. How to make it real (the next 1–2 weeks of engineering)

1. Keep the pinned toolchain; add Mathlib in `lakefile.toml` and `import Mathlib...` where the
   pipeline (not the gate) needs it.
2. Replace the textual `scanBanned` with elaboration + inspection of the elaborated `Expr`
   (defeq-check against the signed spec's `Expr`), keeping `gate` total.
3. Wire `#print axioms` output into `axiomsUsed`; add the signed-policy log for exceptions.
4. Add the independent re-check step so `verified` means "exported and re-checked" (A1).
5. Add a content-addressed **index** (and sharding) over the JSONL log — the log, provenance and dedup
   already exist (`ProofAgent/Memory.lean`).

## 7. Acceptance test for Phase 9

- **Input:** `tests/adversarial.lean`.
- **Expected behaviour:** six rejections (`sorryFound`, `nativeDecideFound`, `unsafeFound`,
  `kernelBypassOption`, `statementMismatch`, `forbiddenAxiom`) followed by one `verified`; exactly one
  `verified` `MemEntry`.
- **Pass/fail metric:** all six cheats rejected **and** the honest case accepted. Any cheat accepted =
  fail (blocking).
- **Failure it guards:** F1/F2/F3/F7 — the classes that would let a false theorem be published as
  proven.
- **Status here: PASSED** on Lean 4.35.0 (`lake build` success; test exit code 0). Recorded output:

```
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

### 7b. Acceptance test for the memory store

- **Input:** `tests/memory.lean`.
- **Expected:** first `insert` appends (`true`); second identical `insert` is deduped (`false`); a
  rejected proposal is **not** persisted; an honest proposal is; reload parses the JSONL back.
- **Pass/fail metric:** dedup works **and** rejections never reach the store **and** the round-trip
  reproduces the entries.
- **Failure it guards:** F7 (memory poisoning); invariant #3 (provenance/append-only).
- **Status here: PASSED** (exit code 0). Recorded output:

```
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

## Self-critique (Phase 9)

- **Weakest point:** the skeleton demonstrates the gate's *policy*, not the *full pipeline* — the
  textual scan is knowingly weaker than elaborated-`Expr` inspection + independent re-check (§6).
  A passing run must **not** be read as a `verified` claim per A1.
- **What was fixed:** the project now **builds and passes** on a real, pinned Lean 4.35.0; two real
  bugs were found and fixed by the compiler (the reserved word `axiom` as a field name; a missing
  library root file), which is exactly the value of actually building it.
- **What was built since first draft:** the memory store is now **real** — an append-only JSONL log
  with content-addressed provenance and dedup (`ProofAgent/Memory.lean`), tested end-to-end
  (§7b). Its content key is FNV-1a, deliberately non-cryptographic for the skeleton; production uses
  SHA-256 over canonical artifact bytes.
- **What remains flagged:** no Lean REPL tool, no Mathlib, no independent re-checker; `String.splitOn`
  being `@[extern]` is why verdicts are checked via `#eval` rather than `by decide`. The
  elaborated-`Expr` gate (kernel-reducible) is what enables machine-checked proofs about the gate
  itself. All items are on the §6 list.
