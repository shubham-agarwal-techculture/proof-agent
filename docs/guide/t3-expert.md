# Level T3 — Expert (Researcher / Staff Engineer / Domain Expert)

*Assumes formal-methods or ML-systems background. This tier is the **full argument**: architecture,
invariants, threat model, economics, roadmap, bets, failure modes, and open problems. It is the guide's
compression of the design record; each section links to the phase file that argues it in full.*

---

## 0. Thesis, and what kind of artifact this is

**Thesis.** The binding constraint on agentic theorem proving is **verified truth**, not ideation.
Foundation models have collapsed the marginal cost of *proposing*; they have not collapsed the cost of
*checking*, *stating correctly*, or *remembering*. Therefore build a **trusted verification core +
compounding memory** and treat agents as a cheap, elastic, *untrusted* frontier. Formally the project's
bet **B1**: at fixed verifier budget, scaling agent count `N` yields a knee (in time-to-solve and
cost/lemma) well before 10³ on a single theorem; throughput is dominated by the verifier pipeline and
by memory (cache/dedup/retrieval), not by `N`.

**What the artifact is.** Two deliverables: (i) a **design set** — Phases 0–9, one file per phase, each
ending in a self-critique, each major decision carrying a mini decision record (context/options/
decision/consequences) and a falsifying experiment; and (ii) a **real, building skeleton** implementing
the trusted policy. Distinguish them sharply: the skeleton *is*; the scale system *is designed*. Status
tags (`[exists today]` / `[near-term]` / `[frontier]` / `[speculative]`) are used on every capability.

Sources for this tier: [phase-1 framing](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-1-framing.md),
[phase-2 architecture](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-2-architecture.md),
[phase-5 scale & economics](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-5-scale-economics.md),
[phase-6 roadmap](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-6-roadmap.md),
[phase-7 red-team](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md),
[phase-8 memo](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-8-decision-memo.md).

---

## 1. Layered architecture (L0–L7) and the boundary

