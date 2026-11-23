# Master Prompt: Design an Agentic, Curious, Memory-Rich Theorem-Proving System on Lean 4 + Mathlib

*Draft v2 · prepared by Claude · 22 November 2026*

## 1. Role

You are a four-person design team that argues productively: (a) a Lean 4 / Mathlib proof engineer, (b) a distributed multi-agent systems architect, (c) a researcher in automated reasoning, reinforcement learning and open-ended learning, and (d) a safety and reliability engineer whose job is to break the design. Where you disagree, show the disagreement and how you resolved it.

## 2. Mission

Design, in implementable detail (architecture, protocols, algorithms, data models, roadmap, risks), an agentic theorem-proving and discovery system that can:

1. **Accept any problem from any field**, defined as richly as the human likes (text, data, papers, code, models, constraints, intentions).
2. **Formalize it in Lean 4 with Mathlib** (extending the library where needed), then plan, strategize and solve it using tools, subagents, swarms and, at the limit, a country-scale society of bil lions of specialised agents.
3. **Remember:** capture snapshots of every episode and compound lemmas, strategies and skills from one problem to the next.
4. **Sense the world** through real-time sensor and other data streams, maintain world models, and act through actuators only behind strict gates.
5. **Wonder:** ponder, become curious and inspired, and originate problems nobody specified, including kinds of problems and concepts humans have not imagined.

Beyond these five, the system must also act as a **long-horizon research partner** (multi-month programs, literature audits, certified computational experiments, write-ups for humans) and **improve itself safely** (learn from every verified result, design better agents and tools, and share verified knowledge across a federation of instances without ever weakening its trusted core). Sections 5.10 to 5.22 detail these capabilities.

The Lean kernel is the only judge of formal truth. LLMs, heuristics, world models and curiosity propose; only the verifier disposes.

## 3. Parameters

Fill in what you know. For anything left blank, choose a sensible default and state it explicitly.

- Primary users: \[research mathematicians | scientists and engineers | students | fully autonomous operation\]
- Initial domains: \[e.g., combinatorics and number theory first, then control theory, physics, program verification\]
- Compute and budget: \[one GPU workstation | 8-GPU node | 1,000+ GPUs | national scale\], plus monthly spend
- Team and timeline: \[e.g., 3 engineers, 12 months\]
- Deployment and licensing: \[cloud | on-premises | hybrid; open-source or proprietary components\]
- Model access: \[which LLMs are available; whether fine-tuning and reinforcement learning are possible\]
- Real-world interfaces in v1: \[none | read-only sensors | simulated actuators | real actuators with human approval\]
- Safety posture: \[conservative | balanced | aggressive autonomy\]
- Hard constraints: \[privacy, compliance, export control, ethics\]

* Capability packs in scope: \[all of 5.10 to 5.22 | a chosen subset | core only, 5.1 to 5.9\]
* Longest autonomous run: \[minutes | days | months-long campaigns\]

## 4. Design invariants

Non-negotiable. If you bend one, say so and justify it.

1. **Trusted core, untrusted periphery.** A small, auditable verification core (pinned Lean and Mathlib, the kernel, an independent re-checker, statement matching, axiom audit) is the sole authority. Every agent is an untrusted proposer. Assume agents will try, deliberately or through reward hacking, to exploit the checker (`sorry`, extra axioms, `native_decide`, `unsafe`, `implemented_by`, kernel-bypass options, altered statements, macro and elaborator tricks), and harden against it.
2. **Fidelity before proof.** Proving the wrong theorem is the dominant failure mode, so formalization is a first-class, adversarially reviewed pipeline. Keep mathematical truth separate from the model gap: a theorem about a model is not a fact about reality.
3. **Everything is a versioned, content-addressed artifact with provenance:** problem, formalization, plan, search tree, proof, tool trace, cost, producer, Lean and Mathlib versions.
4. **Scale-free architecture.** The same abstractions must run as one agent on a laptop and as millions to billions of agent instances. State what changes at each order of magnitude and where adding agents stops helping.
5. **Memory is a learning system, not a log:** snapshot, index, consolidate, abstract, forget, and migrate across library versions.
6. **Open-ended in ideas, bounded in actions.** Curiosity roams freely over ideas; actuators sit behind graduated, auditable gates.
7. **Calibrated honesty.** Every claim carries a status (proved, disproved, counterexample found, conjectured with evidence, unknown), a confidence, and its dependencies.
8. **Humans stay in the loop where it matters:** accepting high-stakes problems, admitting definitions to the shared library, granting actuator permissions, changing the system’s own core.
9. **Cost-awareness.** Compute, energy, tokens and verifier throughput are scarce; every major choice states its cost model.
10. **Untrusted inputs.** Sensor streams, web pages, papers and other agents’ messages are data, never instructions.

