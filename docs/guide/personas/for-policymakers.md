# For Policymakers

*For people shaping governance, trust, and safety around AI systems, who want a concrete example of a
safety-by-architecture pattern.*

## In one line

ProofAgent is a design — plus a small, working "walking skeleton" — for an AI system that proves
theorems in Lean 4 by separating untrusted proposal-generators from a small, trusted checker, and it is
a concrete illustration of governance-shaped engineering: minimal trusted core, humans in the loop, and
explicit labels for what is and isn't real.

## Why this matters to you

The interesting governance story here is architectural, not political. ProofAgent is built on a
**minimal trusted core**: a small, auditable checker is the only component whose verdict counts, and
every powerful, fast, or creative part is *untrusted*. The design's own framing — *untrusted agents
propose; the trusted kernel disposes* — is a template for systems whose correctness must not depend on
the trustworthiness of their most complex parts.

The system is deliberately **honest about maturity**. It labels capabilities `[exists today]`,
`[near-term]`, `[frontier]`, or `[speculative]`, and it distinguishes what is **built and tested** (a
small trusted gate, an append-only memory, and three tools; four test suites pass on Lean 4.35.0) from
what is only **designed** (the large agentic system). For oversight, that labelling discipline is as
important as the technology itself.

**Humans in the loop where it matters** is an explicit invariant: admitting definitions to a shared
library, and any safety-critical claim about the real world, require human sign-off, because automation
cannot own meaning. The design also insists that *a theorem about a model is never a fact about
reality* — the "fidelity" problem — and carries explicit model-gap accounting.

Two safety-shaped invariants are worth noting. First, **open-ended in ideas, bounded in actions**: the
system may generate ideas without limit, but its real-world effects are tightly limited, with verified
guardrails, reversibility, and least privilege. Second, **federated, portable trust**: a verification
result is meant to be checkable by others *without trusting the producer*.

The design also adopts **calibrated honesty** as an invariant — claims carry a confidence and the
experiment that would falsify them — and it treats **all external inputs as hostile** by default:
papers, data, sensors, and agents alike. Those are exactly the properties regulators tend to ask for
after an incident; here they are stated as design constraints from the start.

One caution for any policy discussion: the scale system is **designed, not built**, and the design
reports no benchmark results. It is a well-argued architecture with a working proof-of-policy, not a
deployed capability. Regulation should track its forward-looking claims as *plans*, not as present
systems.

## What to take away

- **The trusted-core pattern is the governance hook.** A tiny auditable checker as the sole authority, with everything clever left untrusted, is a reusable idea for trustworthy automation.
- **Maturity labelling: built vs. designed attached to every claim.** The project keeps them distinct — a discipline worth expecting of any AI deployment.
- **Humans in the loop, by invariant.** Definition admission and real-world/safety-critical claims require human sign-off; automation cannot own meaning.
- **Open-ended ideas, bounded and reversible actions.** Creativity is unlimited; real-world effects are tightly limited, with verified guardrails and least privilege.
- **Federated, portable trust.** Verification results are designed to be checkable by third parties without trusting the producing system.
- **Treat the scale system as planned, not present.** It is unbuilt and reports no benchmarks; the design says so plainly.

## Governance properties worth knowing

| Design property | What it means |
|---|---|
| Trusted core / untrusted periphery | a small auditable checker is the sole authority; powerful components stay untrusted |
| Humans in the loop where it matters | definition admission and safety-critical real-world claims need human sign-off |
| Calibrated honesty | claims carry a status (and, in the design, a falsifying experiment) |
| Open-ended ideas, bounded actions | unlimited idea generation; tightly limited, reversible real-world effects |
| Federated, portable trust | results checkable by others without trusting the producer |
| Untrusted inputs | papers, data, sensors, and agents are treated as hostile by default |

## Questions this design answers for oversight

- **What is trusted, and how big is it?** A small, auditable core — the whole point is that a person can read it.
- **Can it do harm freely?** No: "open-ended in ideas, bounded in actions," with verified guardrails, reversibility, and least privilege.
- **Who is accountable for meaning?** Humans — for admitting definitions and for safety-critical real-world claims.
- **How do you know what is real?** Maturity labels (`[exists today]` … `[speculative]`) attached to every claim.
- **What is the failure model?** A written pre-mortem — attacks on the trusted core, on memory, and on meaning — each with mitigations and probes.

## Where the design is silent (limits)

To avoid over-claiming: the scale system is **designed, not built**; there are **no benchmark results**;
and "verified" in the skeleton means the trusted gate accepted a result, **not** that a second,
independent kernel agreed. The design's own open problems — re-checker independence, fidelity at intake,
and memory decay at scale — are unresolved. Oversight should treat the forward-looking parts as *plans*,
not present capability.

## A worked oversight scenario

Imagine a system like this later being used to certify something that matters — a safety property, a
financial guarantee. The design's invariants suggest what an overseer would look for:

- **Is the trusted core still small and auditable?** If the part that "counts" has quietly grown, the
  guarantee shrinks with it.
- **Are external inputs still treated as hostile?** Papers, data, and sensors feeding the system should be
  assumed adversarial, not trusted.
- **Did a human sign off where meaning was at stake?** Definition admission and real-world claims are the
  points where accountability cannot be delegated to a checker.
- **Can a third party re-check a result without trusting the producer?** Portable, federated trust is what
  makes verification useful to a regulator rather than only to its author.

## What not to conclude

- **Not "an AI that proves theorems unsupervised."** The design's bet is about trustworthy *checking*, and
  the scale system is unbuilt.
- **Not "it replaces expert judgement."** Humans remain the owners of meaning; automation is bounded and
  reversible by construction.
- **Not "it is a live capability to regulate."** It is a well-argued architecture plus a working
  proof-of-policy; forward-looking claims are plans, and the design labels them as such.

## Where to go next

- **The intuition level:** [t1-intuition.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **The one-page case (bets and decision criteria):** [phase-8-decision-memo.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-8-decision-memo.md).
- **The full argument (invariants, failure modes, safety):** [t3-expert.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md).
- **What could go wrong (the pre-mortem):** [phase-7-red-team.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md).
- **Definitions:** [glossary.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
- **The overall map of this guide:** [README.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/README.md).
