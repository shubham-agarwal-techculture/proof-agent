# Phase 0 — Ground Yourself: State of the Art (as of 2026-11-23)

> **Status tags used throughout this design set**
> `[exists today]` = shipped, publicly usable, independently reproducible evidence.
> `[near-term]` = demonstrated in a prototype/paper; productisation plausible within ~12–24 months.
> `[frontier]` = research result exists but is fragile, expensive, or unreplicated at scale.
> `[speculative]` = no working demonstration; engineering extrapolation only.
> `[unverified]` = a claim we could not corroborate from an independent source in this pass.

## 0. Method and honesty note

This phase was produced by live web search on **2026-11-23**. Where a claim is vendor-reported,
single-sourced, or internally inconsistent across sources, it is marked `[unverified]` or
"vendor-claimed". We separate three epistemic categories everywhere in this document set:

1. **Works / exists** — reproducible from a public artifact.
2. **Claimed** — announced or reported, not independently reproduced in this pass.
3. **Unknown** — no evidence found.

We did **not** invent any citation. Every URL in the Sources section was returned by the search
pass. Where the underlying world (pinned Lean/Mathlib versions, benchmark numbers) will drift after
2026-11-23, we say so and mark the pin as a **design-time assumption to re-verify**, not a fact.

A recurring, important meta-observation from the sources: the field's own careful analyses conclude
that **autonomous creative theorem *discovery* remains unproven**, while
**assisted/verified proving is now practical**. Our design is built on that boundary.

---

## 1. Lean 4 and Mathlib `[exists today]`

| Item | State (2026-11) | Evidence status |
|---|---|---|
| Lean releases | Rapid cadence; e.g. 4.30.0 (2026-05-26), 4.33.x (2026-08), 4.35.0 (2026-10-12), 4.36.0-rc2 (2026-10-27) | Cited (release notes) |
| Mathlib size | 270k+ formalized theorems, 750+ contributors, 2.2M+ lines, 1,500+ type classes, 20k+ instances | Cited (de Moura, ICML 2026 AI4Math talk) |
| Coverage claim | "Fewer than ~1,000 definitions separate Mathlib from full modern-research-math coverage" | Vendor/advocacy claim `[unverified]`; a community estimate elsewhere says ~120k lemmas earlier in 2026, **inconsistent** — treat both as soft |
| Ecosystem scale | 250k+ unique Lean installs; 9,000+ GitHub repos depending on Lean; industrial users (AWS, Google, Microsoft, Mistral, Nethermind, Galois, others) | Cited |
| Tooling | Lake (build/cache overhaul in 4.30), module system stabilised (4.27), language server, `grind`, new `sym =>` interactive tactic, expanded `cbv` | Cited |
| Independent kernels | `leanchecker`, `nanoda` (Rust), `con-leche`, `lean4lean`, Lean "paranoid" kernel; community kernel arena at arena.lean-lang.org | Cited |
| Flagship verification run | "Riemann Hypothesis Lean proof" (announced 20 Nov 2026): 175,187 modules compile (Lean 4.33.1 / Mathlib 4.33.1); axioms limited to `propext`, `Classical.choice`, `Quot.sound`; nanoda & con-leche accept full export; lean4lean passes module-by-module | Cited (author-published verification page; **not** peer-reviewed here) `[unverified]` |

**Design implication.** The existence of *multiple independent kernels* plus a public "kernel arena"
is the single most important fact for our invariant #1 (trusted core). Our re-checker component
should target an *exported proof* checked by at least one independent kernel, exactly as the
Riemann run did — not merely a successful `lake build`.

---

## 2. AI theorem provers and autoformalization

