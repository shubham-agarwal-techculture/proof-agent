# Level T1 — Intuition (Undergrad / Engineer New to the Field)

*Assumes you read [T0](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md)
or already know what a proof, Lean, and a kernel are. Here we add the **mechanisms** and, crucially,
the **reasons** each mechanism is shaped the way it is.*

---

## 1. The shape of the system: a boundary, not a blob

Most "AI does math" pitches sound like: *put a big model in a loop and let it think.* ProofAgent's
central bet is different. It splits the world into two halves and never lets them blur:

```
        UNTRUSTED (big, cheap, elastic, possibly hostile)
   ┌───────────────────────────────────────────────────────────────┐
   │  agents · planners · retrieval · tool calls · "curiosity"      │
   │  → produce CANDIDATE formalizations and proofs                 │
   └───────────────────────────────┬───────────────────────────────┘
                                   │  proposes (a Claim)
                                   ▼
        TRUSTED (small, auditable, expensive, slow on purpose)
   ┌───────────────────────────────────────────────────────────────┐
   │  VERIFIER GATE                                                 │
   │   1. reject banned constructs (sorry, native_decide, unsafe)   │
   │   2. statement match: does the proved statement hash equal     │
   │      the hash of the statement a human signed?                 │
   │   3. axiom audit: only {propext, Classical.choice, Quot.sound}  │
   │   → verdict: verified | rejected(reason)                       │
   └───────────────────────────────┬───────────────────────────────┘
                        verified │ only
                                   ▼
   ┌───────────────────────────────────────────────────────────────┐
   │  MEMORY (append-only, content-addressed, deduped)              │
   │   verified entries only · rejections never enter               │
   └───────────────────────────────────────────────────────────────┘
```

Everything left of the gate can be wrong, slow, or malicious without endangering the truth of what's
recorded. That's the whole point of the boundary: **the gate is the only thing that has to be right.**

---

## 2. The loop: propose → verify → record

The core runtime is three steps, repeated:

1. **Propose.** An agent produces a `Claim`: a proof text, a statement hash, a producer id, and the
   list of memory artifacts it relied on (`derivesFrom`, used for poisoning analysis).
2. **Verify.** The gate returns `.verified` or `.rejected reason`.
3. **Record.** On `.verified`, a content-addressed `MemEntry` (hash, statement, producer, status) is
   appended to the store. On any rejection, **memory is untouched** — the rejection may go to a
   separate *failure memory*, never to verified memory.

Two design choices hide inside this simple loop:

- **Total & deterministic gate.** For *every* input the gate returns a verdict; there is no "maybe,"
  no exception, no path where an unverified thing slips into memory. Totality is a safety property,
  not a style preference.
- **Rejections never enter verified memory.** This single rule is the defence against *memory
  poisoning* (failure mode **F7**): otherwise a stream of plausible wrong claims could slowly convince
  the system of falsehoods. Provenance (`derivesFrom`) lets you later ask "which bad premise
  contaminated which conclusions?"

---

## 3. Why each gate rule exists

The gate is a short list of rules, each closing a specific, real hole:

| Rule | The hole it closes | Failure mode |
|---|---|---|
| Reject `sorry` | Lean lets you "prove" anything with `sorry`; it compiles with only a warning. | F1 (kernel bypass) |
| Reject `native_decide`, `unsafe`, `implemented_by`, `partial`, `skipKernelTC` | Lean features that can skip or weaken the kernel's checking. | F1 |
| **Statement match** via hash of the *elaborated* goal type | An agent proves an easier/different statement and claims it proved yours. | F2 (statement drift) |
| **Axiom allow-list** `{propext, Classical.choice, Quot.sound}` | A proof that quietly *assumes* something strong proves less than it appears to. | F3 (axiom inflation) |

Note the word **elaborated**. Matching on the raw text is not enough: two different strings can denote
the same logical statement and, worse, the same string can mean different things in different contexts.
So the reference is a hash of the *elaborated* type (what the proof assistant actually built), which
is what the kernel really checked.

### The trap that makes this necessary: "compiled ≠ verified"

Here is a fact that surprises many newcomers: a Lean file containing `sorry` still **compiles**. The
compiler warns you, but exits successfully. So a naive pipeline that says "it built, therefore it's
proved" is *wrong*. ProofAgent separates the two words on purpose:

- **compiled** = Lean's compiler accepted the text (necessary, not sufficient).
- **verified** = the gate accepted a *statement-matched, axiom-audited* result that has also been
  **independently re-checked**.

That last clause matters because the trusted base should not be a single point of failure. In the
design, "verified" additionally requires an **independent re-checker** (a different implementation of
the kernel) to agree — so a bug or backdoor in one checker doesn't crown a false theorem.

---

## 4. Memory is the compounding engine (agents aren't)

The most counter-intuitive part of the design: **the leverage is in memory and verification, not in
the number of agents.**

Model it roughly, with the design's own symbols. Let `N` be the number of agents, `τ_a` the seconds an
agent spends per proposal, `h` the **acceptance rate** (the fraction of proposals that survive the gate
— often just a few percent for whole proofs), `τ_v` the seconds for one **full verification pass**
(elaborate + statement-match + axiom audit + re-check), and `d` the **dedup factor** (how many
proposals map to one genuinely new obligation after a memory lookup). Then:

```
proposal supply    S = N / τ_a             # agents make candidates
verifier capacity  V = (#pipelines) / τ_v  # the gate finishes candidates
verified rate      X_gross = min(S · h , V)   # agents supply; the verifier caps
net-new knowledge  X_use   = X_gross / d      # memory (dedup) divides the cost
```

