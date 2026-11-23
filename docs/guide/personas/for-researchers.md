# For Researchers

*For researchers in formal methods, automated reasoning, or machine-learning systems who want the
thesis, the threat model, the economics, and — most usefully — the open problems.*

## In one line

ProofAgent is a design (`[exists today]` only as a small trusted-core skeleton) for agentic Lean 4
theorem proving whose central claim is that the binding constraint is **verified truth** — checking,
stating correctly, and remembering — not ideation, so it invests in a minimal trusted core plus
compounding memory and treats agents as a cheap, elastic, *untrusted* frontier.

## Why this matters to you

The design's thesis is deliberately falsifiable: **bet B1** — at fixed verifier budget, scaling agent
count `N` yields a knee in time-to-solve and cost-per-lemma well before 10³ on a single theorem,
because throughput is bounded by the **verifier pipeline** and by **memory** (cache/dedup/retrieval),
not by `N`. Three independent ceilings are offered as the mechanism: the **proof-DAG Amdahl ceiling**
(~2–3× single-theorem speedup), verifier throughput, and retrieval/dedup decay at portfolio scale
(**F16**). Whether these hold is an empirical question the design says it *cannot yet answer* — the
system does not exist — and it commits to instrumenting exactly four numbers (demand rate, verifier
capacity `V`, dedup factor `d`, retrieval precision `p`) precisely so the claims become falsifiable.

The threat model is the paper's real contribution. The gate (**L0**) combines a statement matcher,
kernel acceptance, an **independent re-checker**, an axiom allow-list, a hygiene scan, and resource
limits; failure modes **F1–F19** enumerate the attacks, each with mechanism, mitigation, early-warning
signal, and a cheap probe. They are grouped by the invariant they attack:

| Group | Attacks on | Examples |
|---|---|---|
| A | the trusted core (inv. #1) | F1 kernel bypass, F2 statement drift, F3 axiom inflation |
| B | memory & learning (inv. #3) | F7 memory poisoning, F8 stale dead-end register |
| C+ | coordination/scale, human meaning, safety | fidelity/model-gap, actuation, retrieval decay (F16) |

Crucially, the design is honest about the *weakest* links: independent-rechecker *independence*
(**F4** — nanoda/con-leche/lean4lean may share an export path and fail *correlated*), fidelity at paper
intake (**B2**), and retrieval/dedup decay (**B3**) are called out as frontier work, not solved. That
kind of self-dissection is what makes a design worth attacking.

What is actually running today is narrow but real: a **total, deterministic gate** (reject banned
tokens; match the elaborated statement hash; audit axioms against `{propext, Classical.choice,
Quot.sound}`), an **append-only, content-addressed, deduped** memory, a propose→verify→record loop that
structurally prevents **F7** (rejections never enter verified memory), and three tools built on
`lean --json`. Four test suites pass on `leanprover/lean4:v4.35.0`; there is **no Mathlib dependency by
design**, to keep the trusted base small and auditable. Elaborated-`Expr` matching, `#print axioms`
wiring, the independent re-checker, and interactive tactic stepping are explicitly absent (designed
only).

The economic core is stated in symbols but *flagged as back-of-envelope with assumptions, not
measured*. With supply `S = N/τ_a` and verifier capacity `V = (#pipelines)/τ_v`, gross completions are
`min(S·h, V)` and net-new knowledge divides by the dedup factor `d`. The load-bearing observation: the
verifier term `V` contains no acceptance rate `h`, so better agents cannot move it — only cheaper
verification, more pipelines, or better caching can. The investment order that follows is unusual and
explicit: **verifier → memory → retrieval → reasoning → curation → agents (last)**.

Two more things to note before you judge it. First, **fidelity is elevated above proof**: *a theorem
about a model is never a fact about reality*, and the design carries explicit model-gap accounting and
a statement auditor whose own check is gate-verified (toy instances, non-vacuity, back-translation,
adversarial falsification). Second, cost is reported in **US$ per verified theorem** and **GPU-seconds
per verified lemma**, because cheap proposals are not the product — an accounting stance worth
importing into your own evaluations.

## What to take away

- **The thesis is falsifiable, not rhetorical.** B1 (verification/memory beats agent count), B2 (fidelity is the real risk), B3 (compounding memory is super-linear, then a U-shaped turn) each come with the experiment that could kill them — see the [red-team](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md) and the [decision memo](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-8-decision-memo.md).
- **Ten invariants are the constitution,** including *trusted core / untrusted periphery*, *fidelity before proof*, *content-addressed artifacts with provenance*, *memory as a learning system*, and *calibrated honesty*.
- **F1–F19 is a usable pre-mortem.** It is written "after a year of shipping," grouped by the invariant each attack targets, with mitigations and probes — including the meta-risk that the mitigations themselves fail.
- **The open problems are named openly.** Correlated re-checker bugs (F4), autoformalizing a research paper without dropping hypotheses (B2), and dedup/retrieval decay at scale (B3) are `[frontier]`/unmeasured, and the design says so.
- **One thing genuinely built, and modest.** The trusted gate, memory store, orchestrator, and tools are `[exists today]` and tested; "verified" in the skeleton means "the gate said yes," **not** "a second independent kernel agreed." Do not over-read it.
- **Fidelity is elevated above proof.** *A theorem about a model is never a fact about reality*; the design carries explicit model-gap accounting and a statement auditor (whose own check is gate-verified on toy instances, non-vacuity, back-translation, adversarial falsification).

## The four numbers to instrument

The design commits to instrumenting exactly four quantities, because without them nothing in it is
falsifiable:

| Number | Meaning | Why it decides the argument |
|---|---|---|
| demand rate | proposals per second from the agents (`S = N/τ_a`) | tells you whether agents, not the verifier, are ever the limit |
| verifier capacity `V` | full verification passes per second (`#pipelines/τ_v`) | the outer scaler; it has no acceptance-rate term, so better agents cannot move it |
| dedup factor `d` | raw proposals ÷ unique obligations after a memory lookup | how much the compounding memory actually saves |
| retrieval precision `p` | fraction of retrieved premises that are relevant | whether memory stays an asset or decays into a cost at scale |

If you build or evaluate anything here, these four — and the cost units US$/verified theorem and
GPU-seconds/verified lemma — are where to start, because they turn the bets into measurements.

## A suggested attack plan

If you want to test the thesis, the design says where to push:

1. **Falsify B1** with an agent-count sweep at fixed verifier budget; find the knee in time-to-solve and cost/lemma, or report its honest absence.
2. **Falsify F4** by diversifying the *export path and elaboration inputs* across re-checkers and measuring *correlated* failures, not just agreement counts.
3. **Falsify B2** with a real paper → Lean intake where a dropped hypothesis is caught by the statement auditor — or isn't.
4. **Falsify B3** by measuring cost per lemma versus dedup factor `d` and looking for the U-shaped turn.

Each is designed to be affordable at early scale, which is the point of stating them.

## What would count as success

The design's own MVP exit criteria make a useful benchmark: a handful of nontrivial lemmas
independently re-checked on a pinned toolchain; every adversarial test rejected and the honest case
accepted; dashboards reporting all four numbers (demand, `V`, `d`, `p`); and a statement-mismatch attack
that fails. The kill criterion is equally explicit: if the gate cannot reject *every* known cheat class,
stop and fix the gate — no exceptions.

## Two habits to borrow

Even if you never build this, two practices are portable and cheap to adopt in your own evaluations:

- **Report cost in the unit you actually care about.** Here that is **US$/verified theorem** and
  **GPU-seconds/verified lemma**, not "ideas generated" — cheap proposals are not the product, and the
  accounting stance follows from the thesis.
- **Attach the falsifying experiment to each claim.** The design pairs every load-bearing statement (B1,
  B2, B3) with the measurement that could kill it, instead of a confidence adjective. That is precisely
  what makes the claims reviewable — and refutable — by someone else.

## Where to go next

- **The intuition level:** [t1-intuition.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **The full argument (architecture, economics, bets, failure modes):** [t3-expert.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md).
- **The pre-mortem:** [phase-7-red-team.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md). **The one-page case:** [phase-8-decision-memo.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-8-decision-memo.md).
- **The code:** [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md).
- **Definitions, plainly and precisely:** [glossary.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