Phase 2 frames the system as a **prover-verifier sandwich** with a hard trust boundary. Layer summary
(verbatim roles; see [phase-2 §1](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-2-architecture.md#L3-L48)):

| Layer | Trust | Contents |
|---|---|---|
| **L7 · Humans** | — | mathematicians, engineers, reviewers, auditors |
| **L6 · Interface & workbench** | untrusted | ProblemSpec workbench, co-pilot, dashboards, tutoring, write-up |
| **L5 · Curiosity & research programs** | untrusted proposers | ponder engine, generators, triage, belief ledger, program planner, VoI scheduler |
| **L4 · Agent society** | untrusted | conductor, formalizer, **statement auditor**, strategist, librarian, prover, debugger, counterexample hunter, analogist, curator, economist, safety officer |
| **L3 · Planning & search** | untrusted | blueprint/lemma-graph planner, MCTS/best-first, portfolio racing, budget allocator |
| **L2 · Tools** | untrusted, sandboxed, typed, cached | Lean REPL/server, premise retrieval, automation tactics, ATP/SMT, CAS/numerics, counterexample finders, literature/code search, re-verification |
| **L1 · Memory** | untrusted content, trustworthy provenance | working · episodic · semantic · procedural · meta · world memory |
| **L0 · TRUSTED CORE** | trusted | Lean kernel (pinned) · **independent re-checker** · statement matcher · axiom auditor · content-addressed store · verified guardrails (action gate, capability tokens, autonomy governor) |

**Layer rules (enforced, not stylistic):**

1. **Nothing in L1–L7 may write to L0.** L0's provenance comes from an append-only log owned by L0.
2. Data flows *up* as **verified artifacts** with provenance and structured results; it flows *down*
   only as **untrusted proposals** (candidate proofs, formalizations, plans, formalization hypotheses).
3. **L5 (curiosity) and L2 (tools) are read-only** consumers of L1 semantic memory and of the signed
   spec; they **cannot mutate the problem statement**.

### The attack surface the gate must defeat

[Phase-2 §2](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-2-architecture.md#L92-L104)
enumerates the gate's countermeasures. The gate components are **G1 statement matcher (vs signed
spec)** → **G2 kernel acceptance** → **G3 independent re-check on export** → **G4 axiom allow-list** →
**G5 hygiene scan** (`sorry`/`unsafe`/`implemented_by`/`native_decide`/`partial`/`skipKernelTC`) →
**G6 resource & size limits** → **G7 capability-token/policy (the only path to actuators)**. Fail-closed
throughout.

Key adversarial classes and counters: `sorry`/`admit` (G5 + kernel warning + `#print axioms`); extra
axiom (G4); `native_decide`/`bv_decide` (policy-gated, not silently allowed); `unsafe`/`implemented_by`/
`partial` (G5 + kernel flags); kernel bypass (`skipKernelTC` ⇒ hardened options + independent kernel
re-check, G3); **altered/weakened statement** (G1, structural equality modulo permitted unfolds);
**macro/elaborator tricks** (re-check the *export* on an independent kernel, not the elaborator);
resource exhaustion (G6 sandbox/timeout/size/heartbeat).

---

## 2. The invariants (the constitution)

Ten design invariants (brief §4) plus three pack-level invariants; if any is bent, the phase file says
so and justifies it.

1. Trusted core / untrusted periphery. 2. Fidelity before proof. 3. Versioned, content-addressed
artifacts with provenance. 4. Scale-free architecture. 5. Memory as a learning system. 6. Open-ended in
ideas, bounded in actions. 7. Calibrated honesty. 8. Humans in the loop where it matters. 9.
Cost-awareness. 10. Untrusted inputs. **Pack-level:** verified guardrails · reversibility & least
privilege · federated, portable trust.

Two of these do the most load-bearing work and are worth stating precisely:

- **Invariant #1 (trusted core).** The Lean kernel — with an independent re-checker and statement
  matcher — is the sole authority. This is why the skeleton ([`VerifierGate.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean))
  has **no Mathlib dependency**: keeping the trusted base small and auditable is worth more than
  convenience. "Minimum trusted computing base" as a design force.
- **Invariant #2 (fidelity).** Proving the *wrong statement* dominates as a risk. **A theorem about a
  model is never a fact about reality.** The system carries an explicit **model-gap** accounting and a
  **statement auditor** (L4) whose *check* is itself gate-verified (toy instances, non-vacuity,
  back-translation, adversarial falsification).

---

## 3. Failure modes (Phase 7) — the pre-mortem

Phase 7 is written by the safety/reliability role ("break the design"), assuming a year passed and it
*shipped and failed*, then working backwards. **18 failure/harm modes (labelled F1–F19)**, grouped by
the invariant each attacks; each has *mechanism · mitigation · early-warning signal · cheap probe*, then
unknown-unknown probes and a top-5 watchlist.

**Group A — attacks on the trusted core (invariant #1):**

- **F1 kernel bypass** `[exists today]` — `sorry`/`native_decide`/`unsafe`/`implemented_by`/`partial`/
  `skipKernelTC` make a statement *elaborate and compile* without checking truth. **Mitigation:** gate
  rejects syntactically + axiom audit; `lake build` success is `compiled`, never `verified` (**A1**);
  independent re-check required. **Probe:** `tests/adversarial.lean`.
- **F2 statement drift** `[exists today]` — a weakened/altered statement (dropped hypothesis, changed
  quantifier, `→` vs `↔`, implicit-arg defaulting) type-checks but isn't the spec. **Mitigation:**
  match the *elaborated* type against the human-signed `ProblemSpec`, structurally (modulo permitted
  unfolds), not as a string.
- **F3 axiom inflation** `[near-term]` — results accumulate extra axioms and stop being constructive;
  the allow-list erodes under "just this once." **Mitigation:** allow-list `{propext,
  Classical.choice, Quot.sound}` (**A2**); *any* exception is a signed, logged policy event.
- **F4 re-checker agreement ≠ independence** `[near-term]` — nanoda/con-leche/lean4lean "all accept,"
  but share the exported artifact, the export translation, or the same trusted assumptions — a
  **correlated** bug passes all. **Mitigation:** diversify the *export path and elaboration inputs*, not
  just the back-end; treat "N kernels agree" as *bounded* evidence.
- **F5 supply-chain via Lake/Mathlib pin** `[near-term]` — a compromised dependency alters notation or
  injects a type-checking-but-different term. **Mitigation:** pinned, content-addressed, signed deps;
  air-gappable trusted core; no agent-writable deps in the verified path.
- **F6 elaborator/macro trickery** `[frontier]` — notation/macros make code *look* like the spec while
  elaborating to something else. **Mitigation:** match on the elaborated expression; expand/whitelist
  notation; restrict macros in agent-submitted code; compare under `pp.all`.

**Group B — attacks on memory and learning (invariant #3):**

- **F7 memory poisoning** `[near-term]` — an unverified/subtly-wrong result enters semantic memory and
  is *reused as a premise*, spreading. **Mitigation:** only externally re-checked artifacts enter
  `verified` memory; everything else is quarantined as `candidate` with provenance; memories are
  content-addressed and revocable. **This is the failure mode the skeleton implements directly** — see
  [`Orchestrator.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Orchestrator.lean#L31-L40)
  (no code path from rejection to verified memory).
- **F8 stale/wrong dead-end register** `[near-term]` — a "we tried and failed" record suppresses a now-
  viable path, or noise hides real options. **Mitigation:** dead-ends carry context/version and expire
  when preconditions change; the register is **advisory, not authoritative**.

(Group C onward — attacks on coordination/scale, on human meaning/fidelity, on safety/actuation —
continue in [phase-7](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md),
with the top-5 watchlist at the end.)

---

## 4. Memory as a learning system

Memory is *not storage*; it is the compounding engine (invariant #5). The taxonomy is
**working · episodic · semantic · procedural · meta · world** memory (L1). Design decisions that matter:

- **Layered semantics:** working (current proof state), episodic (what happened), semantic (proved
  facts), procedural (tactics that worked), meta (how to work), world (sensor/domain state).
- **Content-addressing + provenance** (invariant #3) is what makes dedup, cache, revocation, and
  poisoning analysis possible at all.
- **Only re-checked artifacts enter `verified`;** false or unverified results live as `candidate`. **F7**
  is prevented structurally.
- **Consolidation ("sleep")** and curation move episodic traces into durable semantic/procedural memory;
  a **dead-end register** is advisory and versioned (**F8**).

---

## 5. Protocols and the artifact model

- **MCP (agent ↔ tool):** typed tool calls (e.g. `lean.elaborate`, `lean.check`, `retrieval.search`,
  `problemspec.*`). The skeleton's [`CheckServer.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean)
  is the MCP-tool shape in miniature: one long-lived process, JSON request/response per line, `op`
  dispatch, request `id` echo.
- **A2A (agent ↔ agent):** the conductor delegates tasks to the L4 society over an agent-to-agent
  protocol.
- **Artifacts** are versioned, content-addressed, provenance-carrying; the store is append-only. The
  skeleton's JSONL store + `MemEntry { hash, statement, producer, status }` is the single-node seed of
  this.

---

## 6. Scale & economics (Phase 5) — the quantitative core

Phase 5 takes the premise *"more agents ⇒ more theorems"* seriously and locates where it breaks.

### 6.1 Capacity model and the four instrumented numbers

The model is stated in symbols and is explicitly **back-of-envelope with flagged assumptions**, not
measured (the system does not exist) — given as ranges so a factor-of-2 error doesn't flip the
conclusion ([phase-5 §1.1](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-5-scale-economics.md#L26-L41)):

| Symbol | Meaning |
|---|---|
| `τ_a` | mean agent latency for one proposal (10–60 s, multi-turn) |
| `h` | **acceptance rate**: fraction of proposals that are well-formed, on-statement, and kernel-accepted without cheating (≈0.02–0.20 whole-proof) |
| `τ_v` | mean latency of one full verification pass: elaborate + statement-match + axiom audit + independent re-check (≈2–10 s) |
| `c_v` | elaboration cores per verifier pipeline (parallel front-end, **serial kernel**) |
| `d` | **dedup factor**: raw proposals ÷ unique verifier-worthy obligations (after memory lookup) |
| `p` | retrieval precision: fraction of retrieved premises that are actually relevant |
| `N` | live agents (concurrent proposers) |
| `b` | effective branching factor of the reachable subgoal DAG |

The two governing rates are **`X_gross = min(S·h, V)`** (completions) and **`X_use = X_gross / d`**
(net-new knowledge) — agent supply `S = N/τ_a`, verifier capacity `V = (#pipelines)/τ_v`. The **outer
scaler is the verifier term `V`**, which contains no `h` and therefore does **not** improve with better
agents — only with cheaper verification, more pipelines, or better caching.

The design commits to instrumenting exactly four numbers
([phase-5 §8](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-5-scale-economics.md)):
**demand rate · verifier capacity · dedup factor `d` · retrieval precision `p`.** *Without these,
nothing in the design is falsifiable.*

### 6.2 The scale ladder 10⁰ → 10³ → 10⁶ → 10⁹

Deployment topologies from a single workstation to a large fleet, with the bottleneck changing by rung:
at small scale the bottleneck is single-prover capability; at medium scale it is **verifier throughput**
(elaborate → statement-match → axiom audit → independent re-check) plus **memory**; at very large scale,
**coordination** and **retrieval** dominate.

### 6.3 Why more agents stop helping

Three independent ceilings:

1. **Proof-DAG Amdahl ceiling (~2–3×).** Within one theorem, early proof steps are needed by almost
   everything downstream, so single-theorem speedup saturates. *Scale breadth, not depth.*
2. **Verifier throughput.** `verified` output is bounded above by verifier capacity `c_v`; agents past
   that point just lengthen the queue.
3. **Retrieval/dedup decay at portfolio scale.** As the corpus grows, retrieval precision `p` and dedup
   `d` can degrade (**F16** territory) — turning memory from an asset back into a cost.

### 6.4 Cost accounting

Cost is reported as **US$/verified theorem** and **GPU-seconds/verified lemma** (**A4**), with energy
accounting, because "verified theorem" is the only unit that matters — cheap *proposals* are not the
product. Investment order is therefore fixed: **verifier → memory → retrieval → reasoning → curation →
agents (last)**.

---

## 7. The bets, and their falsifiers (Phase 5/8)

| Bet | Claim | Falsifying experiment |
|---|---|---|
| **B1** | Verification/memory throughput beats agent count | Fixed verifier budget; `N ∈ {10, 100, 1000}` on one hard problem; find the knee in time-to-solve and cost/lemma |
| **B2** | Fidelity is the real risk, not raw capability | A real paper → Lean intake where a **dropped hypothesis is caught** by the statement auditor |
| **B3** | Compounding memory is super-linear | Cost/lemma falls as dedup `d` rises, then rises again once `d` saturates (the **U-shaped** curve) |

Each bet is **falsifiable** and paired with the experiment that could kill it — the design's calibrated-
honesty discipline (invariant #7) applied to itself.

---

## 8. Roadmap and the 90-day MVP (Phase 6)

Sequencing is the investment order unrolled in time, under a **fidelity-first** discipline (a proof
counts only when the *statement is right* **and** an independent kernel re-checks it):

- **MVP (0–3 mo)** — "one problem, honestly proved." Packs §5.1 (intake, text-only), §5.2 (basic
  planner), §5.3 (Lean REPL + Mathlib tools), §5.5 (working/episodic/procedural memory v0), §5.8
  (gate + axiom audit + independent re-check), §5.20 (logging), a tickle of §5.9 (human gate). Deliverable:
  the Phase-9 walking skeleton + instrumentation for `demand/V/d/p`. **Exit:** ≥3 nontrivial Mathlib
  lemmas independently re-checked on a pinned toolchain; every adversarial test rejected and the honest
  case accepted; dashboards report all four numbers; a statement-mismatch attack fails. **Kill:**
  if the gate can't reject *every* known cheat class → **stop and fix the gate** (invariant #1, no
  exceptions).
- **v1 (3–9 mo)** — days-long autonomy; full paper→Lean intake; VoI planner + portfolio scheduler;
  **bounded** per-problem swarm (10–100); semantic memory + consolidation; read-only sensor *stub*;
  multi-kernel re-check + statement signing. Scale: 10³ proposals across a **portfolio**, per-theorem
  concurrency capped (DR 5.1).
- **v2 (9–18 mo)** — research partner. **v3 (18–30 mo)** — sensors, programs, discovery. **v4 (30–42+
  mo)** — campaigns, federation, actuators (human-gated).

**90-day demo (four parts):** (i) live rejection of every cheat class; (ii) statement-audit catching a
sloppy formalization; (iii) the `N`-sweep knee — **or its honest absence**; (iv) checkpoint/restart with
dead-end reuse. Guiding rule: **each stage must be falsifiable by an experiment it can afford.**

---

## 9. Honesty ledger: built vs. designed

| Item | State |
|---|---|
| Trusted gate policy (banned tokens · statement-hash match · axiom allow-list), total & deterministic | **Built & tested** ([`VerifierGate.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean)) |
| Append-only, content-addressed, deduped memory | **Built & tested** ([`Memory.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean)) |
| propose→verify→record, rejections never persisted | **Built & tested** ([`Orchestrator.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Orchestrator.lean)) |
| Lean check tool; one-shot **goal-state** reader; JSON tool server | **Built & tested** ([`Tools/`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools)) |
| Elaborated-`Expr` matching, `#print axioms` wiring, **independent re-checker**, interactive stepping | **Designed** (Phase 9 §6) — explicitly absent from the skeleton |
| Agents, retrieval, curiosity, sensors, federation, portfolios, campaigns | **Designed & staged** (Phase 6) |

The skeleton is honest about being a skeleton: it proves the **policy** of the trusted boundary and
ships three real tools, but does not implement elaboration-based matching, axiom wiring, interactive
goal stepping, or the independent re-checker. Note the deliberate side effect of **A1** in the tests: the
check tool *accepts* a `sorry` proof (warning only) — precisely because the gate, not the compiler, is
what rejects it.

---

## 10. Open problems / frontier

The design is explicitly bounded by evidence; these are where it is weakest and where research is
required (`[frontier]`/`[speculative]`):

- **Independent re-checker *independence* (F4).** Correlated bugs across nanoda/con-leche/lean4lean and
  shared export paths mean "N kernels agree" is bounded evidence, not proof. Diversifying the export
  path is an open engineering–research problem.
- **Fidelity at intake (B2, Phase 1 Q1).** Autoformalizing a *research paper* without dropping
  hypotheses is the least-solved part, and the design warns it may **double the MVP timeline**.
- **Retrieval/dedup decay (F16, B3).** Whether compounding memory stays super-linear at portfolio
  scale, or the U-shaped curve turns upward, is unmeasured.
- **Single-theorem parallelism ceiling.** The ≈2–3× proof-DAG ceiling is an estimate; if wrong, the
  architecture's breadth-first emphasis weakens.
- **Human gates are irreducible.** Definition admission to the shared library and any
  `safety_critical` claim about the real world require human sign-off because automation cannot own
  meaning.

---

## 11. Where to go next

- **Full depth:** the phase files — [0](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-0-landscape.md) (landscape/citations),
  [1](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-1-framing.md) (P1–P11, A1–A4, leverage questions),
  [3](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-3-deep-dives.md) (§5.1–§5.22, prompts, schemas, pseudocode),
  [4](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-4-worked-examples.md) (traced examples a–e).
- **One page:** [phase-8-decision-memo.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-8-decision-memo.md).
- **Code:** [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md), [phase-9](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-9-walking-skeleton.md).
- **Terms:** [Glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md). **Lower levels:** [T2](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md) · [T1](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md) · [T0](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md).