Two consequences fall out immediately:

1. Look at `V`, the verifier term — it has **no `h` in it**. So once the system is verifier-bound, a
   *better agent* doesn't help; only *cheaper verification*, *more pipelines*, or *better caching*
   does. Adding agents past that point just lengthens the queue. This is the project's central bet,
   **B1**: *verification/memory throughput beats agent count.*
2. The **dedup factor `d`** — how often a "new" proposal is actually already known — divides the cost
   of *net-new* knowledge for free. So memory pays for itself: the more you've proved, the cheaper the
   next proof is, because you cache, reuse, and avoid re-deriving.

This is why the roadmap's investment order is **verifier → memory → retrieval → reasoning → curation →
agents**, with **agents last**. It isn't that agents are unimportant; it's that pouring compute into
agents before the verifier and memory are efficient is spending on the wrong bottleneck.

### Scale breadth, not depth

There's a second reason to prefer breadth. Within a *single* theorem, the proof search forms a
dependency graph (a **proof DAG**): early steps are needed by almost everything after them, so
parallelism is capped. The design's Phase-5 analysis estimates single-theorem speedup saturates around
**≈ 2–3×** no matter how many workers you add ("Amdahl's law for proofs"). So you scale by working on
**many problems at once** (a portfolio), not by throwing a thousand agents at one problem.

---

## 5. Fidelity: the risk people forget

Suppose everything above works perfectly — the proof is flawless, the gate is flawless. You can still
be *completely wrong*, because you may have **proved the wrong statement**.

Real-world example: a paper says "the controller is stable for **all** gains in the range," and the
formalizer drops the words "for all" (or the range condition) and proves a much weaker, true, and
useless theorem. The kernel is satisfied. The gate is satisfied. The result is still misleading.

The design calls this the **fidelity** problem and elevates it to a first-class risk: *fidelity before
proof*. Concretely, the system (in the full design) includes a **statement auditor** whose job is to
catch dropped hypotheses and silently weakened claims — and the hard rule that **a theorem about a
model is never sold as a fact about reality.** There's a whole **model-gap** accounting discipline for
this. (Failure modes F1–F3 are the *kernel* cheats; fidelity is the *human-meaning* cheat, and it's
arguably the scarier of the two.)

---

## 6. The ten invariants (the design's constitution)

Everything in ProofAgent is checked against ten non-negotiable rules. At T1 you only need the flavor;
T3 gives the full treatment.

1. **Trusted core / untrusted periphery** — the gate is the sole authority.
2. **Fidelity before proof** — a theorem about a model is not a fact about the world.
3. **Versioned, content-addressed artifacts with provenance** — every result knows where it came from.
4. **Scale-free architecture** — the same design works at 1 agent or 10⁹.
5. **Memory as a learning system** — memory is not storage; it's how the system improves.
6. **Open-ended in ideas, bounded in actions** — infinite creativity, tightly limited real-world effects.
7. **Calibrated honesty** — claims carry confidence and the evidence that would falsify them.
8. **Humans in the loop where it matters** — definition admission and real-world claims need a human.
9. **Cost-awareness** — verified theorems per dollar and per GPU-hour are tracked.
10. **Untrusted inputs** — everything from outside (papers, sensors, agents) is treated as hostile.

Plus three pack-level invariants: **verified guardrails**, **reversibility & least privilege**, and
**federated, portable trust**.

---

## 7. What's real today vs. designed

| Layer | Status |
|---|---|
| Trusted **gate** (banned tokens, statement hash, axiom allow-list), content-addressed append-only **memory**, the propose→verify→record **orchestrator**, a Lean **check** tool, a **goal-state** reader, and a tiny **tool server** | **Real, building, tested** — in [`skeleton/`](../../skeleton) on Lean 4.35.0 (4 test suites, all exit 0) |
| Elaboration-based statement matching, `#print axioms` wiring, the **independent re-checker**, interactive tactic stepping | **Designed** (Phase 9 §6) — the skeleton states plainly that it does *not* yet do these |
| Research-paper intake, multi-agent swarms, retrieval, curiosity, sensors, federation, months-long campaigns | **Designed, staged** across MVP → v1…v4 (Phase 6) |

The honest summary: **the trusted policy works and is tested; the scale system is designed and
honest about being unbuilt.**

---

## 8. Where to go next

- **Build and run it →** [Level T2 — Practitioner](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md) (real files, real commands).
- **The full argument →** [Level T3 — Expert](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md).
- **Look up a term →** [Glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).

---

### T1 in one paragraph

ProofAgent draws a hard **trust boundary**: a small, total, deterministic **gate** (reject banned
constructs; match the *elaborated* statement hash against a human-signed spec; audit axioms against a
tiny allow-list) is the only thing whose "yes" counts, and it alone may write to an **append-only,
content-addressed memory**. Untrusted, elastic agents only **propose**; a clean **propose → verify →
record** loop means rejections never poison memory. The leverage lives in **verification and memory
throughput and dedup**, not agent count (bet **B1**), and single-theorem parallelism is capped by the
**proof DAG** (≈2–3×), so scale is **breadth across problems**. Underpinning it all: fidelity is a
first-class risk (a theorem about a model isn't a fact about the world), and "compiled ≠ verified."
The walking skeleton implements and tests the trusted policy; the scaling system is designed, staged,
and explicitly unbuilt.