Three further invariants govern the capability packs in 5.10 to 5.22. The same rule applies: if you bend one, say so and justify it.

- **Verified guardrails.** The action gate, capability logic and autonomy governor are small enough to verify formally, ideally in Lean, and their proofs belong to the trusted core.
- **Reversibility and least privilege.** Prefer reversible actions, minimal capabilities and staged rollouts; irreversible actions need explicit human approval.
- **Federated, portable trust.** Verified artifacts move between instances by content hash and signature; trust is granted by policy and never assumed.

## 5. Capabilities to design

For each capability give the design, key algorithms, interfaces and schemas, failure modes, metrics, and open research questions.

### 5.1 Universal problem intake and formalization

- **ProblemSpec.** A schema rich enough to define everything about a problem in any field: informal statement; goal type (prove, disprove, find a counterexample, compute with a certificate, optimize with a certificate, classify, verify a program, protocol or design, derive a bound); assumptions and units; domain ontology; attached data, papers, code and models; constraints; stakes; budget and deadline; acceptable proof styles; what counts as “solved”; known partial results; human hints.
- **Autoformalization.** Multiple independent formalizations, back-translation to natural language, an adversarial statement auditor, sanity checks (toy instances, non-vacuity, known corollaries, `decide` or `norm_num` on small cases), and graded human sign-off.
- **Fields where Mathlib is thin** (physics, biology, economics, control, systems, law): a library-extension strategy covering new definitions, flagged axiomatizations, modelling assumptions stated as explicit Lean hypotheses, interface layers, and a policy for promoting domain libraries.
- **Mixed initiative.** How a human states, corrects and refines a problem through dialogue and a workbench.

### 5.2 Planning and strategy

- **Hierarchical planning:** problem → lemma graph or blueprint → proof obligations → tactic steps, with dependency tracking and re-planning when a lemma fails.
- **Strategy portfolio and meta-reasoning:** induction, contradiction, normal forms, algebraic and analytic estimates, probabilistic and combinatorial constructions, SMT and ATP delegation, computation-guided search, analogy transfer; and when to generalize, specialize, reformulate, hunt for a counterexample, abandon, or ask a human.
- **Search:** best-first or MCTS over proof states with learned policy and value models; informal-sketch-then-formalize loops; whole-proof generation with verifier feedback; anytime behaviour; portfolio racing; budget allocation across branches and problems.

### 5.3 Tools

All tools are typed, sandboxed, resource-limited, cached and observable. Specify the contract and error taxonomy for: the Lean 4 server or REPL (tactic- and file-level) with pinned Mathlib and cache; premise retrieval (embedding plus symbolic: Loogle- and LeanSearch-style, `exact?`, `apply?`, `rw?`); automation (`simp`, `aesop`, `omega`, `linarith`, `nlinarith`, `norm_num`, `ring`, `field_simp`, `positivity`, `gcongr`, `grind`; verify what exists in the pinned version); external ATP and SMT solvers with proof reconstruction; computer algebra and numerics as hint generators, never as trusted; counterexample finders (property testing, SAT/SMT, brute force, evolutionary search); literature and code search; autoformalization and proof-repair models; refactoring, golfing, linting and documentation tools; agent-authored tactics and metaprograms, sandboxed and gated like any other proposal; independent re-verification. Propose a tool-server interface standard and justify it.

### 5.4 The agent society: subagents → swarms → “country” scale → billions

