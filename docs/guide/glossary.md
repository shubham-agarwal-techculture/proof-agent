# Glossary

Every term a reader of *any* level might hit, defined twice where useful:

- **Plainly** — the everyday-language version (for T0/T1 readers).
- **Precisely** — the version an expert needs (for T2/T3 readers).

Terms are alphabetical. Cross-references are in *italics*. Tier badges show where a term first matters:
`T0` beginner · `T1` intuition · `T2` practitioner · `T3` expert.

---

### A

**A1 (assumption)** `T2·T3`
*Plainly:* "It compiled" is **not** the same as "it is proved."
*Precisely:* `verified` requires an exported artifact that has been **independently re-checked** and
statement-matched; a successful `lake build` yields only `compiled`. Foundation of the *gate*'s
division of labour. (Compare: *compiled*, *verified*.)

**A2 (assumption)** `T2·T3`
The axiom *allow-list* — exactly `{propext, Classical.choice, Quot.sound}`. Any other *axiom* is a
signed, logged policy exception, never silent. (See *axiom*, *axiom inflation*.)

**A3 / A4 (assumptions)** `T3`
**A3:** the *evaluator* is **frozen and agent-unwritable**. **A4:** cost is reported as US$/verified
theorem and GPU-seconds/verified lemma. (See *evaluator*, *cost-awareness*.)

**Agent** `T0·T1`
*Plainly:* an AI program that *suggests* proofs. It is allowed to be wrong; it is never trusted.
*Precisely:* an untrusted proposer (LLM, heuristic, search, curiosity module) that emits *Claims*; it
sits above the *gate* and has no write access to the *trusted core*.

**Amdahl's law / proof-DAG ceiling** `T3`
*Plainly:* if early steps of a proof are needed by everything after them, you can't speed it up by
adding workers.
*Precisely:* within a single theorem, the proof's dependency graph (*proof DAG*) serializes on shared
early lemmas; the design estimates single-theorem speedup saturates at **≈ 2–3×**, motivating
*scale breadth, not depth*.

**Axiom** `T0·T1`
*Plainly:* a starting assumption a proof is allowed to take for granted.
*Precisely:* a declaration taken as true without proof; its use is visible via `#print axioms`. Because
an axiom silently strengthens a theorem's prerequisites, the gate audits them against the *allow-list*.

**Axiom inflation** `T1·T3`
The failure mode (**F3**) where results accumulate extra axioms (or the allow-list erodes) and stop
being constructive/trustworthy. Countermeasure: the fixed allow-list plus signed exceptions only.

---

### C

**Candidate** `T2`
A *memory* entry that has **not** passed independent re-check; it is quarantined and never reused as a
verified premise. The opposite of *verified*. (See *memory poisoning*.)

**Claim** `T2`
An untrusted proposal: `{ specHash, producer, proofText, derivesFrom }`. Its `specHash` is what the
agent *claims* it proved; the gate checks it against the *ProblemSpec*'s signed hash. (See *Spec.lean*.)

**Compiled** `T2·T3`
Lean's compiler accepted the text. **Necessary but not sufficient** for truth — a `sorry` proof
compiles with only a warning. (See *A1*, *verified*.)

**Content-addressed** `T1·T3`
*Plainly:* things are named by a fingerprint of their content, so identical content is recognized
instantly and can be deduplicated.
*Precisely:* an artifact's identity is the hash of its canonical bytes; this enables *dedup*, caching,
revocation, and provenance. Skeleton uses *FNV-1a*; production uses SHA-256. (See *provenance*.)

**Cost-awareness** `T3`
Invariant #9: the system tracks US$/verified theorem and GPU-s/verified lemma. The product is *verified
truth*, not proposals.

---

### D

**Dedup factor `d`** `T3`
The fraction of "new" proposals that are already known. It multiplies effective throughput for free,
which is why *memory* is a cost lever (Phase 5). (See *capacity model*.)

**derivesFrom** `T2`
A field of *Claim*: the content hashes of memory artifacts a proposal relies on. Used for *poisoning*
analysis — tracing which premise contaminated which conclusion. (See *F7*.)

---

### E

**Elaborated expression / `Expr`** `T2·T3`
The fully-resolved internal term Lean builds from source. Statement matching and the real hygiene scan
run on the *elaborated* form, because source text can be fooled by macros, notation, and defaults.
(`pp.all` prints it fully.)

