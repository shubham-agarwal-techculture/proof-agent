# For Funders

*For decision-makers who decide whether to fund, staff, or partner on ProofAgent.*

## In one line

ProofAgent is a design plus a small, working skeleton for an **agentic theorem-proving system on Lean
4** whose central bet is that cheap AI proposals are worthless without a small, trusted checker and a
compounding memory — so the money goes into verification and memory, not into more agents.

## Why this matters to you

The pitch separates two things most projects blur: what is **built** and what is **designed**. Built and
tested today: the trusted core (a gate that rejects cheating proofs and accepts only honest,
on-statement, allow-listed-axiom results), an append-only content-addressed memory, the
propose→verify→record loop, and three tools. `lake build` succeeds and four test suites pass. Designed
but **not built**: agents, retrieval, curiosity, sensors, federation, and large-scale swarms. Value the
first; fund the second.

The investment thesis has a sharp, unglamorous shape. Foundation models collapsed the cost of
*proposing* ideas; they did not collapse the cost of *checking*, *stating correctly*, or *remembering*.
The design's central claim (**bet B1**) is that throughput is bounded by the verifier pipeline and
memory, not by agent count. That implies a specific spending order — **verifier → memory → retrieval →
reasoning → curation → agents (last)**.

The biggest danger is not "the AI isn't smart enough"; it is **fidelity** — proving a statement that
*looks* like the one you meant but isn't (a dropped condition, a changed quantifier). The design treats
this as first-class (`fidelity before proof`) and even warns that paper-intake fidelity may **double
the MVP timeline**. Most competing narratives do not budget for this risk.

What de-risks it is the discipline. Every capability carries a maturity label (`[exists today]`,
`[near-term]`, `[frontier]`, `[speculative]`); every major claim is paired with a **falsifiable**
experiment; and the roadmap has explicit exit criteria plus a **kill criterion** — if the gate can't
reject *every* known cheat class, stop and fix the gate, no exceptions.

The returns, if real, compound. Verified results are content-addressed and reused, so each new theorem
should get cheaper; bet **B3** says cost-per-lemma falls as memory grows, then may rise again once dedup
saturates (a U-shaped curve). That is the number to watch — and the thing that would make memory a
durable moat rather than a cost centre.

Finally, cost is reported in **US$ per verified theorem** and **GPU-seconds per verified lemma** — a
funder's language, not a researcher's — because cheap proposals are not the product. Figures in the
design are labelled back-of-envelope ranges with assumptions, not measurements; the scale system does
not exist yet.

## What to take away

- **Built vs. designed is stated plainly.** The trusted gate, memory, orchestrator, and tools are `[exists today]` and tested; agents, retrieval, curiosity, sensors, and federation are designed and staged `[near-term]`–`[speculative]`. Price the first, fund the second.
- **The bet is checkable.** B1 (verification/memory beats agent count) comes with a falsifying experiment (an agent-count sweep at fixed verifier budget); the 90-day MVP has measurable exits and an explicit kill criterion.
- **The spending order is unusual and defensible.** Agents come *last*; value concentrates in verification throughput and a compounding memory where dedup makes each new theorem cheaper.
- **The headline risk is fidelity, not capability.** The design names it and budgets for it; most competing narratives do not.
- **Returns compound, if real.** Watch the dedup/cost curve (B3): cost per lemma should fall as memory grows, then may turn upward once dedup saturates.
- **No numbers are oversold.** Figures are back-of-envelope ranges with assumptions, not measurements, and the scale system is unbuilt. Treat it as a well-argued thesis with a working proof-of-policy.

## What you are funding, stage by stage

| Stage | Horizon | What it delivers | Maturity |
|---|---|---|---|
| MVP | 0–3 months | one problem, honestly proved; instrumentation for demand, `V`, `d`, `p` | `[near-term]`; skeleton `[exists today]` |
| v1 | 3–9 months | days-long autonomy; paper→Lean intake; bounded per-problem swarm; semantic memory | `[near-term]` |
| v2 | 9–18 months | research partner: programs, longer campaigns | `[frontier]` |
| v3 | 18–30 months | sensors, open programs, discovery | `[frontier]` |
| v4 | 30–42+ months | campaigns, federation, human-gated actuators | `[speculative]` |

## Questions to ask before funding

- **What is built today, and what is only designed?** Expect a crisp split: a small, tested gate + memory + tools versus an unbuilt scale system.
- **What is the falsifying experiment for the central bet?** For B1, an agent-count sweep at a fixed verifier budget. If there is no experiment, there is no bet.
- **What is the kill criterion?** Here it is explicit: if the gate cannot reject *every* known cheat class, stop and fix the gate.
- **What is the unit of value?** Not "ideas generated," but **verified theorems** — reported as US$/verified theorem and GPU-seconds/verified lemma.
- **Where is the compounding?** In memory: dedup should make each new theorem cheaper (watch the U-shaped cost curve, B3).
- **What is the biggest risk?** Fidelity — proving the wrong-but-lookalike statement — which this design budgets for and most pitch decks ignore.

## What would change the thesis

Three results would materially change the case: if more agents *do* keep paying off at fixed verifier
budget (B1 false); if compounding memory flattens or inverts early (B3 false); or if fidelity at paper
intake proves intractable — which the design itself warns could **double the MVP timeline**. A funder
should want these measured, not assumed.

## How to read the numbers in this design

Every figure here is a **range with stated assumptions**, not a measurement, and the design says so. A
funder should sort them into three buckets before taking any number seriously:

- **What is measured:** that the skeleton builds and four test suites pass on a pinned toolchain. Small
  but real engineering fact — and the only hard number on the table.
- **What is estimated:** throughput, cost per lemma, and the memory/dedup curve. These are
  back-of-envelope models whose stated purpose is to be *falsified* by the MVP's instrumentation.
- **What does not exist:** any benchmark for an agentic prover, because that system is unbuilt. There is
  nothing to compare against yet, and the design does not pretend otherwise.

The practical move is therefore to fund the **measurement**, not the claim: the first paid outcome is a
dashboard reporting demand, `V`, `d`, and `p`.

## Two ways this can still be a good bet

The thesis is contrarian, which cuts both ways. It is attractive if either of these holds — and the MVP
is designed to tell you quickly:

1. **The verifier really is the bottleneck.** If so, an agent-count race burns money, and the team that
   owns cheap verification plus compounding memory holds a durable advantage.
2. **Memory really compounds.** If each verified theorem makes the next cheaper (B3), value accrues to
   whoever accumulates the most *verified* results first — a land-grab in checked truth, not compute.

## Where to go next

- **The intuition level:** [t1-intuition.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **The one-page case, with bets and decision criteria:** [phase-8-decision-memo.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-8-decision-memo.md).
- **The full argument (economics, roadmap, failure modes):** [t3-expert.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md).
- **What could go wrong (the pre-mortem):** [phase-7-red-team.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md).
- **The running code:** [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md).
- **Definitions:** [glossary.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
