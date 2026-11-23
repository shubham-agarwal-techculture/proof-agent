# ProofAgent — The Reader's Guide

This folder is a **single explanation of ProofAgent, written four times**, once for each reader level.
The design is the same at every level; only the amount of prior knowledge assumed changes. Pick the
level that fits you, read down from there, and jump to the [glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md)
(or up a level) whenever a term is unfamiliar.

> **One rule holds the whole project together, and it is stated the same way at every level:**
> **untrusted agents propose; the trusted kernel disposes.** A computer-checked proof counts for
> something only because a small, trustworthy core says *yes*. Everything else in ProofAgent is an
> elaborate way of feeding that core good candidates.

---

## 1. Choose your level

| Level | File | Reader | Assumes | Answers |
|---|---|---|---|---|
| **T0** | [t0-high-schooler.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md) | Curious high-schooler, anyone new to this | Arithmetic, a little algebra | *What is a proof? Why would a computer check one? What is this thing?* |
| **T1** | [t1-intuition.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md) | Undergrad / engineer barely new to the field | T0 | *How does it work, and why is it built this way?* |
| **T2** | [t2-practitioner.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md) | Working programmer / Lean user | Can read code; some Lean helps | *How do I build, run, and extend it?* |
| **T3** | [t3-expert.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md) | Researcher / staff engineer / domain expert | Formal methods or ML systems background | *What exactly is the design, its assumptions, its bets, and where is it weak?* |

Plus a single [**glossary**](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md)
that defines every term at a school-level entry point *and* gives the precise meaning, so a reader at
any level can look up any word without leaving the guide — and three supplementary shelves — **persona
guides**, **background primers**, and **how-to guides** — in §5.

```
T0  what & why          (no jargon; analogies)
T1  how it works        (mechanisms + the reasons behind them)
T2  how to build it     (real files, real commands)
T3  how it's argued     (architecture, economics, failure modes, bets)
                  ↕
  personas/  ·  primers/  ·  how-to/   (audience · background · tasks)
                  ↕
            glossary (all terms, all levels)
                  ↕
     docs/phase-0..9  (the full design record, expert reference)
```

---

## 2. The same story at four depths

To make the tiers concrete, here is the project's central idea rendered at each level. If you only
read one row, read the one matching your level; noticing how the *same* claim survives the depth
increase is the point.

| Level | The idea, in that level's words |
|---|---|
| **T0** | A proof is a careful argument that a statement is *always* true, not just true in the cases you tried. ProofAgent is a machine that tries to *write* such arguments — but a second, very strict machine *checks* them, and only its "yes" is trusted. |
| **T1** | An AI proposes a Lean proof; a small trusted gate re-checks it against the signed statement, forbids known "cheats", and audits which axioms were used; only a gate-passing proof is written to memory. Verified results compound; rejected ones are discarded. |
| **T2** | `ProofAgent.Tools.LeanCheck` compiles candidates with the pinned `lean --json`; `VerifierGate.gate` is a total, deterministic function rejecting the six banned tokens plus statement-hash mismatch plus non-allow-listed axioms; `Orchestrator.verifyAndRecord` appends a deduped, content-addressed `MemEntry` to an append-only JSONL store only on `.verified`. |
| **T3** | A layered system (L0 trusted kernel → L7 humans) whose throughput is bounded by the *verifier pipeline* and *memory*, not agent count; it is organized around ten invariants, tested against failure modes F1–F19, and probed by falsifiable bets B1–B3 (e.g. the proof-DAG Amdahl ceiling ≈ 2–3× on single-theorem speedup). |

---

## 3. What ProofAgent actually is (short)

ProofAgent is a *design + a working skeleton* for an **agentic theorem-proving system on Lean 4**:

- **Input:** a mathematical (or scientific) problem, eventually from text or data.
- **Agents (untrusted, elastic, cheap):** propose formalizations, plans, tactics, proofs.
- **Trusted core (small, auditable, expensive):** a Lean-based **verifier gate** that alone decides
  whether something is *verified*.
- **Memory (compounding):** verified results are stored content-addressed with provenance, deduped,
  and reused; rejections never enter verified memory.