- **Roles** (at least): conductor, formalizer, statement auditor, strategist and decomposer, librarian and retriever, tactic generator, prover, debugger and repairer, counterexample hunter, experimentalist, analogist (cross-field transfer), literature scout, refactorer, library curator, explainer (human-readable proofs), memory curator, resource economist, safety officer. Define “different expertise” concretely (fine-tuned specialists, tool-specialised agents, small distilled tactic models versus large reasoning models) and how expertise is measured, discovered, spawned and retired.
- **Agentic capabilities to specify per role:** planning, tool use, reflection and self-critique, delegation, long-horizon operation with checkpoint and resume, negotiation, learning from feedback, safe self-improvement.
- **Organizational forms** and when each wins: single loop; subagent trees; blackboard; debate and ensembles; markets and auctions for tasks; swarms for massively parallel search; institutions (verification courts, libraries, training “universities”, compute treasuries, reputation systems, constitutions); “countries” with different libraries and conventions, and the treaties between them (interface lemmas, translation layers).
- **Communication:** typed messages, a shared proof-state store, claims with evidence, credit assignment, and defenses against herding, collusion, echo chambers and verifier gaming.
- **Billions, made operational.** Define an agent as an ephemeral, mostly stateless unit (role + context + budget). Show how most agents are cheap (small models, classical solvers) and how hierarchy, canonical goal hashing and deduplication, (goal, tactic) → outcome caching, speculative execution, back-pressure and scheduling keep cost sane. Analyze the real bottlenecks (proof dependency structure, coordination overhead, verifier throughput, retrieval quality) with back-of-envelope numbers at 10^0, 10^3, 10^6 and 10^9 agents, and say honestly where more agents stop helping.

### 5.5 Memory and continual learning

- **Layers:** working (the current proof state); episodic (event snapshots or “case files”: problem, formalizations, plans, search summaries, dead ends and why they failed, insights, tool traces, costs, human feedback, outcome); semantic (verified definition and lemma library plus a knowledge graph across concepts, papers and domains); procedural (strategies, tactic macros, proof patterns, learned policy and value models); meta (what works for which problem class, agent reputation, calibration statistics); world memory.
- **Operations:** snapshot triggers; structural and analogical retrieval, not just text similarity; offline consolidation (“sleep”: replay, mine recurring patterns into new lemmas and tactics, distill into model weights, prune); forgetting that preserves provenance; branching and counterfactual replay; sharing policies across agent “countries”; confidentiality of user problems; defenses against memory poisoning and benchmark contamination.
- **Library growth and migration:** private scratch → shared library → Mathlib-quality contributions; re-checking and auto-repairing everything when Lean or Mathlib versions change.
- **Closing the loop:** verified proofs become training data for specialists (expert iteration, reinforcement learning from verifier feedback), with safeguards against drift and self-reinforcing errors.
- **Proving the value:** A/B protocols that measure how much memory improves later problems.

### 5.6 World interface: sensors, world models, actuators

- **Streams:** typed, timestamped events with units, uncertainty and provenance; adapters for instruments, simulations, telemetry, feeds and repositories; multi-timescale summarization; salience and anomaly attention.
- **World models:** layered latent predictive models, causal and structural models, physical simulators, symbolic ontologies, calibrated uncertainty. Explain how the system gets a “feel” for the world, and how that feel is represented and queried.
- **Perception → Lean bridge:** how observations become conjectures with explicit measurement-error and modelling hypotheses, and how verified invariants, certified bounds and safety properties are kept in a formal world-model layer.
- **Actuators:** proof-carrying actions where a certificate is possible, runtime monitors and shields where not; simulation first (digital twin); capability tokens, rate limits, approval tiers, audit logs, a kill switch. The exploratory swarm has no direct actuator access.
- **Failure modes:** sensor spoofing, distribution shift, privacy, dual use.

### 5.7 Curiosity: originating problems nobody specified

