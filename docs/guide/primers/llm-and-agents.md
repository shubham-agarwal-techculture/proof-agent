# LLMs and Agents

*Heard "AI proves theorems" and want to know what the AI actually does here? Start here.*

## Why this primer exists

ProofAgent is an **agentic** theorem-proving system, and it is built on one unusual decision: the AI is
*never* trusted. To see why that is the right decision — and not just a hedge — you need a plain-language
picture of what a large language model (LLM) is, why its strengths and weaknesses line up exactly with
"propose but don't judge," and what "agent" means in this project.

This primer supplies that picture and follows it through the propose → verify → record loop, memory
poisoning, and the project's central economic bet. It unblocks
[Level T1 — Intuition](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md)
and [Level T3 — Expert](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md).

---

## 1. What an LLM is (at a high level)

A **large language model** is a program trained on enormous amounts of text to predict, given some input,
what text plausibly comes next. When you "chat" with it, it is repeatedly predicting the next chunk of text,
then the next, and so on.

Three consequences of *how it is trained* matter here:

- It is **good at plausible continuation.** It has absorbed patterns from a huge corpus, so it is fluent, and
  often genuinely useful — including for Lean: it can draft a proof that *looks* right and frequently is.
- It has **no built-in truth check.** It is optimizing for plausibility, not correctness. A confident,
  well-formatted, wrong proof is entirely possible — even likely, on hard problems.
- It can be **wrong in ways that look right.** Unlike a random guess, its errors tend to be fluent and
  "reasonable-sounding," which makes them more dangerous, not less.

That is the whole reason this project exists: LLMs collapsed the cost of *proposing* and did **not** collapse
the cost of *being sure*.

---

## 2. Why LLMs propose but must not judge

Proposing and judging are different jobs with opposite requirements:

| Job | What it needs | Is an LLM good at it? |
|---|---|---|
| **Propose** a proof | fluency, breadth, pattern-matching across many proofs | **Yes** — cheap, elastic, creative |
| **Judge** a proof | a definite, checkable rule; no persuasion | **No** — no truth check, and it can be talked into anything |

A judge that can be *convinced* is not a judge — and an LLM can be convinced by a confident-sounding
argument. So the project never asks the model "is this correct?" It asks the model only to *produce
candidates*, and routes every candidate to a checker that cannot be persuaded: the Lean **kernel** and the
project's **gate**.

This is the slogan, made concrete:

> **"Untrusted agents propose; the trusted kernel disposes."**

"Disposes" is the key word: the kernel's yes/no is final, and it does not care how impressive the model
sounds.

---

## 3. What "agent" means in this project

Here, an **agent** is any **untrusted proposer** — most often an LLM, but it could be a search routine or a
heuristic. Agents are *assumed hostile*: they may be wrong, may be sloppy, and may even try to cheat.

An agent's output is a **`Claim`** — an untrusted proposal. From
[Spec.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Spec.lean):

```lean
structure Claim where
  specHash    : String   -- the statement the agent *claims* it proved
  producer    : String   -- who produced it (provenance)
  proofText   : String   -- the Lean source of the proposed proof
  derivesFrom : List String := []   -- memory artifacts it cites as premises
```

Two fields encode the design's distrust directly:

- `specHash` is what the agent *claims* to have proved — the gate will check it against the human-signed
  spec's hash, so the agent cannot quietly prove a different statement.