**Elan** `T2`
The Lean toolchain manager; installs and pins the Lean version declared in `lean-toolchain`.

**Evaluator** `T3`
The harness that measures the system (benchmarks, N-sweeps). **Frozen and agent-unwritable** (A3) so it
can't be gamed.

---

### F

**Failure mode (F1–F19)** `T1·T3`
A named way the system can fail or be attacked, catalogued in Phase 7 with mechanism, mitigation,
early-warning signal, and a cheap probe. Grouped by the invariant each attacks. (See *F1*, *F2*, *F3*,
*F7*, *memory poisoning*, *fidelity*.)

**F1** — kernel bypass (`sorry`/`native_decide`/`unsafe`/`implemented_by`/`partial`/`skipKernelTC`).
**F2** — statement drift (proving the wrong/weaker statement). **F3** — axiom inflation. **F4** —
re-checker agreement ≠ independence (correlated bugs). **F5** — supply-chain via dependencies. **F6** —
elaborator/macro trickery. **F7** — memory poisoning. **F8** — stale/wrong dead-end register.

**Fidelity** `T1·T3`
Invariant #2: proving the *wrong statement* (a dropped hypothesis, a weakened quantifier) is a
first-class risk. **A theorem about a model is never a fact about reality.** Guarded by a *statement
auditor* and explicit *model-gap* accounting. (See *B2*.)

**FNV-1a** `T2`
A fast, **non-cryptographic** hash used in the skeleton only to give memory entries a stable *content
key*. Production uses SHA-256. (See *content-addressed*.)

---

### G