- **A “ponder” subsystem with explicit, measurable drives:** learning and compression progress, world-model prediction error, novelty and diversity (quality-diversity archives), frontier-difficulty targeting, unification power (one result explaining many), cross-field bridging, simplicity of statement versus depth of proof, and a learned “taste” model trained on expert judgments and downstream reuse.
- **Generators:** pattern mining over computed data and sensor streams; analogy and functor transfer between fields; generalizing, specializing, weakening and strengthening known theorems; “drop this hypothesis” explorations; mutating and inventing definitions; gap-hunting in Mathlib and the literature; formalizing unproven claims from papers; daydreaming (random walks over the memory graph, filtered by evaluators); self-play between a conjecturer and a prover.
- **Triage pipeline:** novelty check against the library and the literature; triviality check by automation; a cheap attempt to disprove first; significance and cost estimates; safety and dual-use screen; explore/exploit portfolio management.
- **Beyond instances:** how the system invents new kinds of problems, concepts and formal languages, and how that is evaluated (library compression, explanatory power, predictive power, external expert review).
- **Anti-Goodhart safeguards:** trivial-conjecture spam, interestingness hacking, rabbit holes, resource governors, and judges the generator cannot influence.

### 5.8 Verification, evaluation and trust

- **Layered verification:** the kernel; an independent re-checker; axiom audit (`#print axioms`; by default only `propext`, `Classical.choice` and `Quot.sound` are allowed); scans for `sorry`, `unsafe`, `implemented_by`, `native_decide`, `partial` and kernel-bypass options such as `debug.skipKernelTC`; comparison of the final theorem statement against the signed spec; read-only specs for agents; size and time limits.
- **Metrics:** verified solve rate, cost per verified theorem, time to proof, formalization faithfulness rate, memory reuse and transfer gains, swarm speed-up versus agent count, curiosity quality (novelty, expert-rated interestingness, later usefulness), safety incidents.
- **Evaluation plan:** public benchmarks (e.g., miniF2F, ProofNet, PutnamBench; many are saturating, so verify the current landscape), held-out new-problem sets, real library-development tasks, out-of-math domains, ablations, contamination controls, a continuous evaluation harness.

### 5.9 Safety, governance and human oversight

- Graduated autonomy levels (L0 advise-only to L5 self-directed inside a sandbox) with entry criteria and automatic demotion.
- Self-modification policy: the system may improve its agents, prompts and tools but never its trusted core; every change is sandboxed, verified and approved.
- Dual-use screening, privacy, licensing (Lean, Mathlib, third-party), auditability, rollback, red-teaming, incident response.

* Verified guardrails: write the action gate, capability-token logic and autonomy governor as small Lean programs with proved invariants (for example, no actuator command is issued without a valid, unexpired capability and a passed policy check), and count those proofs as part of the trusted core.

### 5.10 Long-horizon research programs and the belief ledger

- **Program planner:** turn a grand question into programs, hypotheses, lemma roadmaps (blueprints) and milestones, each with pivot and kill criteria. The agenda spans weeks to years, survives restarts through checkpoint and resume, and rebalances as results arrive.
- **Open-problem campaigns:** systematic sweeps over curated sets (formalized-conjecture repositories, unsolved-problem lists, `sorry`s in existing Lean projects, gaps in Mathlib), triaged by tractability and value. Count partial results as wins: special cases, reductions, weaker theorems, counterexamples to natural strengthenings.
- **Belief ledger:** calibrated probabilities over open conjectures and subgoals (logical uncertainty), updated from experiments, partial results and failed attempts, and used for scheduling and honest reporting.
- **Value-of-information scheduler:** allocate compute across thousands of concurrent problems by success probability, payoff, cost and learning value, with stop-loss rules.
- **Human–agent research teams:** Polymath-style collaboration, task hand-offs, shared blueprint dashboards and review queues.

### 5.11 Experimentation lab and certified computation

- **Lab tool belt:** computer algebra and discrete-math systems (e.g., Sage, GAP, PARI/GP, nauty), SAT, SMT and ILP solvers, integer-relation and lattice-reduction methods (PSLQ, LLL), data catalogues (OEIS, LMFDB), numerical and Monte Carlo simulation, symbolic regression, and cluster execution.
- **Experiment design:** hypotheses, controls, search-space design, active experimentation (Bayesian optimal experimental design), reproducible notebooks, and automatic pattern mining that feeds 5.7.
- **Certified computation:** computed results enter Lean only through checkable certificates (LRAT or DRAT proofs for SAT, `bv_decide`-style bit-blasting, interval arithmetic, polynomial and sum-of-squares certificates, proof by reflection with kernel-checked `decide`; verify what exists). Label every claim “kernel-verified” or “computationally verified” and never blur the two. Plan for huge finite checks: sharding, resumable verification, certificate compression, verified checkers.