- `derivesFrom` records which stored results the proposal used — so if a bad premise ever contaminates
  conclusions, you can trace which. (This is *provenance*, invariant #3.)

Notice what is **absent**: no confidence score, no "the model says this is correct." The agent supplies a
candidate and a name; it gets no vote.

---

## 4. The loop: propose → verify → record

The runtime is three steps, repeated. The skeleton implements all three in
[Orchestrator.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Orchestrator.lean):

1. **Propose.** An untrusted agent emits a `Claim`.
2. **Verify.** The trusted **gate** returns exactly one verdict: `verified` or `rejected reason`. The gate is
   **total and deterministic** — for *every* input there is a verdict, with no "maybe," no exception, and no
   path around it.
3. **Record.** **Only on `verified`** is an entry appended to memory. On any rejection, **memory is
   untouched**.

The gate itself ([VerifierGate.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean))
does three things in a fixed order: reject banned constructs (`sorry`, `native_decide`, `unsafe`,
`implemented_by`, `partial`, `skipKernelTC`); check that the proved statement's hash equals the signed spec's
hash; and audit the axioms used against the allow-list `{propext, Classical.choice, Quot.sound}`.

The division of labour is deliberate and is worth stating plainly: **compilation is the compiler's job,
verification is the gate's job.** A `sorry` proof *compiles* (Lean warns, then exits successfully). Only the
gate rejects it. This is assumption **A1**, "compiled ≠ verified."

---

## 5. Memory poisoning (F7): why rejections never enter verified memory

Suppose memory were allowed to hold anything an agent submitted. Then a stream of plausible-but-wrong
results would accumulate, later proposals would *cite them as premises*, and the system would slowly build
false proofs on top of false foundations — each step looking locally fine. The store would become a
liability: a well of confident nonsense that the next agent happily drinks from.

This is failure mode **F7, memory poisoning**, and it is why the design has one hard rule:

> **Rejections never enter verified memory. Ever.**

The skeleton enforces it *structurally*: in `Orchestrator.step` and `verifyAndRecord`, there is simply **no
code path** from a rejection to a memory write. You do not have to remember to enforce the rule; you cannot
break it without rewriting the control flow. Anything that has not passed re-check lives as a `candidate`
(quarantined), never as `verified`.

This is the answer to "why not let agents write to memory?" — because a storing agent is a *learning* system,
and a learning system fed poisoned examples learns the wrong thing, fluently and at scale.

---

## 6. The bet: verification and memory throughput, not agent count

The most counter-intuitive claim in the project is bet **B1**:

> **Verification/memory throughput beats agent count.**

The intuition: an agent makes candidates, but the gate *finishes* them. Rate of verified output is roughly
`min(agent supply, verifier capacity)` — so once the verifier is the bottleneck, **a better agent does not
help**. Its extra proposals just join the queue. What helps is *cheaper verification*, *more verification
pipelines*, or *better caching* (memory that recognizes a once-proved result so it is never re-proved).

Two further facts push in the same direction:

- **Dedup divides the cost of new knowledge for free.** The more you have proved, the more likely a "new"
  proposal is already known — so memory pays for itself.
- **Single-theorem parallelism is capped.** Within one problem, early proof steps are needed by everything
  after them, so throwing workers at *one* theorem saturates quickly (the design's proof-DAG ceiling,
  estimated at roughly 2–3×). You scale by working on **many problems at once** — breadth, not depth.

So the investment order is **verifier → memory → retrieval → reasoning → curation → agents**, with agents
*last*. Not because agents don't matter, but because pouring compute into agents before the verifier and
memory are efficient is spending on the wrong bottleneck.

One honesty note: B1 is a **bet**, paired with the experiment that could kill it (sweep agent count at a
fixed verifier budget and look for the knee). It is stated as falsifiable, not as established fact.

---

## 7. The tool layer in miniature: `CheckServer.lean`

If "agentic" sounds abstract, the skeleton shows the concrete shape. Agents need *tools* they can call —
"compile this," "read the goals of that." In the full design this is an **MCP**-style interface (agent ↔
tool). The skeleton's
[CheckServer.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean)
is that shape in miniature `[exists today]`: **one long-lived process, one JSON request per line, one JSON
response per line.** Run with `lake exe checkServer`, it echoes a request id and dispatches on an `op`
field:

```text
{"id":"r1","op":"check","source":"theorem a : 1 + 1 = 2 := rfl"}
  → {"id":"r1","ok":true,"diagnostics":[]}

{"id":"r2","op":"goals","statement":"1 + 1 = 2"}
  → {"id":"r2","ok":true,"goals":["⊢ 1 + 1 = 2"],"raw":"unsolved goals\n⊢ 1 + 1 = 2"}

garbage
  → {"ok":false,"error":"bad request"}
```

Why this matters for the trust story: these tools are **untrusted helpers**. `check` reports *compilation*
(and a `sorry` proof will compile — `ok: true`), and `goals` reads the initial goal, which is *not* a claim
of truth (a **false** statement still yields a goal). Neither tool can write to memory or crown a result
`verified`. They exist to give agents good information and a fast compile oracle — and then the gate, not
the tool, decides.

That is the whole pattern: **big, helpful, untrusted tools and agents; small, silent, trusted gate.**

---

## Common misconceptions

- **"The AI can check its own work, so we can trust its output."** No. An LLM has no truth check and can be
  talked into anything, so it is never the judge. Only the kernel/gate decides.
- **"More agents always means more theorems."** Only until the verifier becomes the bottleneck; past that
  point extra agents just lengthen the queue (bet **B1**).
- **"Once a candidate compiles, it's proved."** No — a `sorry` proof compiles with only a warning (A1); the
  gate is what rejects it.
- **"A result was checked, so it's safe to store."** Not from an untrusted source: only gate-accepted,
  `verified` results enter memory, precisely to prevent **F7** memory poisoning.

---

## Where to go next

- **Mechanisms and the reasons behind them →** [Level T1 — Intuition](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **Architecture, economics, and bets in full →** [Level T3 — Expert](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md).
- **Build and run the loop →** [Level T2 — Practitioner](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md).
- **What a proof even is →** [Logic and Proofs](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/logic-and-proofs.md).
- **Any term →** [Glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