- **Goal:** prove *new* theorems at scale — with honesty engineered in (every claim carries a status,
  a provenance, and the experiment that would falsify it).

The **design record** lives in the sibling files `../phase-0-landscape.md` … `../phase-9-walking-skeleton.md`
(see the [design-set index](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/README.md)).
The **code** lives in [`../../skeleton/`](../../skeleton). Both are cross-referenced from each tier.

---

## 4. Reading paths (pick one)

- **"I just want the idea."** T0 → T1. Stop at [glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md) when needed.
- **"I want to run it."** T1 → T2 → then the [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md) §"How to run".
- **"I'm evaluating the design."** T1 → T3 → [Phase 8 memo](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-8-decision-memo.md) → [Phase 7 red-team](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md).
- **"I'm going to work on it."** T2 → T3 → the phase docs most relevant to your component (Phase 3 for agents/schemas, Phase 5 for scale, Phase 2 for architecture).

---

## 5. More guides: personas, primers, how-tos

Beyond the four levels, the guide ships three supplementary shelves. Use them to match an *audience*,
fill a *knowledge gap*, or accomplish a *task*.

### 5.1 Persona guides — start where you are (`personas/`)

One short entry point per audience; each says why the project matters *to you* and which tier to read.

| Persona | File |
|---|---|
| Kids (~10–13) | [for-kids.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/personas/for-kids.md) |
| Teachers | [for-teachers.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/personas/for-teachers.md) |
| Undergraduates | [for-undergrads.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/personas/for-undergrads.md) |
| PhD researchers | [for-researchers.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/personas/for-researchers.md) |
| Engineers | [for-engineers.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/personas/for-engineers.md) |
| Funders / decision-makers | [for-funders.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/personas/for-funders.md) |
| Journalists | [for-journalists.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/personas/for-journalists.md) |
| Policymakers | [for-policymakers.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/personas/for-policymakers.md) |

### 5.2 Background primers — fill the prerequisite (`primers/`)

The tiers assume some background; these primers supply it without leaving the guide.

| Primer | What it unblocks |
|---|---|
| [logic-and-proofs.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/logic-and-proofs.md) | What a proof is; `∀`/`∃`, implication vs. equivalence; proof styles |
| [lean-crash-course.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/lean-crash-course.md) | Lean 4 syntax, using only code from this repo; the repo's real gotchas |
| [type-theory-intuition.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/type-theory-intuition.md) | "Propositions are types"; the kernel as referee; elaborated `Expr` |
| [llm-and-agents.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/llm-and-agents.md) | LLMs, agents, propose→verify→record, memory poisoning, the throughput bet |

### 5.3 How-to guides — do a specific task (`how-to/`)

Task-oriented, with real commands and "verify it worked" checklists.

| Task | Guide |
|---|---|
| Build and run the skeleton | [build-and-run.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/build-and-run.md) |
| Extend the trusted gate (add a banned token / change the axiom allow-list) | [extend-the-gate.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/extend-the-gate.md) |
| Add a new tool | [add-a-tool.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/add-a-tool.md) |
| Fix common problems | [troubleshooting.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/troubleshooting.md) |
| Contribute (repo layout, trust rules, conventions) | [contributor-guide.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/contributor-guide.md) |

---

## 6. Honesty contract of this guide

The guide obeys the project's own discipline:

- **Verified vs. designed vs. proposed** are kept distinct, exactly as in the design set. The walking
  skeleton **builds and its four test suites pass** (Lean 4.35.0); everything else at the scale tiers
  is *design*, not measured, and is labeled so.
- **No invented facts.** Figures from the design docs are reproduced with their "back-of-envelope"
  caveat attached (they are ranges with explicit assumptions, not measurements).
- **Every tier says what is *not* true yet**, so no level mistakes the skeleton for the system.

Status vocabulary used throughout (from the design set):

| Tag | Meaning |
|---|---|
| `[exists today]` | Shipping/known practice or tooling as of 2026-11-23 |
| `[near-term]` | Credible within a normal engineering cycle on current foundations |
| `[frontier]` | Requires research progress; plausible but unproven |
| `[speculative]` | Beyond current evidence; stated to bound the design, not promised |
