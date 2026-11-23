# For Undergraduates

*For undergraduates in mathematics, computer science, or philosophy who have seen proofs and a little
logic, and want to know how formal verification and AI actually fit together here.*

## In one line

ProofAgent is a design for an **agentic theorem prover on Lean 4** where untrusted AI "agents" propose
proofs and a small trusted kernel — the gate — alone decides what counts, so you can watch formal
verification, trust boundaries, and honest engineering at a scale you can actually read.

## Why this matters to you

You have already met the pieces separately: a **proof** as a chain of justified steps, a **formal
language** (like Lean) where every step is checkable, and a **kernel** as the tiny engine that checks
them. ProofAgent's twist is to put an AI *around* that kernel and then be extremely careful about where
the trust goes. This is the "untrusted agents propose; the trusted kernel disposes" rule — the same
shape as a compiler front-end (untrusted, clever) feeding a checker (small, trusted). If you have
studied programming languages, type systems, or security, the pattern will feel familiar, and the
applications here are fresh.

Two lessons are worth carrying into your own work. First, **compiled ≠ verified**: a Lean file with the
cheat word `sorry` still *builds*, so "it compiled" is never "it's proved." Second, the design turns
each famous way of cheating into an explicit rule the gate enforces — no `sorry` or other kernel-bypass
constructs, no proving a *different* statement (caught by hashing the **elaborated** type, not the
text), and no smuggling in **axioms** beyond a tiny allow-list `{propext, Classical.choice,
Quot.sound}`. Each rule closes a specific hole; that "rule ↔ hole it closes" style of reasoning is
exactly what your proof courses reward.

The counter-intuitive claim is about *leverage*. You might assume the key to an AI prover is the
smartest possible agent. The design argues the opposite: once a system is *verifier-bound*, adding more
idea-generators just lengthens the queue, and the real wins come from **cheaper verification** and a
**good memory** (content-addressed, deduped) that makes the next proof cheaper by reusing what was
already proved. The design even names this as its central bet, **B1** — *verification/memory throughput
beats agent count* — and pairs it with the experiment that could falsify it.

There is a second, subtler ceiling you will appreciate if you have met Amdahl's law. Within a *single*
theorem, the proof forms a dependency graph; early steps are needed by almost everything after them, so
parallelism saturates (the design estimates ≈ 2–3× single-theorem speedup). The conclusion is to scale
**breadth across many problems**, not depth on one — a design principle stated in one line: *scale
breadth, not depth*.

Here is the whole idea compressed into a small table — read it as "concept → the one thing that
matters":

| Concept | The one thing that matters |
|---|---|
| Trust boundary | only the gate is trusted; everything clever is untrusted |
| The gate's rules | no banned constructs · statement-hash match · axiom allow-list |
| Compiled vs. verified | a `sorry` proof *builds*; the gate is what rejects it |
| Memory | append-only, content-addressed, deduped; rejections never enter |
| Leverage | verifier throughput + memory, not agent count |
| Honesty | every claim carries a status and (in the design) a falsifying experiment |

You do not need to have used Lean. You need curiosity and tolerance for one idea that takes a moment:
**the leverage is not in more agents, but in verification and memory.**

## What to take away

