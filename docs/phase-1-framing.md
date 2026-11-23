# Phase 1 — Frame: Assumptions, Defaults, and the Five Leverage Questions

## 1. Parameter assumptions (every blank in the brief's §3 is filled)

The brief said: *"Fill in what you know. For anything left blank, choose a sensible default and state
it explicitly."* All were blank. Our assumptions, each with the reason it protects the design:

| # | Parameter | Assumed default | Why this default |
|---|---|---|---|
| P1 | Primary users | **Research mathematicians (primary)**; scientists/engineers (secondary); graded human oversight throughout, not "fully autonomous" | Highest-value, Mathlib-dense entry point; keeps human gates where the brief's invariant #8 requires them |
| P2 | Initial domains | **Combinatorics & number theory → analysis/probability → algorithms/complexity → control theory → program verification** | Matches Mathlib density and gives a natural ramp from "library-rich" to "library-thin" (tests §5.1 library-extension strategy) |
| P3 | Compute & budget | **v0–v1: one 8-GPU node; v3–v4: cloud-burst to ≥1,000 GPUs; ~US$50k/month** (stated assumption) | MVP must be affordable; the scale study (Phase 5) is the deliverable, not the spend |
| P4 | Team & timeline | **4 engineers + 1 Lean/Mathlib expert; ~18 months to v2** (stated) | Small team forces the "trusted core, untrusted periphery" split to be real, not aspirational |
| P5 | Deployment & licensing | **Hybrid** — cloud burst for ephemeral untrusted agents; **isolated/on-prem trusted core**. Lean 4 + Mathlib = Apache-2.0 (open). Models mixed. | Trusted-core isolation is invariant #1; licenses: Lean/Mathlib are permissive, but *Lake dependencies* need per-package auditing (Phase 3 §5.21) |
| P6 | Model access | Frontier closed reasoning models **and** open-weight specialist provers (DeepSeek-Prover-V2 / Goedel-Prover-V2 class) with fine-tuning + RL permitted | Needed for the §5.18 training flywheel; open weights are also a hedge against vendor changes |
| P7 | Real-world interfaces in v1 | **None** (core). v3 → read-only sensors; v3.5 → simulated actuators; v4 → real actuators **with human approval** | Conservative actuator posture; the brief's "open-ended in ideas, bounded in actions" |
| P8 | Safety posture | **Balanced**, but **conservative for actuators** | Ideas can roam; irreversible actions cannot |
| P9 | Hard constraints | User-problem **confidentiality**; **license compliance** (Lean/Mathlib/third-party/Lake deps); **no export-controlled** reasoning content | These are non-negotiable pass/fail gates, not features |
| P10 | Capability packs in scope | **All of §5.10–§5.22**, plus core §5.1–§5.9 | Brief's default "all"; deferrals are argued explicitly in the roadmap (Phase 6) |
| P11 | Longest autonomous run | v1: **days**; v4: **months-long campaigns** | Matches §5.10's checkpoint/restart requirement |

**Extra assumptions we are forced to make and are flagging:**

- **A1 — "Verified" means exported-and-re-checked.** We define a proof as `verified` only when an
  *independent* kernel (nanoda/con-leche/lean4lean-class) accepts the exported proof, matching the
  2026 Riemann-run practice. A successful `lake build` alone is `compiled`, not `verified`.
- **A2 — Kernel-allow-list baseline.** Default permitted axioms: `propext`, `Classical.choice`,
  `Quot.sound` only. Anything else requires an explicit, signed policy exception.
- **A3 — The evaluator is frozen.** All benchmarks, canary sets and the trusted core live in a
  separate, agent-unwritable environment (this is what makes "self-improvement" falsifiable).
- **A4 — Cost currency.** We report cost in **US$ per verified theorem** and **GPU-seconds per
  verified lemma**, with all assumptions stated, because raw "cost multiplier" claims in the
  literature are not comparable.

## 2. The five questions whose answers would most change the design

We proceed on defaults, but these are the questions where a different answer would most change the
architecture. They are ranked by leverage.