**Gate / VerifierGate** `T0·T1·T2`
*Plainly:* the strict checker whose "yes" is the only thing that counts.
*Precisely:* a **total, deterministic** function `gate : ProblemSpec → Claim → provedHash → axiomsUsed →
Verdict` that rejects banned tokens (G5), statement mismatch (G1), and non-allow-listed axioms (G4); on
`.verified` alone may memory be written. Skeleton: [`VerifierGate.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean).

**Goal state** `T1·T2`
*Plainly:* what still needs to be proved at a given point.
*Precisely:* the hypotheses and `⊢` target Lean reports for a statement. The skeleton reads the
**initial** goal by compiling `example : <stmt> := by skip` and parsing the `unsolved goals`
diagnostic — one-shot, not interactive. (See *GoalState.lean*.)

---

### I

**Independent re-checker** `T3`
A *different* kernel implementation (nanoda/con-leche/lean4lean class) that re-checks the **exported**
proof, so a bug/backdoor in one checker doesn't crown a false theorem. Caveat **F4**: agreement is
*bounded* evidence when the checkers share assumptions.

**Invariant (design)** `T1·T3`
One of ten non-negotiable rules (plus three pack-level). See *trusted core*, *fidelity*,
*content-addressed*, *memory as a learning system*, *bounded in actions*, *calibrated honesty*,
*cost-awareness*.

---

### K

**Kernel** `T0·T2`
*Plainly:* the tiny, trusted engine deep inside Lean that does the actual proof-checking.
*Precisely:* the small trusted core of the proof assistant; a *kernel bypass* (F1) is any construct
that makes a statement elaborate/compile without the kernel checking truth.

---

### L

**Lean 4** `T0·T2`
A programming language for stating and machine-checking mathematics. Pinned here at
`leanprover/lean4:v4.35.0`.

**LLM** `T0·T1`
Large Language Model — the AI behind chatbots; in this system, an *untrusted* proposer of proofs. The
slogan **"LLM proposes, kernel disposes"** names invariant #1.

---

### M

**Mathlib** `T2·T3`
Lean's large community mathematics library. Deliberately **not** a dependency of the skeleton's trusted
core (invariant #1: keep the trusted base small).

**MCP / A2A** `T3`
Protocol families: **MCP** = model-context protocol, the *agent ↔ tool* interface;
**A2A** = agent-to-agent, the *agent ↔ agent* interface (the conductor delegating to the L4 society).
The skeleton's check server is the MCP-tool shape in miniature.

**Memory (as a learning system)** `T1·T3`
Invariant #5. Not storage: the compounding engine. Layers: working · episodic · semantic · procedural ·
meta · world. Only re-checked artifacts enter *verified* memory. (See *dedup*, *poisoning*.)

**Memory poisoning** `T1·T3`
Failure mode **F7**: a wrong/unverified result enters memory and spreads by being reused as a premise.
Structurally prevented — rejections never enter verified memory (see the *Orchestrator*).

**Model gap** `T3`
The distance between a *model* (e.g. a control-law model) and reality. The design accounts for it
explicitly; a theorem about the model is never asserted as a fact about the world.

---

### N

**native_decide** `T1·T2`
A Lean tactic that evaluates a decidable proposition by **running code**, outside the kernel — so it is
*not* a proof term in the trusted sense. The gate rejects it (F1).

---

### P

**ProblemSpec** `T2`
The **human-signed** statement: `{ id, statement, specHash, safetyCritical, domain }`. `specHash` is the
hash of the *elaborated* goal type — the reference the gate trusts. `safetyCritical` forces human
sign-off for real-world claims. (See *Spec.lean*.)

**Proof** `T0`
A rigorous argument that a statement is true in **every** case, not just checked cases.

**Proof DAG** `T3`
The dependency graph of a proof; its serialization causes the *Amdahl* ceiling on single-theorem
parallelism.

**Provenance** `T1·T3`
Invariant #3: every artifact records where it came from (producer, dependencies, version). Enables
dedup, revocation, and *poisoning* analysis. (See *content-addressed*, *derivesFrom*.)

---

### R

**RejectReason** `T2`
The enumerated *cheat surface*: `sorryFound`, `nativeDecideFound`, `unsafeFound`, `implementedByFound`,
`partialFound`, `kernelBypassOption`, `statementMismatch signed claimed`, `forbiddenAxiom name`. Because
it is data, the policy is auditable.

---

### S

**Safety-critical** `T1·T3`
A claim about the real world requiring human sign-off (invariant #8). Automation cannot own meaning.

**Scale-free architecture** `T3`
Invariant #4: the same design works from 10⁰ to 10⁹ agents/proposals; the *scale ladder* is a
deployment axis, not an architectural one.

**`sorry`** `T0·T1`
*Plainly:* a Lean keyword meaning "pretend this is proved — I give up."
*Precisely:* a placeholder that lets anything compile with only a warning; the gate rejects it (F1).
The archetypal *A1* trap.

**Statement drift** `T1·T3`
Failure mode **F2**: proving a weakened/altered statement that type-checks but isn't the spec.
Countermeasure: match the *elaborated* type against the signed spec hash.

**Statement auditor** `T3`
An L4 role that adversarially falsifies formalizations (toy instances, non-vacuity, back-translation)
so *fidelity* (**F2/B2**) is caught before proof effort is spent. Its *check* is itself gate-verified.

---

### T

**Theorem / Lemma** `T0`
A statement that has been *proved*. A **conjecture** is one believed but not proved (checking cases is
not proving).

**Toolchain (pinned)** `T2`
The exact Lean version a project uses (`lean-toolchain` → `leanprover/lean4:v4.35.0`), so results are
reproducible and dependencies are content-addressed (**F5**).

**Total (function)** `T2·T3`
A function defined on *every* input. The gate is total and deterministic: no input escapes a verdict, so
there is no "undefined behaviour" path into memory — a safety property, not a style choice.

**Trusted core** `T0·T1·T3`
Invariant #1: the small, auditable part (Lean kernel + independent re-checker + statement matcher +
axiom auditor + content-addressed store + guardrails) that is the **sole authority**. Nothing outside it
may write to it.

---

### U

**unsafe / implemented_by / partial** `T1·T2`
Lean features that weaken or escape logical checking. All rejected by the *gate* (F1).

---

### V

**Verdict** `T2`
The gate's output: `verified` or `rejected reason`. Skeleton: `inductive Verdict | verified | rejected
(Reason)`.

**Verified** `T1·T2·T3`
*Plainly:* "the gate said yes" — the only status that counts.
*Precisely:* a **statement-matched**, **axiom-audited**, **independently re-checked** artifact. Distinct
from *compiled* (**A1**). Only `verified` entries enter verified memory.

---

### W

**Walking skeleton** `T2`
A minimal end-to-end implementation that exercises the core mechanics (here: gate + memory +
orchestrator + tools), so the design's policy can be **run and tested** before the full system exists.
Lives in [`skeleton/`](../../skeleton); builds and passes four test suites on Lean 4.35.0.

---

*Missing a term? It is almost certainly defined in the phase file that introduces it; see the
[guide index](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/README.md)
for the level→source map.*