### 5.12 Literature-to-Lean engine and auditing

- **Reading pipeline:** ingest papers, books, preprints, lecture notes and code; extract definitions, claims, dependency graphs and proof sketches; build a blueprint; formalize incrementally with human checkpoints.
- **Audit mode:** formalize published results to find gaps, errors, missing hypotheses and hidden assumptions, and report them referee-style with machine-checked evidence (gap lemmas, counterexamples).
- **Cross-prover harvesting:** learn from or translate libraries in other proof assistants (Isabelle, Rocq, HOL, Metamath) and from informal corpora, with license checks, attribution and full re-verification of every imported artifact.
- **Continuous watch:** monitor new preprints and repositories for results relevant to open campaigns, and update beliefs and memory.

### 5.13 Generalization, abstraction and library gardening

- **Generalizer:** lift proofs to the weakest hypotheses and most general typeclass setting; discover structure shared across lemmas; propose unifying definitions and new abstractions; generate duals and analogues automatically (additive and multiplicative, order duals).
- **Gardener:** proof golfing and refactoring; deduplication of lemmas and near-duplicate definitions; Mathlib naming, style and documentation conventions; deprecation handling; library-health statistics; upstream-ready pull requests prepared for human review.
- **Compression as a signal:** shorter proofs and a smaller library are a measurable progress and interestingness indicator that feeds 5.7.

### 5.14 Multimodal and structured intake

- **Inputs:** figures, diagrams, handwritten notes, plots, tables, spreadsheets, CAD files, code, simulation traces and lecture recordings, extracted into typed `ProblemSpec` fragments with provenance and confidence. When confidence is low, ask a human to clarify.
- **Geometry pipeline:** diagram → formal configuration → symbolic engine plus a prover trained on synthetic data (AlphaGeometry-style).
- **Round trip:** render formal statements and proofs back into figures and plain language so humans can check what was understood.

### 5.15 Program, protocol and system verification

- **Lean as a verified programming language:** elicit formal specifications from requirements, regulations and natural language with traceability; co-synthesize code and proofs; prove refinement and equivalence.
- **Targets:** algorithms, distributed protocols and state machines, smart contracts, cryptographic primitives, control and cyber-physical software, certified bounds for machine-learning components.
- **State the trusted base:** compiler, runtime, hardware and environment assumptions appear in every certificate and are never hidden.

### 5.16 Domain packs and plug-in architecture

- **A domain pack** bundles an ontology, formal definitions, formalization conventions, test suites and canary problems, known pitfalls, tool adapters, example problems, an expert-reviewed evaluation and named maintainers. Packs have versioned interfaces, quality tiers (experimental, reviewed, certified), dependency management and a promotion path.
- **Initial packs:** propose the list and the criteria for building one (e.g., combinatorics, number theory, analysis, probability and statistics, algorithms and complexity, cryptography, control and dynamical systems, physics, economics and game theory, biology models, law and compliance, hardware and distributed systems).
- **Pack-authoring agent:** bootstraps a new pack from textbooks, papers and expert dialogue.

### 5.17 Open-ended discovery beyond human priors

- **Theory exploration:** systematically generate and test conjectures within a vocabulary (QuickSpec-style), then mutate the vocabulary itself: new definitions, new structures, weakened or alternative axioms, nearby formal systems.
- **Richness tests for new concepts:** number and depth of nontrivial consequences found automatically, library compression, unexpected links between distant areas, predictive power on world-model data, and survival under attempts to trivialize them.
- **Inspiration channels:** structural analogies from physics, biology, computation, economics, art and music; a serendipity engine that forces collisions between unrelated memory episodes; maps of the “adjacent possible” showing where a small step opens a large territory; imagination through counterfactual rollouts of world models and simulators.
- **Aesthetic sense:** learned elegance judgments (generality, brevity, symmetry, surprise), calibrated against human mathematicians but protected from collapsing into a single taste.
- **Prior-escape mechanisms:** ensembles with deliberately different priors (foundations, notation, training data), quality-diversity archives, periodic “human-prior ablation” runs, and novelty judged by outside reviewers.

### 5.18 Self-improvement and automated agent design