| System | Claimed achievement | Status | Second-source note |
|---|---|---|---|
| **AlphaProof** (DeepMind) | Silver-medal equivalent IMO 2024 (3/5 non-geometry, incl. Problem 6); AlphaZero-style RL; "Test-Time RL"; reported ~80M formal problems; Nature paper Nov 2025 | `[exists today]` | Multiple sources; strongest evidence base |
| **AlphaProof Nexus** | Peer-reviewed in *Science*, Oct 2026 | `[near-term]` | Cited |
| **AlphaGeometry / AG2** | Synthetic-data geometry prover; combined w/ AlphaProof for IMO silver | `[exists today]` | Cited |
| **Gauss AI** (Math Inc.) | Formalised strong Prime Number Theorem (~25k lines, 1,100+ thms) in ~3 weeks vs 18+ months of human effort | `[near-term]` | Cited; vendor-affiliated |
| **Seed-Prover** (ByteDance) | IMO 2025 silver; ~331/657 PutnamBench (50.4%) | `[near-term]` | Cited |
| **Aristotle** (Harmonic) | IMO 2025 gold, all solutions Lean-verified | `[near-term]` | Cited; vendor-reported |
| **DeepSeek-Prover-V2** | 671B MoE; 88.9% MiniF2F-test; 49/658 PutnamBench; MCTS + subgoal decomposition | `[exists today]` | Open weights |
| **Goedel-Prover-V2** (Princeton) | 32B w/ self-correction: ~86/644 PutnamBench (13.4%); data architecture beats scale | `[exists today]` | Open weights |
| **Kimina-Prover** (Moonshot) | Lean prover family | `[near-term]` | Cited in surveys |
| **Leanstral** (Mistral) | "First open-source *code agent* for Lean 4"; 26.3 on FLTEval @pass@2; ~15× cheaper than Claude Sonnet | `[near-term]` | Single-source `[unverified]` |
| **Hilbert** (Gemini 2.5 Pro driver) | PutnamBench 70%, miniF2F 99.2%; ~US$170k API spend reported | `[near-term]` | Cost figure vendor/Deliberative-report sourced |
| **Goedel-Architect** (Princeton) | Blueprint-generation agent; PutnamBench 75.6% for ~US$294; solved all 244 miniF2F-test | `[frontier]` | Cited; cost claims `[unverified]` |
| **OProver-32B** (M-A-P + Nanjing U.) | MiniF2F 93.3, ProverBench 58.2, PutnamBench 11.3; OProofs corpus 1.76M statements / 6.80M verified proofs | `[near-term]` | Cited |
| **REAL-Prover** | Retrieval-augmented stepwise; ProofNet 23.7% @pass@64; FATE-M 56.7% | `[near-term]` | Cited |
| **Axiom** (startup) | 12/12 Putnam 2025 | `[unverified]` | Conference-slide claim |

**Ecosystem tooling that is real today:**
- **LeanDojo-v2** — repository tracing, lifelong datasets, retrieval-augmented agents, HF
  fine-tuning (SFT/GRPO), Pantograph-based interactive proof search `[exists today]`.
- **LeanCopilot** — native LLM inference inside Lean; tactic suggestion, proof search, premise
  selection; MIT-licensed `[exists today]`.
- **LeanSearch v2** — embedding+reranker premise retrieval (nDCG@10 ≈ 0.62 standard mode);
  "reasoning mode" for *global* premise retrieval `[near-term]`.
- Named retriever baselines: `LeanFinder`, `LeanStateSearch`, `INF-X-Retriever`.

**Design implication.** Two architectural lessons are consistent across top systems:
(1) **hierarchical decomposition / blueprints** (Hilbert, Goedel-Architect, DeepSeek-V2) beat flat
whole-proof generation on hard problems; (2) **retrieval quality is a first-class bottleneck**, not
an add-on. Both are adopted in Phase 2/3.

---

## 3. Agent frameworks and interoperability protocols `[exists today]`