1. **How much formalization fidelity is *enough*?**
   If the user needs "a theorem about a model", autoformalization can be largely automated. If the
   user needs "a fact about reality" (clinical dosing, control systems, contracts), then §5.1/§5.6
   must add heavyweight, human-signed **model-gap accounting** (explicit measurement-error and
   modelling hypotheses as Lean hypotheses), and the MVP timeline roughly doubles on the
   verification-fidelity work. *Impact: high. Default assumed: fidelity is first-class, model gap
   always surfaced.*

2. **Is the goal *verified proving* or *open-ended discovery*?**
   Discovery (§5.7, §5.17) requires the curiosity engine, generator/triage pipeline, quality-diversity
   archives, and prior-escape mechanisms — the most speculative and least-evidenced part of the design.
   Proving alone lets us cut roughly a third of the system. *Impact: high. Default: both, but
   discovery is staged late (v2+) and always evaluator-bounded.*

3. **Where is the real bottleneck — agents, search, retrieval, or verification throughput?**
   The brief explicitly asks us to test "more agents" as a premise. If the bottleneck is **verifier
   throughput** (our strong prior, Phase 5), then investing in caching/independent kernels/surrogate
   verifiers beats investing in swarm size by a large factor. *Impact: high; this is the single most
   consequential architectural bet. Default: verification/memory throughput first, agent count last.*

4. **What is the trusted base's licensing/deployment reality?**
   If Lean/Mathlib or the independent kernels must run on regulated on-prem hardware with pinned,
   audited Lake dependencies, our deployment topology and supply-chain design (§5.21) change
   materially (air-gapped mirror, signed content-addressed registry). *Impact: medium-high. Default:
   hybrid with an air-gappable trusted core.*

5. **How much human-in-the-loop is acceptable?**
   Graded sign-off on formalizations, definition admission to the shared library, and actuator
   permissions are human gates. If the user wants near-autonomous throughput, we must replace those
   gates with calibrated automatic authorities — and accept a higher fidelity-risk. *Impact:
   medium-high. Default: humans gate definition-admission and actuation; automation gates
   low-stakes formalization.*

## 3. The four-member design-team disagreements we are explicitly resolving

The brief asks us to *show* productive disagreement. Representative ones (full decision records live
in their phase files):

| Tension | Lean engineer says | Multi-agent architect says | Resolution (and where) |
|---|---|---|---|
| Should the orchestrator be a Lean program or external? | "Put the gate in Lean so its invariant is proved" | "Put orchestration in a normal runtime; Lean is too slow for control flow" | **Both**: control flow external; the **gate + capability/autonomy logic in Lean, proved** (brief's verified-guardrails invariant). See Phase 3 §5.9. |
| Swarms vs. better search | "The kernel is the bottleneck; more agents add noise" | "Hierarchy makes cheap agents nearly free" | **Search/verification first**; swarms only for embarrassingly parallel subgoal search with dedup caching. See Phase 5. |
| Curiosity: drive or flourish? | "Interestingness can't be proved; keep it out of the trusted path" | "Curiosity is the whole point (§5.7)" | Curiosity is an **untrusted proposer** with its own archive; **never** touches the trusted core (anti-Goodhart, Phase 3 §5.7). |
| World models: understanding or prediction? | "A model of reality is not reality" | "We need a 'feel' for the world (§5.6)" | World models are **predictive, calibrated, and explicitly labelled as models**; the perception→Lean bridge carries measurement-error hypotheses. See Phase 3 §5.6. |

## 4. Effect on the plan

These defaults fix: the **trusted/untrusted boundary** (Phase 2), the **verification-first investment
order** (Phase 5), the **staged placement of discovery/capability packs** (Phase 6), and the
**human-gate list** (Phase 3 §5.9). No default blocks progress; each is overridable without
re-architecting.

## Self-critique (Phase 1)

- **Weakest assumption:** P6 (RL/fine-tuning possible). If it is not, the training flywheel (§5.18)
  degrades to prompt/retrieval evolution only — acceptable but a real capability loss. Flagged.
- **Risk:** our "verification throughput first" bet (Q3) could be wrong if retrieval quality turns
  out to dominate; Phase 5 defines an instrumentation plan to detect this early and re-allocate.
- **Not resolved:** acceptable human-gate latency (Q5). We assume "hours to days for high-stakes
  gates" and design resume-able checkpoints around it.