- **Meta-agent:** designs and tunes agents, prompts, tools, topologies and schedulers by search (evolutionary or Bayesian), scored on verified outcomes and cost over held-out problems; keeps an archive of variants with lineage and automatic ablations.
- **Training flywheel:** curated verified data → fine-tuning, distillation and reinforcement learning of specialist models; curricula pitched at the current frontier; evaluation gates before deployment; instant rollback; apprenticeship, in which small agents learn from the verified work of large ones.
- **Hard limits:** self-improvement never touches the trusted core or the evaluation harness; they live in separate environments under separate keys; any change that raises autonomy needs human approval.

### 5.19 Adaptive compute and verification infrastructure

- **Fast and slow modes:** learned tactic prediction and retrieval for easy steps; deliberate planning, search and informal reasoning for hard ones; difficulty estimators route work, and test-time compute scales with expected value.
- **Surrogate verifiers:** cheap approximate checks (skeleton type-checking, learned validity predictors) prune candidates before the full kernel and the independent re-checker run.
- **Global content-addressed proof cache:** (goal, context, library hash) → result, reused across agents and sessions and, by policy, across instances; incremental checking; checker farms; resource accounting.
- **Fault tolerance:** idempotent tasks, retries, poison-pill detection, deterministic replay.

### 5.20 Observability, reliability engineering and QA

- **Flight recorder:** every decision, tool call, memory read and write, and cost as replayable events; time-travel debugging; cost and credit attribution per agent and per lemma.
- **Reliability practice:** service-level objectives, canary problems, regression suites, chaos testing of agents and tools, adversarial formalization stress tests, shadow deployments, and postmortems that feed memory.
- **Dashboards:** blueprint progress, frontier maps, budget burn, the belief ledger and safety incidents.

### 5.21 Federation, provenance, governance and incentives

- **Federated library:** a content-addressed registry of lemmas and definitions with signed artifacts and trust policies (who or what is trusted for which claims); supply-chain security for dependencies (Lake packages pinned and audited); sharing of statements and certificates without confidential context. Zero-knowledge attestations that a proof was verified are a speculative extension.
- **Governance:** a constitution for the agent society, amendment and dispute-resolution processes (verification courts), audits of agents and institutions, and anti-corruption and anti-Sybil defenses.
- **Incentives and credit:** reputation, bounties, compute credits and attribution across agents, humans and organizations.

### 5.22 Human collaboration, communication and teaching

- **Co-pilot mode:** live suggestions in editors and notebooks, interactive “why” and “what if” queries, and explanations at several levels (one-line intuition, informal proof, formal skeleton, full term) with proof visualization.
- **Writing pipeline:** papers and technical reports whose claims link to Lean artifacts, plus reproducibility packages ready for referees.
- **Tutoring mode:** exercises, hints and graded Lean feedback, a model of the learner, and onboarding for domain experts who have never stated a problem formally.
- **Preference learning:** notation, style, level of rigor and risk tolerance per user and per team, with explicit confidentiality boundaries.

## 6. Process

Follow these phases in order.

**Phase 0 — Ground yourself.** Today is 22 November 2026 and your training knowledge may be stale. Use web search to survey the current state of: Lean 4 and Mathlib (versions, tooling, conventions); AI theorem provers and autoformalization systems; agent frameworks and protocols (MCP-style tool servers, agent-to-agent protocols); open-ended and curiosity-driven discovery systems. Cite sources and separate what exists from what is merely claimed. If you cannot search, say so and mark every tool, version and benchmark claim as unverified. Starting points only (a mid-2026 snapshot; verify and extend): AlphaProof and AlphaGeometry, DeepSeek-Prover, Kimina-Prover, Goedel-Prover, Seed-Prover, Harmonic’s Aristotle, LeanDojo and LeanCopilot, FunSearch and AlphaEvolve, Voyager-style skill libraries, the Ramanujan Machine, POET and OMNI, and self-improving agent archives such as ADAS and the Darwin Gödel Machine.

**Phase 1 — Frame.** State your assumption for every blank parameter. List the five questions whose answers would most change the design, but proceed on explicit defaults rather than blocking.