| Protocol | Layer | Key facts (2026-11) |
|---|---|---|
| **MCP** (Model Context Protocol, Anthropic) | vertical: agent↔tools/resources/prompts | JSON-RPC, stdio or Streamable HTTP; stateless per call; `tools/list`, `server/discover`; revision **2026-07-28** with a **Tasks** extension |
| **A2A** (Agent2Agent, Google-led) | horizontal: agent↔agent | **v1.0 shipped 2026-03-12** (advisor committee of 8 firms); Agent Cards (now *signed*); bindings JSON+HTTP, gRPC, JSON-RPC; task lifecycle w/ polling/streaming/webhooks; v1.0.1 latest |
| **ACP** | REST-native performative messaging | multi-part messages, async streaming, observability |
| **ANP** (Agent Network Protocol) | open-internet discovery | DIDs + JSON-LD graphs |
| **OpenWOP** | durable workflow orchestration substrate | runs, event logs, replay, human-approval interrupts |

Consensus framing from sources: **MCP = depth (a given agent's tools); A2A = reach (peer agents)**.
They are complementary, used together. Security literature (threat modelling across MCP/A2A/ANP/Agora)
identifies protocol-level risks (e.g. missing mandatory identity binding for executable components,
wrong-provider tool execution under multi-server composition) `[exists today]`.

**Design implication.** Our tool-server interface standard (Phase 3, §5.3) adopts **MCP** as the
baseline tool contract and **A2A** for cross-instance/cross-"country" agent federation, because both
had stable production releases by 2026 and a security literature to build on. We do **not** invent a
new protocol unless MCP/A2A provably cannot express a needed capability.

---

## 4. Open-ended / curiosity-driven discovery systems

| System | Mechanism | Status | Notes |
|---|---|---|---|
| **FunSearch** (DeepMind, 2023) | LLM + evolutionary search over *programs* | `[exists today]` | Predecessor of AlphaEvolve |
| **AlphaEvolve** (DeepMind, May 2025) | Gemini ensemble as mutation operator + **automated evaluators** as selection; runs unattended for hours/days | `[exists today]` | 48-mult 4×4 complex matmul (beats Strassen's 49); internal Google use (scheduling, TPU, training); PNAS 2026 follow-up (Georgiev, Gómez-Serrano, Tao, Wagner) across 67 problems |
| **AlphaTensor** (2022) | RL decomposition of tensor problems | `[exists today]` | Lineage for AlphaEvolve |
| **Ramanujan Machine** (2021) | Automated *conjecture* generation (continued fractions) | `[exists today]` | Generates conjectures **without** establishing validity — the canonical "propose, don't dispose" example |
| **Voyager** (NVIDIA/Caltech, 2023) | Automatic curriculum + **growing skill library** + iterative prompting w/ self-verification | `[exists today]` | The template for our *procedural* + *skill* memory |
| **POET / OMNI / enhanced POET** | Open-ended RL w/ co-evolving environments | `[near-term]` | Paired environment–agent evolution |
| **ADAS** (Automated Design of Agentic Systems) | Meta-agent searches for new agent designs; keeps an archive | `[near-term]` | Directly informs our §5.18 meta-agent |
| **Darwin Gödel Machine** (Sakana, May 2025) | Self-referential agent rewrites own code, **validates each change on a benchmark** | `[near-term]` | Informs our *bounded* self-improvement + frozen-eval invariant |
| **OpenAI unit-distance disproof** | Reasoning model produced a *counterexample family* to Erdős's 1946 conjecture (2025-05-20); Lean formalisation reported 2026-05-28; 9 mathematicians cross-checked | `[frontier]` | Milestone for *discovery by counterexample*; the direction our §5.7 must support |

**Design implication.** Every credible open-ended system pairs a **proposer** with a **frozen,
agent-influenceable-proof evaluator**. This is exactly our invariant #1 and the anti-Goodhart
requirement in §5.7. AlphaEvolve's "LLM proposes, evaluator disposes" is structurally identical to
"LLM proposes, kernel disposes" — we reuse the pattern but with the kernel as the evaluator.

---

## 5. Benchmarks and their saturation `[exists today]`

| Benchmark | Domain | Reported range (2026) | Saturation |
|---|---|---|---|
| **miniF2F** | olympiad/competition | Hilbert 99.2%; OProver 93.3; DeepSeek-V2 88.9; Goedel-Architect 244/244 | **Saturated** — near-useless as a frontier signal |
| **ProofNet** | undergrad-level textbook | REAL-Prover 23.7% @pass@64 | Partially saturated |
| **PutnamBench** (644–672 problems) | Putnam-level | 11.3% → 75.6% depending on system | **Active frontier**; wide spread; cost-sensitive |
| **FLTEval** | repository-scale Lean | Leanstral 26.3 @pass@2 | Newer; frontier |

**Design implication.** A design that optimises miniF2F is optimising a solved game. Our evaluation
plan (Phase 5, §5.8) must use **PutnamBench-class and out-of-math tasks**, **held-out new problems**,
and **real library-development / literature-audit tasks**. We must also control for **contamination**,
since many of these problems (and their solutions) are on the public web that models were trained on.

---

## 6. What exists vs. what is merely claimed (executive summary)

**Genuinely available today (build on these):** Lean 4 + Mathlib + independent kernels; MCP; A2A v1.0;
LeanDojo-v2; LeanCopilot; LeanSearch-style retrieval; open-weight provers (DeepSeek-Prover-V2,
Goedel-Prover-V2); program-evolution pipelines (FunSearch/AlphaEvolve pattern); skill-library agents
(Voyager pattern).

**Demonstrated but not cheap/reliable at scale:** agentic blueprints (Goedel-Architect), retrieval
augmentation for hard math (REAL-Prover), self-improving agent archives (ADAS/DGM), counterexample
discovery on famous conjectures (single dramatic cases).

**Claimed but weakly evidenced in this pass:** exact Mathlib lemma counts (~120k vs ~270k conflict),
specific cost multipliers (~500×), "first open-source Lean agent" claims, and the not-yet-peer-reviewed
flagship verification runs.

**Not demonstrated anywhere we found:** autonomous *creation of new kinds of problems or formal
languages* with externally validated significance; world models giving "understanding" (see §5.6
critique); Mathlib-quality autonomous library contribution without human review.

---

## 7. Where the field's own analysis agrees the hard problems are

Across the survey material the same bottlenecks recur, and they are exactly the sections the brief
asks us to spend depth on:

1. **Autoformalization fidelity + the "definition-finding gap"** (can't yet invent the right new
   definitions) — the dominant failure mode for *discovery*.
2. **Verifier throughput & trust** (multiple kernels, caching, independent re-check) — the cost wall.
3. **Retrieval quality** — global premise retrieval is the emerging frontier.
4. **Perception→Lean bridge** — essentially untouched outside mathematics.
5. **Memory consolidation / continual learning** — Voyager-style skill libraries exist but no
   demonstrated long-horizon verified-library growth loop.
6. **Curiosity signals** — every system uses an evaluator precisely because intrinsic "interestingness"
   alone is not trusted.

---

## Sources

- [Lean 4.30.0 release notes (2026-05-26)](https://lean-lang.org/doc/reference/latest/releases/v4.30.0/)
- [Lean 4.35.0 release notes (2026-10-12) + release index](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/)
- [Lean 4.27.0 release notes (2026-01-24)](https://lean-lang.org/doc/reference/latest/releases/v4.27.0/)
- [Verification files for the Lean proof of the Riemann Hypothesis (Sutherland, MIT)](https://math.mit.edu/~drew/grh/)
- [Leo de Moura — "Machine-Checked Mathematics in the Age of AI" (ICML 2026 AI4Math)](https://leodemoura.github.io/static/icml2026/)
- [Major Breakthroughs in Lean 4-Based Auto-Formalized Mathematics (UVA course survey, Jan 2026)](https://www.cs.virginia.edu/~rmw7my/Courses/AgenticAISpring2026/Major%20Breakthroughs%20in%20Lean%204-Based%20Auto-Formalized%20Mathematics.html)
- [AlphaProof, Nature 2025](https://www.nature.com/articles/s41586-025-09833-y)
- [Goedel-Prover (arXiv 2502.07640)](https://arxiv.org/pdf/2502.07640)
- [DeepSeek-Prover (AI Wiki, updated Oct 2026)](https://aiwiki.ai/wiki/deepseek_prover)
- [Hilbert: Recursively Building Formal Proofs with Informal Reasoning (ICLR 2026)](https://papernotes.org/ICLR2026/llm_reasoning/hilbert_recursively_building_formal_proofs_with_informal_reasoning/)
- [Goedel-Architect write-up (36Kr / 机器之心, 2026-06-07)](https://m.36kr.com/p/3841174468151553)
- [OProver-32B (36Kr, 2026-06-09)](https://eu.36kr.com/en/p/3845562669042179)
- [REAL-Prover (arXiv 2505.20613)](https://arxiv.org/pdf/2505.20613v2.pdf)
- [LeanDojo-v2 (NeurIPS Math Reasoning & AI 2025)](https://leandojo.org/leandojo)
- [Lean Copilot (NeuS 2025 / arXiv 2404.12534)](https://leandojo.org/leancopilot.html)
- [LeanSearch v2 (arXiv 2605.13137)](https://arxiv.org/html/2605.13137v1)
- [Survey of Agent Interoperability Protocols: MCP, ACP, A2A, ANP (arXiv 2505.02279)](https://arxiv.org/pdf/2505.02279v1)
- [A2A and MCP (a2a-protocol.org)](https://a2a-protocol.org/latest/topics/a2a-and-mcp/)
- [A2A Protocol Ships v1.0 (2026-03-12)](https://a2a-protocol.org/latest/blog/2026/03/12/a2a-protocol-ships-v10-production-ready-standard-for-agent-to-agent-communication/)
- [Security Threat Modeling for MCP/A2A/Agora/ANP (arXiv 2602.11327)](https://arxiv.org/pdf/2602.11327v2)
- [OpenWOP — A2A vs MCP vs OpenWOP](https://openwop.dev/comparisons/a2a-openwop-mcp/)
- [AlphaEvolve (AI Wiki, updated 2026-11-01)](https://aiwiki.ai/wiki/alphaevolve/raw)
- [Mathematical exploration and discovery can be done at scale (PNAS 2026, Georgiev et al.)](https://par.nsf.gov/biblio/10716339/media/xml)
- [List of mathematical discoveries made with AI (Wikipedia)](https://en.wikipedia.org/wiki/List_of_mathematical_results_produced_by_artificial_intelligence)
- [Voyager: An Open-Ended Embodied Agent (arXiv 2305.16291)](https://arxiv.org/pdf/2305.16291v1)
- [9 Open-Source Self-Improving AI Agent Frameworks (2026)](https://futureagi.com/blog/self-improving-ai-agents-open-source-frameworks/)
- [The Machines That Build Themselves: History of Recursive Self-Improving AI](https://1cw.org/the-machines-that-build-themselves-a-history-of-recursive-self-improving-ai/)
- [KARP "Lean 4 Verification Convergence" report (Apr 2026)](https://souldriver.com.au/report/lean-4-verification-convergence/pdf)
- [AI4Math Chronicle](https://charlie-wang-03.github.io/ai4math-chronicle/en/)

## Self-critique (Phase 0)

- **Weakest assumption:** that today's benchmark numbers and Mathlib counts are stable enough to
  design against. They will drift; every version pin in this design set is flagged "re-verify".
- **Biggest evidence weakness:** several headline entries (Leanstral, Aistotle cost, Goedel-Architect
  cost, the Riemann verification page) are single-sourced or author-published. We deliberately did
  **not** elevate them to `[exists today]`.
- **What we could not resolve:** the true size/coverage of Mathlib (two sources conflict by >2×).
  Our design does not depend on the absolute number, only on "large and rapidly growing".
- **Falsifying experiment for the whole design's optimism:** *"Do agentic decompositions of
  PutnamBench-class problems improve verified solve-rate per dollar over a strong single-agent +
  search baseline?"* — Phase 5 defines this A/B explicitly.