- **A hard trust boundary, made concrete.** Only the gate is trusted; agents, planning, and tools are not. If you can read a little Lean, the gate is small enough to read ([`VerifierGate.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean)).
- **"Compiled ≠ verified" is a first-class rule, not a footnote.** The compiler accepts a `sorry` proof with only a warning; the gate is what rejects it. This is labelled **A1** in the design.
- **Statement matching is structural, not textual.** The gate compares the hash of the *elaborated* goal type to the human-signed statement, which stops an agent proving an easier lookalike ("statement drift", **F2**).
- **Rejections never enter verified memory.** This rule, **F7**, structurally prevents "memory poisoning" — bad results can't quietly become premises for later proofs.
- **Some parts are real, some are only designed.** The gate, the append-only content-addressed memory, the propose→verify→record loop, and three tools are **built and tested** `[exists today]` (four test suites pass on Lean 4.35.0). Independent re-checkers, agents, retrieval, and large-scale swarms are **designed, not built** `[near-term]`/`[frontier]`.
- **A gentle on-ramp to research taste.** The design states falsifiable bets and the experiments that would kill them — a habit worth copying in any project you write up.

## Getting a taste of it yourself

You can read and run the real thing in an afternoon, with no Mathlib download.

- **Read the gate first.** `ProofAgent/VerifierGate.lean` is the whole trusted policy and is short: a banned-token scan, a statement-hash comparison, and an axiom allow-list.
- **Build and test.** Run `lake build`, then `lake env lean tests/adversarial.lean` — six cheat claims must be rejected and one honest claim accepted.
- **Probe the tools.** `lake exe checkServer` answers line-delimited JSON requests, with `op` = `check` or `goals`; both are built on `lean --json`.
- **Notice what you are *not* seeing.** There are no agents and no retrieval here, and "verified" means the gate said yes — not that a second, independent kernel agreed. Elaborated-`Expr` matching, `#print axioms` wiring, and the independent re-checker are designed, not built.
- **Then go hands-on.** The exact commands and file map are in the practitioner tier.

## How the pieces fit together

The whole trusted path is a chain you can trace:

1. **`ProblemSpec`** — the *signed statement*: what the human asked for, identified by a hash of its elaborated type.
2. **`Claim`** — an *untrusted proposal*: a proof text, the hash the agent *claims* it proved, a producer id, and what it relied on.
3. **Gate** — rejects banned constructs, compares the proved hash to the signed hash, and audits the axioms used against the allow-list; returns `verified` or `rejected reason`.
4. **Memory** — an append-only, content-addressed, deduped store that records **only** `verified` entries.

Read the files in that order and the "trusted core / untrusted periphery" boundary becomes obvious:
steps 1 and 2 are untrusted artifacts, step 3 is the single trusted point, and step 4 is the durable
consequence.

## A reading order (if you have an afternoon)

`Spec.lean` → `VerifierGate.lean` (twice) → `Memory.lean` → `Orchestrator.lean` → `Tools/` → the
`tests/` suites. The gate is the one file you should understand completely; everything else is plumbing
that *surrounds* it.

## Where the design is (honestly) unfinished

If you go looking for the parts of the pitch that sound most exciting, here is where the line sits. The
following are **designed, not built**, and the project says so itself:

- **Independent re-checking.** The design wants a result confirmed by a *second*, independent kernel. In
  the skeleton, "verified" only means the gate accepted it — no second kernel has agreed. The design even
  names the risk (**F4**) that re-checkers could share an export path and fail *together*, so agreement
  counts would be misleading.
- **Elaborated-`Expr` matching.** The gate is meant to compare the elaborated goal type, not raw text;
  that wiring is designed, and the skeleton uses a statement hash as the matching key instead.
- **Agents, retrieval, curiosity, sensors, federation.** The entire "agentic" layer is on paper.
- **Interactive tactic stepping.** Goal read-back here is one-shot; step-by-step checking is a stated
  future goal.

Reading the design with that split in mind is itself good training: the propose→verify→record loop is a
small, honest thing you can trace end to end, and everything loud sits outside it.

## If you remember only two sentences

1. *Untrusted agents propose; the trusted kernel disposes.* Everything clever stays off the trust path.
2. *Compiled ≠ verified.* A `sorry` proof builds; only the trusted check says otherwise.

## Where to go next

- **The intuition level (mechanisms + reasons):** [t1-intuition.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **The absolute-beginner level, if any term is shaky:** [t0-high-schooler.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md).
- **If you want to build and run it:** [t2-practitioner.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md) and the [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md).
- **Definitions, plainly and precisely:** [glossary.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
- **The full map of the guide:** [README.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/README.md).