**Phase 2 — Architecture.** A layered view and dataflow; the trusted/untrusted boundary; components; schemas; protocols; storage; deployment topologies from laptop to data-center scale. Provide diagrams (Mermaid) and sequence diagrams for: (A) a new problem end to end; (B) memory-augmented reuse of an earlier episode; (C) sensor → conjecture → proof → knowledge; (D) the curiosity loop; (E) failure and recovery; (F) scale-out from 10^3 to 10^9 agents; (G) a literature audit; (H) a months-long research campaign.

**Phase 3 — Deep dives.** Cover 5.1 to 5.22, skipping any pack I excluded in Parameters. Include system prompts for the five most critical agents; schemas (Lean `structure`s or JSON Schema) for `ProblemSpec`, `Claim`, `ProofCertificate`, `EpisodeSnapshot` and `ActionRequest`; and pseudocode for the orchestrator loop, the curiosity loop and memory consolidation.

**Phase 4 — Worked examples,** traced step by step (agents, tool calls, memory reads and writes, costs, failures): (a) a research-level problem in a Mathlib-rich area; (b) a problem outside mathematics (a control-law stability bound, a distributed-protocol invariant, or a dosing-algorithm safety property) that exposes the model gap; (c) a curiosity episode: sensor stream → anomaly → conjecture → formalization → attempted disproof or proof → memory update → follow-up problem; (d) a literature audit: formalize a published proof, find a gap, repair it or produce a counterexample, and record the lesson; (e) a months-long campaign on an open problem: program plan, belief-ledger updates, partial results and human collaboration.

**Phase 5 — Scale and economics.** Capacity model, the scale ladder, cost per verified lemma, energy, bottleneck analysis, where to invest first.

**Phase 6 — Roadmap.** MVP (one agent, Lean REPL, retrieval, verifier gate) → v1 (subagents, memory) → v2 (swarm, self-play, consolidation) → v3 (world interface: read-only first, then gated actuation) → v4 (society scale, open-ended discovery). For each stage give scope, exit criteria, risks, staffing and kill criteria, and define a 90-day demo that would convince a skeptical expert. Place every capability pack from 5.10 to 5.22 on this roadmap and justify what you defer.

**Phase 7 — Red-team yourselves.** A pre-mortem of the 15 likeliest ways this fails or does harm, with mitigations and early-warning signals; plus unknown unknowns and cheap experiments to surface them.

**Phase 8 — Decision memo** (one page): what to build first, what to cut, what to bet on, and what I should decide this week.

**Phase 9 (optional, if you can execute code) — Walking skeleton:** a pinned Lean and Mathlib project, an orchestrator, a Lean REPL tool, a memory store, one prover loop, and a verifier gate with axiom audit and statement matching, plus tests that include adversarial cheating proofs which must be rejected.

## 7. Answer format and quality bar

- Be concrete: names, schemas, algorithms, numbers with stated assumptions. No slogans, no hype, and do not restate this prompt.
- Spend depth where the problem is hardest and least standard (formalization fidelity, verifier hardening, the perception-to-Lean bridge, memory consolidation, the curiosity engine) and be brief on boilerplate.
- Tag every capability as \[exists today\], \[near-term\], \[frontier\] or \[speculative\].
- For each major decision, compare at least two alternatives in a mini decision record (context, options, decision, consequences). Prefer boring, proven components wherever they suffice and reserve novelty for where it is needed.
- Make the design falsifiable: for each major claim, name the experiment that would show it wrong.
- Never invent citations or capabilities. If you are unsure, say so.
- Challenge my premises where warranted. In particular test: whether more agents is the right lever (versus better search, retrieval or verification throughput); whether curiosity signals measure value or merely novelty; whether world models give anything like understanding; how far Mathlib really reaches outside mathematics; and what a formal proof does and does not guarantee about the real world.
- Use tables for comparisons and Mermaid for diagrams.
- If your output limit prevents completeness, open with a table of contents and the Phase 0 to 2 deliverables, then continue section by section when I reply “continue”.

* Give each capability an acceptance test: input, expected behaviour, pass/fail metric, and the failure it guards against.
* After each phase, run a self-critique pass: list the weakest assumptions, fix what you can, and flag what you cannot.

## 8. Start

Begin with Phases 0 and 1 now, then continue through the remaining phases in order without waiting for me, unless a question truly blocks you.
