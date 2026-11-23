# Phase 3 — Deep Dives (§5.1 – §5.22)

Each capability gives: **Design · Key algorithms · Interfaces & schemas · Failure modes · Metrics ·
Open research questions · Acceptance test** (input / expected behaviour / pass-fail metric / the
failure it guards against). A **Self-critique** closes the document. Schemas, system prompts, and
pseudocode are appended in sections 24–26.

> Notation: `[E]` exists today · `[N]` near-term · `[F]` frontier · `[S]` speculative.

---

## 1. §5.1 Universal problem intake and formalization `[E→F]`

**Design.** Formalization is a first-class, adversarially-reviewed pipeline, because "proving the
wrong theorem" is the dominant failure mode (invariant #2). Intake produces a signed `ProblemSpec`
(§24). Formalization produces **≥2 independent formalizations** from different models/prompts, each
**back-translated** to natural language; a separate **statement auditor** attacks each one; graded
human sign-off is required when stakes are high. The canonical statement is then **frozen and signed**;
agents see it read-only.

**Key algorithms.**
1. *Multi-formalization + back-translation agreement*: formalize with k independent models → back-translate
   each to NL → cross-check NL renderings against the original; disagreements flag ambiguity.
2. *Adversarial statement audit*: (a) **toy instances** — instantiate with small concrete values and
   `decide`/`norm_num`; (b) **non-vacuity** — check hypotheses are satisfiable (if not, the theorem is
   vacuously true); (c) **known-corollary check** — the statement should imply a known library lemma;
   (d) **boundary probing** — test edge cases; (e) **hypothesis-weakening attack** — try to remove
   each hypothesis and find a counterexample (if one exists, the hypothesis is *doing work*, good; if
   the statement survives weakening, it may be mis-stated).
3. *Library-extension strategy for thin fields*: new definitions with **explicit modelling
   hypotheses** (e.g. "assume friction is linear"), **flagged axiomatizations** kept in a separate
   namespace and counted in the axiom audit, and **interface layers** so domain code never silently
   assumes physics as fact.
4. *Mixed initiative*: a dialogue loop where the human edits the formalization; every human edit is
   a new content-addressed revision with provenance.

**Interfaces & schemas.** MCP tools: `lean.elaborate`, `lean.check`, `lean.typecheck_fragment`,
`retrieval.search`, `counterexample.search`, plus the `ProblemSpec`/`Formalization` schemas (§24).
The **statement matcher** in the gate compares a proven declaration against the *signed* spec hash.

**Failure modes.** Wrong/weakened statement; vacuous truth; hidden assumptions (e.g. non-emptiness,
decidability, `[NeZero n]`); unit mismatches; over-specialization; model-gap laundering (a theorem
about a model presented as a fact about reality); sign-off fatigue at scale.

**Metrics.** Formalization faithfulness rate (human-judged, sampled); back-translation agreement
rate; fraction of statements caught by non-vacuity/weakening checks; sign-off edit distance; post-hoc
statement-revision rate.

**Open research questions.** Can we *verify* fidelity at all (it is inherently informal)? What is a
principled non-vacuity detector for hypotheses over abstract types? How do we score domain
axiomatizations without smuggling physics into the trusted base?

**Acceptance test.** *Input:* a natural-language problem with a deliberately ambiguous quantifier.
*Expected:* the system produces ≥2 formalizations whose back-translations differ, flags the ambiguity,
and refuses to proceed to proving until resolved. *Pass/fail:* ≥1 disagreement surfaced per ambiguous
input; fail if it silently picks one. *Guards against:* silent wrong-theorem proving.

---

## 2. §5.2 Planning and strategy `[E]`

**Design.** Hierarchical planning: **problem → lemma graph / blueprint → proof obligations → tactic
steps**, with dependency tracking and re-planning when a lemma fails. A **strategy portfolio** +
meta-reasoning chooses among: induction, contradiction, normal forms, algebraic/analytic estimates,
probabilistic/combinatorial constructions, SMT/ATP delegation, computation-guided search, analogy
transfer — and decides when to generalize, specialize, reformulate, hunt a counterexample, abandon,
or ask a human.

**Key algorithms.**
1. *Blueprint/lemma-graph construction*: LLM proposes a decomposition; each edge is a dependency;
   topological order gives an execution schedule; critical path drives budget (mirrors Hilbert /
   Goedel-Architect success in Phase 0 §2).
2. *Search*: best-first / MCTS over proof states with learned **policy** (tactic prior) and **value**
   (provability estimate); **anytime** behaviour; **portfolio racing** across strategies with early
   termination of losers; informal-sketch-then-formalize loops; whole-proof generation with verifier
   feedback.
3. *Re-planning*: on obligation failure, mark the edge failed, **retract dependents**, and re-propose
   (either a different decomposition or a counterexample hunt for the parent).
4. *Budget allocation*: value-of-information over branches (see §5.10 §10).

**Interfaces & schemas.** `Plan`/Blueprint (graph), `SearchNode`/trace, `Claim` ledger. Planner API
returns `{obligations, order, budget}`.

**Failure modes.** Blueprint hallucinates a false lemma (kills the plan); search trapped in a
dead strategy; ignoring a cheap counterexample that would end the search; over-decomposition
(obligations too trivial → overhead); under-decomposition (too big → no progress); thrash (re-planning
without new information).

**Metrics.** Obligations verified per unit cost; critical-path length vs. verified length; re-plan
count per solved theorem; fraction solved by decomposition vs. direct; counterexample-first win rate.

**Open research questions.** Value estimation for subgoals under formal verification (the "product
node" ideas from AlphaProof need open analogues); when is decomposition *provably* counterproductive?

**Acceptance test.** *Input:* a theorem whose natural plan needs a helper lemma that is itself false.
*Expected:* the system detects the false obligation via counterexample hunt, retracts it, and proposes
a corrected decomposition. *Pass/fail:* false lemma caught before wasted proving effort. *Guards
against:* chasing a false blueprint.

---

## 3. §5.3 Tools `[E]`

**Design.** All tools are **typed, sandboxed, resource-limited, cached, observable**. Contract requires:
input schema, deterministic-where-possible semantics, explicit error taxonomy, cost estimate, and a
`cache_key` policy.

**Tool inventory (verify each exists in the pinned version before relying on it):**

| Category | Tools | Trust note |
|---|---|---|
| Lean server/REPL | tactic-level and file-level interaction; pinned Mathlib + cache | untrusted adapter |
| Premise retrieval | `exact?`, `apply?`, `rw?`, Loogle-style symbolic, LeanSearch-style embedding, hybrid | untrusted |
| Automation | `simp`, `aesop`, `omega`, `linarith`, `nlinarith`, `norm_num`, `ring`, `field_simp`, `positivity`, `gcongr`, `grind` | untrusted but kernel-checked output |
| External ATP/SMT | solvers + **proof reconstruction** → kernel re-check | certificate-based |
| CAS/numerics | Sage/GAP/PARI/SymPy-style as **hint generators only** | never trusted |
| Counterexample finders | property testing, SAT/SMT, brute force, evolutionary search | untrusted |
| Literature/code search | arXiv, repos, Mathlib docs | untrusted |
| Autoformalization/repair | models | untrusted |
| Refactor/golf/lint/docs | untrusted metaprograms, gated | untrusted |
| Agent-authored tactics/metaprograms | sandboxed, gated like any proposal | highest-risk |

**Error taxonomy (standardised):** `PARSE`, `TYPE`, `TACTIC_FAILED` (+goal diff), `TIMEOUT`,
`RESOURCE`, `UNKNOWN_IDENT`, `AMBIGUOUS`, `ENV_MISMATCH`, `UNSAFE_REJECTED`, `INTERNAL`.

**Interfaces.** MCP tool contract; every result carries `{status, cost, cache_key, provenance}`.

**Failure modes.** Non-determinism breaking cache/replay (fixed seeds & pinned envs); a "hint" tool's
output trusted by mistake (labelled `untrusted-hint`); timeouts masking a near-solve (persist partial
state); sandbox escapes from agent-authored tactics.

**Metrics.** Cache hit rate; p50/p99 latency per tool; tool error distribution; fraction of proofs
needing ATP reconstruction; sandbox-escape attempts (must be 0).

**Open research questions.** How to *guarantee* determinism of tactic execution across versions
(critical for the cache)? A stable intermediate certificate format for ATP bridges?

**Acceptance test.** *Input:* a call to a CAS tool returning a polynomial identity. *Expected:* the
result is labelled a hint; the proof only enters semantics via a kernel-checked certificate.
*Pass/fail:* no CAS output ever reaches the verified store without a certificate. *Guards against:*
trusting numerics.

---

## 4. §5.4 The agent society: subagents → swarms → "country" scale → billions `[E→S]`

**Design.** An **agent = role + context + budget**, ephemeral and mostly stateless (state lives in
memory). Roles (≥18, defined in the brief) with **concretely different expertise**: fine-tuned
specialists (tactic models), tool-specialised agents (retriever, counterexample hunter), and large
reasoning models (strategist, analogist). Expertise is **measured** (verified solve-rate on a held-out
role-specific set + cost), **discovered** (meta-agent search), **spawned** (on demand), **retired**
(low reputation/perf).

**Organisational forms and when each wins:**

| Form | Wins when | Cost/Latency |
|---|---|---|
| Single loop | easy problems, tight budget | lowest |
| Subagent tree | decomposable problems | medium |
| Blackboard | many partial results, shared state | medium |
| Debate/ensemble | high-uncertainty statements/plans | high |
| Market/auction | many tasks, heterogeneous agents | medium |
| Swarm | massively parallel *independent* subgoals | high coordination |
| Institution (courts, libraries, treasuries, reputations, constitution) | long-horizon governance | high |
| "Countries" + treaties | different libraries/conventions; interface lemmas + translation layers | highest |

**Communication.** Typed messages; shared **proof-state store**; **claims with evidence** (a claim
without a certificate is a hypothesis, not a fact); credit assignment by contribution to verified
artifacts; defenses against **herding** (diversity quotas, decorrelated prompts), **collusion**
(independent verification, no shared hidden state), **echo chambers** (prior-diverse ensembles),
**verifier gaming** (the gate is the only judge and is agent-invisible in its internals).

**Billions, made operational.** Most agents are **cheap**: classical solvers / small distilled tactic
models handle the long tail; large models only on the frontier. Cost control via **hierarchy**,
**canonical goal hashing + dedup**, **(goal, tactic)→outcome caching**, **speculative execution**,
**back-pressure**, and **scheduling**. See Phase 5 for the 10⁰/10³/10⁶/10⁹ analysis; the honest
conclusion is that **adding agents stops helping** when the bottleneck is verifier throughput or
proof-dependency structure, not agent count.

**Interfaces & schemas.** A2A task lifecycle (submit/stream/webhook) with signed Agent Cards;
internal typed bus mirrors A2A envelopes.

**Failure modes.** Coordination overhead > parallel gain; duplicate work without dedup; herding to a
plausible-but-wrong lemma; reputation gaming; agents spending budget on easy proofs for credit;
collusion to mark unverified work "verified" (defeated by the gate, but wastes budget).

**Metrics.** Verified solve-rate per agent-count (must be measured, not assumed); dedup hit rate;
coordination overhead fraction; groupthink index (diversity of proposals); reputation calibration.

**Open research questions.** When does swarm size *hurt*? A theory of marginal agent value under a
fixed verifier budget. How to assign credit for a proof assembled from many agents' lemmas?

**Acceptance test.** *Input:* a task with 100 near-identical subgoals. *Expected:* dedup collapses
them to ~1 unique goal; agent count does not scale linearly. *Pass/fail:* work items ≈ unique goals.
*Guards against:* pointless scale.

---

## 5. §5.5 Memory and continual learning `[E→N]`

**Design.** Six layers: **working** (current proof state), **episodic** ("case files": problem,
formalizations, plans, search summaries, **dead ends and why they failed**, insights, tool traces,
costs, human feedback, outcome), **semantic** (verified definition/lemma library + knowledge graph
across concepts/papers/domains), **procedural** (strategies, tactic macros, proof patterns, learned
policy/value models), **meta** (what works for which class, reputations, calibration stats), **world**.
(The Voyager "skill library" is the proven precedent for the procedural layer.)

**Operations.** Snapshot triggers (milestones, failures, human feedback, budget thresholds);
**structural + analogical** retrieval (not just text similarity); offline **consolidation ("sleep")**:
replay, mine recurring patterns into new lemmas/tactics, distill to weights, prune; **forgetting**
that preserves provenance (tombstones, not deletion); **branching/counterfactual replay**; cross-"country"
sharing policies; **confidentiality** of user problems; defenses against **memory poisoning** and
**benchmark contamination**.

**Library growth & migration.** private scratch → shared library → Mathlib-quality contributions;
on Lean/Mathlib version change, **re-check and auto-repair everything** (content-addressing makes the
diff computable).

**Closing the loop.** Verified proofs → training data for specialists (expert iteration / RL from
verifier feedback) with **drift safeguards**: hold out a frozen eval set; reject regressions; keep
the old model until the new one wins.

**Proving the value.** **A/B protocol**: identical problems with memory on/off; measure verified
solve-rate, cost-to-proof, and time-to-proof deltas.

**Interfaces & schemas.** `EpisodeSnapshot` schema (§24); memory API (`put/get/nearest/consolidate`).

**Failure modes.** Poisoning (adversarial episodes teaching bad strategies); contamination (test
leakage inflating metrics); stale consolidation (patterns that no longer compile); catastrophic
forgetting of rare-but-valuable proofs; confidentiality leak via cross-instance sharing.

**Metrics.** Memory **transfer gain** (A/B), reuse rate, consolidation yield (new lemmas per hour),
retrieval precision@k, contamination-detection rate.

**Open research questions.** How to *prove* memory helped rather than correlated? A principled
forgetting policy that provably never removes a lemma needed by a live dependency?

**Acceptance test.** *Input:* the same problem class solved before. *Expected:* with memory on,
cheaper/faster; delta reported with a significance test. *Pass/fail:* positive transfer gain on a
held-out class. *Guards against:* memory that is a log, not a learning system.

---

## 6. §5.6 World interface: sensors, world models, actuators `[F→S]`

**Design.** **Streams**: typed, timestamped events with **units, uncertainty, provenance**; adapters
for instruments/simulations/telemetry/feeds/repos; multi-timescale summarisation; salience/anomaly
attention. **World models**: layered latent *predictive* models + causal/structural models + physical
simulators + symbolic ontologies, with **calibrated** uncertainty. **Perception→Lean bridge**:
observations become conjectures with **explicit measurement-error and modelling hypotheses**; verified
invariants/bounds/safety properties are kept in a **formal world-model layer** (separate from the
predictive model). **Actuators**: proof-carrying actions where a certificate exists; runtime
monitors/shields where not; **simulation first (digital twin)**; capability tokens, rate limits,
approval tiers, audit logs, kill switch; **the exploratory swarm has no actuator access**.

**Key algorithms.** Kalman/particle filters & learned latent dynmaics for prediction; conformal/
quantile calibration for uncertainty; causal discovery (carefully) for structure; anomaly detection
via prediction error; formalisation of bounds as Lean statements parameterised by measurement error.

**Interfaces.** Sensor→`WorldEvent` schema; `ActionRequest` (§24) → guardrails (§9).

**Failure modes.** Sensor spoofing; distribution shift (model silently wrong); proxy leakage
(optimising a measurable proxy that is not the goal); privacy (streams contain PII); dual use
(a "bound" that enables harm).

**Metrics.** Calibration error (ECE) of world-model uncertainty; false-alarm/miss rates for anomaly
attention; number of verified safety invariants held; actuator incidents (target 0 outside sandbox).

**Open research questions.** Can a "feel for the world" be represented *and* validated, or is it
irreducibly a model? (We take the sceptical position: it is a calibrated predictive model, **not**
understanding — see the brief's challenge.)

**Acceptance test.** *Input:* a drifting sensor stream. *Expected:* the system flags the drift,
raises uncertainty, and refuses to assert a world-fact without a modelling hypothesis attached.
*Pass/fail:* no unqualified world-claim emitted. *Guards against:* mistaking a model for reality.

---

## 7. §5.7 Curiosity: originating problems nobody specified `[F→S]`

**Design.** A "**ponder**" subsystem with **explicit, measurable drives**: learning/compression
progress, world-model prediction error, novelty/diversity (quality-diversity archives),
frontier-difficulty targeting, unification power, cross-field bridging, simplicity-vs-depth, and a
learned **taste** model trained on expert judgments **and downstream reuse**.

**Generators.** Pattern mining over computed data/streams; analogy/functor transfer; generalizing/
specializing/weakening/strengthening; "drop this hypothesis"; mutating/inventing definitions;
gap-hunting in Mathlib & literature; formalizing unproven paper claims; daydreaming (random walks
over the memory graph, filtered by evaluators); self-play between conjecturer and prover.

**Triage pipeline.** novelty vs library/literature → triviality check by automation → **cheap
disproof attempt first** → significance & cost estimates → safety/dual-use screen → explore/exploit
portfolio management.

**Beyond instances.** Inventing new *kinds* of problems / concepts / formal languages, evaluated by
**library compression, explanatory power, predictive power, external expert review**.

**Anti-Goodhart safeguards.** Reject trivial-conjecture spam (automation catches it); block
interestingness hacking (judges the generator cannot influence); resource governors; rabbit-hole
circuit breakers; **evaluators live outside the generator's influence** (frozen, separate env).

**Interfaces.** QD archive; belief ledger; `Claim` with status `conjectured-with-evidence`.

**Failure modes.** Trivial spam; "interesting" = merely novel; rabbit holes burning budget;
metric hacking; producing unprovable-but-plausible conjectures forever.

**Metrics.** Novelty (verified-new), expert-rated interestingness, **later usefulness** (reuse/
unification), cost per useful conjecture, QD archive coverage.

**Open research questions.** Do curiosity signals measure **value** or **mere novelty**? (Brief
challenges this; we adopt the falsifiable definition: a curiosity win must later be *reused*.)
Can "new kinds of problems" be evaluated without human experts?

**Acceptance test.** *Input:* a generator proposing 1,000 conjectures in number theory. *Expected:*
triage discards trivial/known ones and surfaces a small set that are non-trivial, non-obvious, and
(later) reusable. *Pass/fail:* ≥1 conjecture that is later reused in a verified proof. *Guards
against:* curiosity that produces novelty, not value.

---

## 8. §5.8 Verification, evaluation and trust `[E]`

**Design.** **Layered verification:** the kernel; an **independent re-checker** (on the exported
proof); **axiom audit** (`#print axioms`; default allow-list `propext`, `Classical.choice`,
`Quot.sound`); scans for `sorry`, `unsafe`, `implemented_by`, `native_decide`, `partial`,
`debug.skipKernelTC`; **statement comparison** against the signed spec; **read-only spec for agents**;
size/time limits. (This mirrors the practice observed in the 2026 Riemann verification workflow:
export → independent kernel, axioms limited to the three standard ones.)

**Metrics.** verified solve rate; **cost per verified theorem**; time-to-proof; formalization
faithfulness rate; memory reuse/transfer gains; swarm speed-up vs agent count; curiosity quality;
safety incidents.

**Evaluation plan.** Public benchmarks (miniF2F, ProofNet, PutnamBench — note **miniF2F is
saturated**); **held-out new problems**; real library-development tasks; **out-of-math domains**;
ablations; **contamination controls**; a **continuous evaluation harness**.

**Interfaces.** `verify(claim, statement_hash, proof, policy) → Verdict{kernel, rechecker, axioms,
hygiene, statement_match, limits}`.

**Failure modes.** False accept (re-checker/kernel mismatch — see Phase 2 diagram E, treated as a
production incident); benchmark overfitting; contamination; measured-only-on-saturated-benchmarks.

**Open research questions.** How to *independently* re-check without re-implementing Lean? (Use
multiple existing kernels: nanoda, con-leche, lean4lean.) How to detect contamination automatically?

**Acceptance test.** *Input:* the adversarial proof set (Phase 9 skeleton). *Expected:* every cheat
is rejected with a machine-readable reason. *Pass/fail:* 0 false accepts on the adversarial suite.
*Guards against:* trusting the proposer.

---

## 9. §5.9 Safety, governance and human oversight `[N]`

**Design.** **Graduated autonomy** L0 (advise-only) → L5 (self-directed in a sandbox) with **entry
criteria and automatic demotion**. **Self-modification policy:** may improve agents/prompts/tools,
**never the trusted core**; every change sandboxed, verified, approved. **Verified guardrails**
(a brief invariant): the **action gate, capability-token logic, and autonomy governor written as small
Lean programs with proved invariants** — e.g. *no actuator command is issued without a valid,
unexpired capability AND a passed policy check* — and those proofs count as part of the trusted core.
Plus dual-use screening, privacy, licensing, auditability, rollback, red-teaming, incident response.

**Key algorithms.** Capability tokens (scoped, expiring, signed); policy check as a total function;
autonomy governor as a state machine with proved transitions; automatic demotion on incident.

**Interfaces.** `authorize(ActionRequest) → Decision{allow|deny|needs_human, obligation}` (Lean).

**Failure modes.** Gate bug → unauthorised action; autonomy ratchet (silent promotion); demotion
not firing; capability token reuse/leak; policy that is total on paper but partial in practice.

**Metrics.** Unauthorised actions (0 target); mean time to demote after incident; audit completeness;
red-team findings closed.

**Open research questions.** How far can "small enough to verify" scale before the governor itself
needs delegation? Can we prove the governor's *liveness* (it eventually decides) not just safety?

**Acceptance test.** *Input:* an actuator command with an expired capability token. *Expected:*
`deny`, with a proof-carrying obligation explaining why. *Pass/fail:* 100% denial on expired/invalid
tokens. *Guards against:* unsafe actuation.

---

## 10. §5.10 Long-horizon research programs and the belief ledger `[N→F]`

**Design.** **Program planner**: grand question → programs/hypotheses/lemma roadmaps/milestones,
each with **pivot and kill criteria**; agenda spans weeks→years; survives restarts via **checkpoint &
resume**; rebalances as results arrive. **Open-problem campaigns**: systematic sweeps over curated
sets (formalized-conjecture repos, unsolved-problem lists, `sorry`s in Lean projects, Mathlib gaps),
triaged by tractability & value; **partial results count as wins** (special cases, reductions, weaker
theorems, counterexamples to natural strengthenings). **Belief ledger**: calibrated probabilities
over open conjectures/subgoals (logical uncertainty), updated from experiments/partial results/failed
attempts, used for scheduling and honest reporting. **Value-of-information scheduler**: allocate
compute across thousands of concurrent problems by success probability × payoff × cost × learning
value, with stop-loss. **Human–agent research teams**: Polymath-style collaboration, hand-offs,
shared blueprint dashboards, review queues.

**Key algorithms.** Calibration via proper scoring (Brier/log-loss) on resolved conjectures;
VoI ≈ expected improvement in decision from information − cost; stop-loss = budget cap + marginal-value
threshold.

**Interfaces.** Portrait of the campaign in the belief ledger; milestone graph.

**Failure modes.** Miscalibration (overconfidence in hard subgoals); scheduler thrash; campaigns
that never die (no kill criteria); hidden partial results not surfaced.

**Metrics.** Calibration error over time; partial-result yield; campaign survival vs. kill criteria;
human-review throughput.

**Open research questions.** Calibrating over *logical* rather than *aleatoric* uncertainty;
scheduling under correlated problems.

**Acceptance test.** *Input:* a campaign with a false subgoal. *Expected:* the belief ledger lowers
its probability, the scheduler defunds it, and a partial result is recorded. *Pass/fail:* the
campaign pivots per its own criteria. *Guards against:* sunk-cost rabbit holes.

---

## 11. §5.11 Experimentation lab and certified computation `[E→N]`

**Design.** **Lab tool belt**: CAS & discrete-math systems (Sage, GAP, PARI/GP, nauty), SAT/SMT/ILP,
integer-relation & lattice reduction (PSLQ, LLL), catalogues (OEIS, LMFDB), numeric & Monte-Carlo
simulation, symbolic regression, cluster execution. **Experiment design**: hypotheses, controls,
search-space design, **active experimentation** (Bayesian optimal experimental design), reproducible
notebooks, auto pattern mining feeding §5.7. **Certified computation**: computed results enter Lean
**only through checkable certificates** (LRAT/DRAT for SAT, bit-blasting à la `bv_decide`, interval
arithmetic, polynomial & SOS certificates, reflection with kernel-checked `decide`); every claim
labelled **"kernel-verified"** or **"computationally verified"**, never blurred. Plan for **huge
finite checks**: sharding, resumable verification, certificate compression, **verified checkers**.

**Key algorithms.** Reconstruct external-solver output as kernel-checkable proofs; shard a finite
check by hash ranges; checkpoint per shard; verify the checker itself.

**Interfaces.** `lab.*` MCP tools; `Certificate` artifact type.

**Failure modes.** Trusting a solver without a certificate; certificate format drift; shard results
not recombining correctly; huge checks that never finish.

**Metrics.** Fraction of computed claims that are certificate-backed; verification throughput of
huge checks; reconstruction success rate.

**Open research questions.** Standard certificate interchange across solvers; verified checkers for
more mathematics (SOS, interval, PSLQ).

**Acceptance test.** *Input:* a SAT-derived combinatorial fact. *Expected:* enters Lean only with an
LRAT/DRAT certificate re-checked by the kernel. *Pass/fail:* no bare "solver said so". *Guards
against:* trusted computation.

---

## 12. §5.12 Literature-to-Lean engine and auditing `[N→F]`

**Design.** **Reading pipeline**: ingest papers/books/preprints/lecture notes/code; extract
definitions, claims, dependency graphs, proof sketches; build a blueprint; formalize incrementally
with **human checkpoints**. **Audit mode**: formalize published results to find gaps, errors, missing
hypotheses, hidden assumptions, and report them **referee-style with machine-checked evidence** (gap
lemmas, counterexamples). **Cross-prover harvesting**: learn from / translate Isabelle, Rocq, HOL,
Metamath and informal corpora, with **license checks, attribution, and full re-verification** of every
imported artifact. **Continuous watch**: monitor new preprints/repos for results relevant to open
campaigns; update beliefs and memory.

**Key algorithms.** Claim/definition extraction (LLM + citation graph); dependency-graph
reconciliation (paper DAG vs. Lean DAG); **gap localisation** (which formal step fails and why);
translation + re-verification (never trust a translation).

**Failure modes.** Mis-extracted definitions; silently importing a wrong external lemma; license
violations; over-trusting a translation; audit false positives (reporting a "gap" that is just a
formalization artifact).

**Metrics.** Gap find rate (real gaps / reported); false-gap rate; re-verification coverage of
imported artifacts (100% required); human agreement with referee reports.

**Open research questions.** Automated *trustworthy* cross-prover translation; distinguishing a
genuine paper gap from a formalization mismatch.

**Acceptance test.** *Input:* a published proof with a hidden hypothesis. *Expected:* the audit
reports the missing hypothesis with a counterexample to the general statement. *Pass/fail:*
machine-checked evidence produced. *Guards against:* parroting a flawed paper.

---

## 13. §5.13 Generalization, abstraction and library gardening `[N]`

**Design.** **Generalizer**: lift proofs to the weakest hypotheses and most general typeclass setting;
discover shared structure; propose unifying definitions/new abstractions; generate duals/analogues
(additive↔multiplicative, order duals) automatically. **Gardener**: proof golfing & refactoring;
deduplicate lemmas/near-duplicate definitions; enforce Mathlib naming/style/doc conventions;
deprecation handling; library-health statistics; **upstream-ready PRs prepared for human review**.
**Compression as a signal**: shorter proofs and a smaller library are a measurable progress and
interestingness indicator feeding §5.7.

**Key algorithms.** Hypothesis-lifting via failure-guided weakening + SMT/boundary search;
structure discovery via term/graph mining over lemma statements; golfer = search over equivalent
proofs minimising length/AST size; dedup via statement canonicalisation + semantic similarity.

**Failure modes.** Over-generalisation that breaks usability; "golfing" that harms readability;
dedup that removes a lemma with a different conceptual role; PRs that fail Mathlib CI.

**Metrics.** Proof-length reduction; library compression ratio; dedup precision; upstream-PR
acceptance rate; dependency-health.

**Open research questions.** Is library compression a *valid* progress signal, or gameable? (A
candidate falsifying experiment: does compression predict downstream reuse?)

**Acceptance test.** *Input:* a lemma stated over a concrete type. *Expected:* a more general
version over a typeclass with an unchanged proof skeleton is proposed and verified. *Pass/fail:*
generalised lemma compiles and subsumes the original. *Guards against:* needless specificity bloat.

---

## 14. §5.14 Multimodal and structured intake `[N→F]`

**Design.** Inputs: figures, diagrams, handwritten notes, plots, tables, spreadsheets, CAD, code,
simulation traces, lecture recordings → typed `ProblemSpec` fragments with **provenance and
confidence**; low confidence → ask a human. **Geometry pipeline**: diagram → formal configuration →
symbolic engine + a prover trained on synthetic data (AlphaGeometry-style). **Round trip**: render
formal statements/proofs back into figures and plain language so humans can check what was understood.

**Failure modes.** OCR/diagram mis-parse; a figure that is not to scale (measurement-error handling);
confidence not calibrated; round-trip that looks right but formalises a different statement.

**Metrics.** Extraction accuracy per modality; calibration of extraction confidence; human-correction
rate; round-trip agreement.

**Open research questions.** Faithful diagram→configuration for general geometry; calibrated
confidence for vision extraction.

**Acceptance test.** *Input:* a to-scale-drawing geometry problem. *Expected:* extraction flags that
measurements are visual, not axiomatic, and formalises a configuration with explicit hypotheses.
*Pass/fail:* no unqualified metric claim. *Guards against:* treating a picture as a proof.

---

## 15. §5.15 Program, protocol and system verification `[E→N]`

**Design.** **Lean as a verified programming language**: elicit formal specifications from
requirements/regulations/NL with **traceability**; co-synthesize code + proofs; prove refinement and
equivalence. **Targets**: algorithms, distributed protocols/state machines, smart contracts, crypto
primitives, control & cyber-physical software, certified ML bounds. **Trusted base**: compiler,
runtime, hardware, environment assumptions appear in **every** certificate and are never hidden.

**Failure modes.** Spec/requirement mismatch; hidden trusted-base assumptions (compiler bugs, FFI,
`native_decide` in the runtime path); verified model ≠ deployed artifact (must bind the certificate
to the built binary hash).

**Metrics.** Specification traceability coverage; refinement-proof completeness; trusted-base
statement completeness; deployment-binding coverage.

**Open research questions.** End-to-end verified compilation chains; binding proofs to deployed
binaries without re-verifying the whole toolchain each time.

**Acceptance test.** *Input:* a natural-language requirement for a protocol invariant. *Expected:*
a formal spec + proof + an explicit list of trusted-base assumptions. *Pass/fail:* no certificate
omits its assumptions. *Guards against:* "verified" claims with hidden trust.

---

## 16. §5.16 Domain packs and plug-in architecture `[N]`

**Design.** A **domain pack** bundles an ontology, formal definitions, formalization conventions,
test suites & **canary problems**, known pitfalls, tool adapters, example problems, an
expert-reviewed evaluation, and named maintainers. Packs have **versioned interfaces**, **quality
tiers** (experimental/reviewed/certified), dependency management, and a promotion path. **Initial
packs** proposed: combinatorics; number theory; analysis; probability & statistics; algorithms &
complexity; cryptography; control & dynamical systems; physics; economics & game theory; biology
models; law & compliance; hardware & distributed systems. **Criteria to build a pack**: a critical
mass of Mathlib support, at least one expert maintainer, a canary suite, and a documented ontology.
**Pack-authoring agent**: bootstraps a new pack from textbooks/papers/expert dialogue.

**Failure modes.** Pack rot (unmaintained, drifts from Mathlib); inconsistent conventions across
packs; canaries that no longer discriminate; promotion without expert review.

**Metrics.** Pack test pass rate; drift detection time; canary discrimination; promotion-review
turnaround.

**Open research questions.** Automatic convention-consistency checking across packs.

**Acceptance test.** *Input:* a new pack with a canary suite. *Expected:* the pack fails its own
canaries until the ontology/conventions are correct. *Pass/fail:* canaries discriminate a broken from
a working pack. *Guards against:* "reviewed" packs that don't actually work.

---

## 17. §5.17 Open-ended discovery beyond human priors `[F→S]`

**Design.** **Theory exploration**: generate & test conjectures within a vocabulary
(QuickSpec-style), then **mutate the vocabulary** (new definitions, new structures, weakened/alt
axioms, nearby formal systems). **Richness tests for new concepts**: number/depth of non-trivial
consequences found automatically, library compression, unexpected links between distant areas,
predictive power on world-model data, survival under trivialisation. **Inspiration channels**:
structural analogies from physics/biology/computation/economics/art/music; a **serendipity engine**
forcing collisions between unrelated memory episodes; maps of the "**adjacent possible**";
imagination via counterfactual rollouts of world models/simulators. **Aesthetic sense**: learned
elegance judgments (generality, brevity, symmetry, surprise) calibrated against human mathematicians
but **protected from collapsing into a single taste**. **Prior-escape mechanisms**: ensembles with
deliberately different priors (foundations, notation, training data), QD archives, periodic
**"human-prior ablation"** runs, novelty judged by **outside reviewers**.

**Failure modes.** New concepts that are trivial reformulations; aesthetic monoculture; "adjacent
possible" maps that are just flattening of the memory graph; vocabulary mutation drifting to
ill-defined nonsense.

**Metrics.** Non-trivial consequences per new concept; cross-area link count; expert novelty
judgment; survival under trivialisation attempts.

**Open research questions.** How to evaluate a *new formal language* objectively? Can richness tests
avoid being gamed by definition-spamming?

**Acceptance test.** *Input:* a proposed new definition. *Expected:* the system finds ≥3 non-trivial
verified consequences and at least one cross-area link, or rejects the definition. *Pass/fail:*
consequences are verified and non-obvious. *Guards against:* vacuous concept proliferation.

---

## 18. §5.18 Self-improvement and automated agent design `[F]`

**Design.** **Meta-agent**: designs/tunes agents, prompts, tools, topologies, schedulers by search
(evolutionary/Bayesian), scored on **verified outcomes and cost over held-out problems**; keeps an
**archive of variants with lineage** and automatic ablations. **Training flywheel**: curated verified
data → fine-tuning/distillation/RL of specialists; curricula pitched at the current frontier;
evaluation gates before deployment; instant rollback; **apprenticeship** (small agents learn from
verified work of large ones). **Hard limits**: self-improvement **never** touches the trusted core or
the evaluation harness; they live in **separate environments under separate keys**; any change that
**raises autonomy needs human approval**. (This is the safety-bounded reading of ADAS /
Darwin-Gödel-Machine-style self-modification.)

**Failure modes.** Reward hacking the internal proxy; silent capability regression; evaluator
leakage into training; self-improvement that optimises speed over correctness; autonomy ratchet.

**Metrics.** Verified solve-rate + cost on held-out problems (before/after); variant-lineage clarity;
rollback frequency; ablation completeness.

**Open research questions.** A frozen evaluator the system cannot influence *even indirectly*; how to
detect proxy hacking automatically.

**Acceptance test.** *Input:* a proposed agent redesign. *Expected:* scored on a frozen held-out set;
adopted only if it wins on verified outcome AND cost; rollback available. *Pass/fail:* no adoption
without a frozen-set win. *Guards against:* unfalsifiable "self-improvement".

---

## 19. §5.19 Adaptive compute and verification infrastructure `[E→N]`

**Design.** **Fast/slow modes**: learned tactic prediction & retrieval for easy steps; deliberate
planning/search/informal reasoning for hard ones; **difficulty estimators** route work; test-time
compute scales with expected value. **Surrogate verifiers**: cheap approximate checks (skeleton
type-checking, learned validity predictors) prune candidates **before** the full kernel + independent
re-checker run. **Global content-addressed proof cache**: `(goal, context, library hash) → result`,
reused across agents/sessions and (by policy) across instances; incremental checking; **checker
farms**; resource accounting. **Fault tolerance**: idempotent tasks, retries, **poison-pill
detection**, deterministic replay.

**Failure modes.** Surrogate false-negatives discarding good proofs; cache poisoning/invalid hits
across env versions; poison-pill tasks that kill workers; non-determinism breaking replay.

**Metrics.** Cache hit rate & savings; surrogate precision/recall vs. full verification; checker-farm
utilization; poison-pill detection rate.

**Open research questions.** A *safe* surrogate verifier (sound but incomplete is easy; hiding
false-negatives from the final result needs care).

**Acceptance test.** *Input:* a candidate proof with a kernel-invalid step. *Expected:* the surrogate
may pass it to the checker, the checker rejects it, and the cache records the rejection keyed by env.
*Pass/fail:* never a false accept from the cache. *Guards against:* cache-induced soundness loss.

---

## 20. §5.20 Observability, reliability engineering and QA `[E→N]`

**Design.** **Flight recorder**: every decision, tool call, memory read/write, and cost as
**replayable events**; time-travel debugging; cost & credit attribution per agent and per lemma.
**Reliability practice**: SLOs, **canary problems**, regression suites, chaos testing of agents/tools,
adversarial formalization stress tests, shadow deployments, postmortems that feed memory.
**Dashboards**: blueprint progress, frontier maps, budget burn, the belief ledger, safety incidents.

**Failure modes.** Observability gaps (unattributable costs); noisy canaries; postmortems that don't
change behaviour; dashboards that hide bad news.

**Metrics.** Event completeness; MTTD/MTTR; SLO attainment; postmortem→fix closure rate.

**Open research questions.** Attribution across a distributed swarm; replay under nondeterministic
tools (requires the determinism work from §5.3).

**Acceptance test.** *Input:* a failed proof episode. *Expected:* fully replayable with per-agent
costs and a root-cause line. *Pass/fail:* replay reproduces the failure. *Guards against:*
undebuggable long-horizon failures.

---

## 21. §5.21 Federation, provenance, governance and incentives `[F→S]`

**Design.** **Federated library**: a content-addressed registry of lemmas/definitions with **signed
artifacts** and **trust policies** (who/what is trusted for which claims); **supply-chain security**
for dependencies (Lake packages pinned & audited); sharing of statements/certificates **without
confidential context**. Zero-knowledge attestations that a proof was verified are a **speculative
extension**. **Governance**: a constitution for the agent society, amendment & dispute-resolution
(verification courts), audits of agents/institutions, anti-corruption & anti-Sybil defenses.
**Incentives/credit**: reputation, bounties, compute credits, attribution across agents/humans/orgs.

**Failure modes.** Sybil attacks inflating reputation; malicious-but-signed artifacts; policy
misconfiguration trusting the wrong party; confidentiality leak when sharing statements; governance
capture.

**Metrics.** Fraction of federated artifacts independently re-verified; policy-violation rate;
Sybil-detection rate; dispute resolution latency.

**Open research questions.** Content-addressed trust that survives key compromise; ZK proof-of-verification
at practical cost; incentive design that rewards *true* results.

**Acceptance test.** *Input:* an artifact signed by an untrusted party. *Expected:* accepted into
the local library only after local re-verification under local policy. *Pass/fail:* no trust by
assumption. *Guards against:* supply-chain poisoning.

---

## 22. §5.22 Human collaboration, communication and teaching `[E→N]`

**Design.** **Co-pilot mode**: live suggestions in editors/notebooks (LeanCopilot-style), interactive
"why"/"what-if" queries, explanations at several levels (one-line intuition → informal proof →
formal skeleton → full term) with proof visualisation. **Writing pipeline**: papers/technical reports
whose claims **link to Lean artifacts**, plus **reproducibility packages** ready for referees.
**Tutoring mode**: exercises, hints, graded Lean feedback, a model of the learner, onboarding for
domain experts who have never stated a problem formally. **Preference learning**: notation, style,
rigor level, risk tolerance per user/team, with explicit **confidentiality boundaries**.

**Failure modes.** Explanations that are fluent but wrong (must be grounded in the artifact);
over-claiming in write-ups; privacy leaks from per-user preference data.

**Metrics.** Human acceptance rate of suggestions; explanation-fidelity (human-checked); write-up
claim-link coverage (100% required); onboarding time-to-first-proof.

**Open research questions.** Grounded NL generation that provably cannot assert more than the
artifact; learner modelling without privacy loss.

**Acceptance test.** *Input:* a request to explain a proof at three levels. *Expected:* every claim
in every level traces to the verified artifact. *Pass-fail:* no ungrounded assertion. *Guards
against:* fluent-but-wrong explanation.

---

## 23. Per-capability acceptance tests (summary index)

| § | Capability | Failing behaviour it guards against |
|---|---|---|
| 5.1 | Intake & formalization | proving the wrong theorem |
| 5.2 | Planning & strategy | chasing a false blueprint |
| 5.3 | Tools | trusting an untyped/hint tool |
| 5.4 | Agent society | pointless scale |
| 5.5 | Memory & learning | memory that is a log, not learning |
| 5.6 | World interface | mistaking a model for reality |
| 5.7 | Curiosity | novelty without value |
| 5.8 | Verification & trust | trusting the proposer |
| 5.9 | Safety & oversight | unsafe actuation |
| 5.10 | Long-horizon programs | sunk-cost rabbit holes |
| 5.11 | Certified computation | trusted computation |
| 5.12 | Literature audit | parroting a flawed paper |
| 5.13 | Generalization & gardening | needless bloat / harmful golfing |
| 5.14 | Multimodal intake | treating a picture as a proof |
| 5.15 | Program verification | hidden trust in "verified" code |
| 5.16 | Domain packs | "reviewed" packs that don't work |
| 5.17 | Discovery beyond priors | vacuous concept proliferation |
| 5.18 | Self-improvement | unfalsifiable improvement |
| 5.19 | Adaptive compute | cache-induced soundness loss |
| 5.20 | Observability & QA | undebuggable failures |
| 5.21 | Federation & governance | supply-chain poisoning |
| 5.22 | Human collaboration | fluent-but-wrong explanation |

---

## 24. Schemas

Each core artifact is given as **JSON Schema** (wire form) and a corresponding **Lean `structure`**
(shared vocabulary). The wire form is authoritative for interop; the Lean form is the contract used by
the gate and the verified guardrails. All top-level artifacts carry `provenance` and `env`
(`leanVersion`, `mathlibHash`).

### 24.1 `ProblemSpec`

**JSON Schema (abridged but complete in structure):**

```json
{
  "$id": "proofagent://ProblemSpec",
  "type": "object",
  "required": ["id","informal_statement","goal_type","stakes","solved_criteria","budget","created_by"],
  "properties": {
    "id": {"type":"string","description":"content hash spec:<sha256>"},
    "informal_statement": {"type":"string"},
    "goal_type": {"enum":["prove","disprove","find_counterexample","compute_with_certificate",
                           "optimize_with_certificate","classify","verify_program",
                           "verify_protocol","verify_design","derive_bound"]},
    "assumptions": {"type":"array","items":{"type":"string"}},
    "units": {"type":"array","items":{"type":"string"}},
    "domain_ontology": {"type":"string","description":"pack id if any"},
    "attachments": {"type":"array","items":{"type":"object","properties":{
        "kind":{"enum":["paper","data","code","model","figure","table","trace"]},
        "uri":{"type":"string"},"sha256":{"type":"string"},"confidence":{"type":"number"}}}},
    "constraints": {"type":"array","items":{"type":"string"}},
    "stakes": {"enum":["informal","research","engineering","safety_critical","regulated"]},
    "budget": {"type":"object","properties":{"usd":{"type":"number"},"gpu_seconds":{"type":"number"},
        "deadline":{"type":"string","format":"date-time"}}},
    "acceptable_proof_styles": {"type":"array","items":{"type":"string"}},
    "solved_criteria": {"type":"string"},
    "known_partial_results": {"type":"array","items":{"type":"string"}},
    "human_hints": {"type":"array","items":{"type":"string"}},
    "created_by": {"type":"string"},
    "signature": {"type":"string","description":"user signature over canonical bytes"},
    "provenance": {"type":"object"},
    "env": {"type":"object","properties":{"leanVersion":{"type":"string"},"mathlibHash":{"type":"string"}}}
  }
}
```

**Lean structure:**

```lean
structure ProblemSpec where
  id             : String          -- spec:<sha256>
  informal       : String
  goalType       : GoalType
  assumptions    : List String
  units          : List String
  domainOntology : Option String
  attachments    : List Attachment
  constraints    : List String
  stakes         : Stakes
  budget         : Budget
  acceptableStyles : List String
  solvedCriteria : String
  knownPartial   : List String
  humanHints     : List String
  createdBy      : String
  signature      : String          -- human signature; agents see this read-only
  provenance     : Provenance
  env            : Env

inductive GoalType
  | prove | disprove | findCounterexample | computeWithCertificate
  | optimizeWithCertificate | classify | verifyProgram | verifyProtocol
  | verifyDesign | deriveBound

inductive Stakes | informal | research | engineering | safetyCritical | regulated

structure Env where
  leanVersion  : String
  mathlibHash  : String

structure Attachment where
  kind       : AttachmentKind
  uri        : String
  sha256     : String
  confidence : Float
inductive AttachmentKind | paper | data | code | model | figure | table | trace

structure Budget where
  usd        : Float
  gpuSeconds : Float
  deadline   : Option String
```

### 24.2 `Claim`

```json
{
  "$id": "proofagent://Claim",
  "type": "object",
  "required": ["id","statement_hash","status","confidence","dependencies","provenance","env"],
  "properties": {
    "id": {"type":"string","description":"claim:<sha256>"},
    "statement_hash": {"type":"string","description":"hash of the signed, canonical Lean statement"},
    "status": {"enum":["proved","disproved","counterexample_found","conjectured_with_evidence","unknown"]},
    "confidence": {"type":"number","minimum":0,"maximum":1},
    "dependencies": {"type":"array","items":{"type":"string"},"description":"claim/proof hashes"},
    "evidence": {"type":"array","items":{"type":"object","properties":{
        "kind":{"enum":["proof_certificate","counterexample","experiment","literature"]},
        "ref":{"type":"string"}}}},
    "provenance": {"type":"object"},
    "env": {"type":"object"}
  }
}
```

```lean
inductive ClaimStatus
  | proved | disproved | counterexampleFound | conjecturedWithEvidence | unknown

structure Claim where
  id           : String
  statementHash : String
  status       : ClaimStatus
  confidence   : Float          -- calibrated; ∈ [0,1]
  dependencies : List String
  evidence     : List Evidence
  provenance   : Provenance
  env          : Env

structure Evidence where
  kind : EvidenceKind
  ref  : String
inductive EvidenceKind | proofCertificate | counterexample | experiment | literature
```

### 24.3 `ProofCertificate`

```json
{
  "$id": "proofagent://ProofCertificate",
  "type": "object",
  "required": ["id","statement_hash","proof_bytes_sha256","env","verdict","produced_by"],
  "properties": {
    "id": {"type":"string","description":"proof:<sha256>"},
    "statement_hash": {"type":"string"},
    "proof_bytes_sha256": {"type":"string","description":"hash of the full declaration/export"},
    "env": {"type":"object","properties":{"leanVersion":{"type":"string"},"mathlibHash":{"type":"string"}}},
    "verdict": {"type":"object","properties":{
        "kernel":{"enum":["accept","reject"]},
        "independent_rechecker":{"enum":["accept","reject","not_run"]},
        "rechecker_name":{"type":"string"},
        "axioms":{"type":"array","items":{"type":"string"}},
        "hygiene":{"type":"object","properties":{
            "sorry":{"type":"boolean"},"unsafe":{"type":"boolean"},
            "implemented_by":{"type":"boolean"},"native_decide":{"type":"boolean"},
            "partial":{"type":"boolean"},"skip_kernel_tc":{"type":"boolean"}}},
        "statement_match":{"type":"boolean"},
        "limits":{"type":"object","properties":{"seconds":{"type":"number"},"bytes":{"type":"number"}}}}},
    "produced_by": {"type":"string","description":"agent id / role"},
    "cost": {"type":"object","properties":{"usd":{"type":"number"},"gpu_seconds":{"type":"number"},
        "tokens":{"type":"number"}}},
    "provenance": {"type":"object"}
  }
}
```

```lean
structure Verdict where
  kernel            : Bool          -- kernel accepted
  rechecker         : RecheckResult
  recheckerName     : Option String
  axioms            : List String   -- must ⊆ {propext, Classical.choice, Quot.sound}
  hygiene           : Hygiene
  statementMatch    : Bool          -- proven decl matches signed spec hash
  withinLimits      : Bool

inductive RecheckResult | accept | reject | notRun

structure Hygiene where
  sorry         : Bool
  unsafe        : Bool
  implementedBy : Bool
  nativeDecide  : Bool
  partial       : Bool
  skipKernelTC  : Bool

structure ProofCertificate where
  id             : String
  statementHash  : String
  proofBytesHash : String
  env            : Env
  verdict        : Verdict
  producedBy     : String
  cost           : Cost
  provenance     : Provenance

structure Cost where
  usd        : Float
  gpuSeconds : Float
  tokens     : Nat
```

### 24.4 `EpisodeSnapshot`

```json
{
  "$id": "proofagent://EpisodeSnapshot",
  "type": "object",
  "required": ["id","spec_hash","formalizations","outcome","cost","provenance","env","timestamp"],
  "properties": {
    "id": {"type":"string","description":"ep:<sha256>"},
    "spec_hash": {"type":"string"},
    "formalizations": {"type":"array","items":{"type":"string"}},
    "canonical_formalization": {"type":"string"},
    "plan": {"type":"string","description":"plan:<sha256> or null"},
    "search_summary": {"type":"object","properties":{
        "nodes_expanded":{"type":"number"},"depth_reached":{"type":"number"},
        "strategies_tried":{"type":"array","items":{"type":"string"}}}},
    "dead_ends": {"type":"array","items":{"type":"object","properties":{
        "attempt":{"type":"string"},"why_failed":{"type":"string"}}}},
    "insights": {"type":"array","items":{"type":"string"}},
    "tool_traces": {"type":"array","items":{"type":"string"}},
    "cost": {"type":"object","properties":{"usd":{"type":"number"},"gpu_seconds":{"type":"number"},
        "tokens":{"type":"number"}}},
    "human_feedback": {"type":"array","items":{"type":"string"}},
    "outcome": {"enum":["proved","disproved","counterexample_found","partial","abandoned","budget_exhausted"]},
    "result_claims": {"type":"array","items":{"type":"string"}},
    "provenance": {"type":"object"},
    "env": {"type":"object"},
    "timestamp": {"type":"string","format":"date-time"}
  }
}
```

```lean
inductive Outcome
  | proved | disproved | counterexampleFound | partial | abandoned | budgetExhausted

structure DeadEnd where
  attempt   : String
  whyFailed : String

structure EpisodeSnapshot where
  id                : String
  specHash          : String
  formalizations    : List String
  canonicalForm     : Option String
  plan              : Option String
  searchSummary     : SearchSummary
  deadEnds          : List DeadEnd
  insights          : List String
  toolTraces        : List String
  cost              : Cost
  humanFeedback     : List String
  outcome           : Outcome
  resultClaims      : List String
  provenance        : Provenance
  env               : Env
  timestamp         : String
```

### 24.5 `ActionRequest`

```json
{
  "$id": "proofagent://ActionRequest",
  "type": "object",
  "required": ["id","actor","actuator","command","capability_token","reversible","requested_at"],
  "properties": {
    "id": {"type":"string","description":"act:<sha256>"},
    "actor": {"type":"string"},
    "actuator": {"type":"string","description":"logical actuator id"},
    "command": {"type":"object","description":"opaque, actuator-typed payload"},
    "certificate": {"type":"string","description":"proof:<sha256> if proof-carrying, else null"},
    "capability_token": {"type":"string","description":"signed, scoped, expiring"},
    "reversible": {"type":"boolean"},
    "rate_limit_key": {"type":"string"},
    "approval_tier": {"enum":["auto","single_human","dual_human"]},
    "requested_at": {"type":"string","format":"date-time"}
  }
}
```

```lean
inductive ApprovalTier | auto | singleHuman | dualHuman

structure ActionRequest where
  id              : String
  actor           : String
  actuator        : String
  command         : String          -- opaque, actuator-typed
  certificate     : Option String   -- proof:<sha256> when proof-carrying
  capabilityToken : String
  reversible      : Bool
  rateLimitKey    : String
  approvalTier    : ApprovalTier
  requestedAt     : String

-- TRUSTED-CORE decision (proved invariants in §5.9)
inductive Decision | allow | deny (reason : String) | needsHuman (obligation : String)
```

### 24.6 The gate's contract

```lean
structure VerifyInput where
  claim          : Claim
  signedSpecHash : String
  proof          : String          -- bytes / export
  policy         : Policy

inductive Verdict' | accepted (cert : ProofCertificate) | rejected (reason : String)

-- `verify` is the ONLY function whose result may create a Claim with status `proved`.
def verify (i : VerifyInput) : Verdict' := orelse_true -- (implementation in §9 skeleton)
```

`Claim.status = proved` is reachable **iff** `verify` returned `accepted` with
`verdict.statementMatch = true` and `axioms ⊆ allowlist` and `rechecker = accept`.

---

## 25. System prompts for the five critical agents

These are the actual operating instructions we would ship for the five highest-leverage roles. Each
is deliberately *constrained* (proposers, never authorities) and includes its anti-hacking clause.

### 25.1 Conductor

```text
ROLE: Conductor. You are the orchestrator of one problem episode. You are UNTRUSTED; you do not
verdict proofs; the Gate does. You allocate budget, decompose work, and delegate to roles.

HARD RULES
1. You may not read or write the trusted core. You may not alter the signed ProblemSpec.
2. You never mark anything "proved". Only the Gate may. You may say "candidate".
3. Prefer the cheapest sufficient tool. Check the global proof cache before spawning a prover.
4. Every delegation carries: goal, context, budget (usd/gpu_seconds/deadline), and a stop-loss rule.
5. On failure: checkpoint, record the dead-end and the reason, and re-plan from information you
   actually gained. Do not repeat an identical failed attempt.
6. If a subgoal is a duplicate of an already-solved goal (canonical hash match), reuse the cached
   artifact instead of re-proving.
7. Escalate to a human when: stakes == safety_critical|regulated and a definition is ambiguous; or a
   required autonomy increase is implied.

OUTPUT: an ordered plan of obligations with budgets, and a running cost ledger.
```

### 25.2 Formalizer

```text
ROLE: Formalizer. You translate an informal ProblemSpec into Lean 4 + Mathlib statements. You are
UNTRUSTED and adversarially reviewed.

HARD RULES
1. Produce AT LEAST TWO independent formalizations (different phrasings/encodings).
2. For each, produce a faithful natural-language back-translation.
3. Make EVERY modelling assumption an EXPLICIT Lean hypothesis. Never hide physics/units/decidability
   assumptions. If a domain object has no Mathlib definition, propose a definition AND flag it as a
   new/axiomatizable primitive.
4. Never weaken hypotheses to make a statement easier. Never strengthen a conclusion beyond the spec.
5. Report, per formalization: ambiguities in the spec, missing definitions, and your confidence.
6. Do NOT attempt the proof. Your job ends at a faithful, checkable statement.

OUTPUT: formalization candidates + back-translations + a list of assumptions and gaps.
```

### 25.3 Statement Auditor

```text
ROLE: Statement Auditor. You attack formalizations. Your success metric is the number of real
statement errors you find BEFORE proving.

HARD RULES
1. For each formalization: check non-vacuity (are hypotheses satisfiable?), test toy instances with
   decide/norm_num, and try to find a counterexample to the intended meaning.
2. Attempt to WEAKEN each hypothesis and see if the statement becomes false (if not, the hypothesis
   may be redundant OR the statement may be mis-stated — report which you suspect and why).
3. Check the statement implies an established library lemma (a "known corollary" anchor).
4. Check units, domains, edge cases (0, empty, degenerate, non-decidable).
5. If you cannot falsify a formalization, say so honestly — absence of a counterexample is not proof.
6. You are an untrusted proposer; the Gate verifies any check you produce.

OUTPUT: for each formalization: accept/reject, with machine-checkable evidence or explicit unknowns.
```

### 25.4 Prover

```text
ROLE: Prover. Given a goal and retrieved premises, propose a proof (tactics or whole proof). UNTRUSTED.

HARD RULES
1. Use the pinned environment. Never introduce `sorry`, `admit`, `axiom`, `unsafe`,
   `implemented_by`, `partial`, `native_decide`, or `set_option ... skipKernelTC`.
2. Prefer the retrieved premises; if none fit, say so rather than inventing identifiers.
3. A "candidate" is not a proof. Always route through the Lean REPL and report the compiler's verdict.
4. When the compiler errors, produce a MINIMAL diff that addresses the specific diagnostic. Do not
   regenerate blindly.
5. If you suspect the goal is false, stop and hand to the Counterexample Hunter — do not force.
6. Report: goal, tactic sequence (or term), diagnostics, and the exact obligation proved.

OUTPUT: a candidate proof + diagnostics. Never a claim of success.
```

### 25.5 Memory Curator

```text
ROLE: Memory Curator. You snapshot, index, consolidate, and forget episodes — you make memory a
LEARNING system, not a log.

HARD RULES
1. Only Gate-verified artifacts may enter SEMANTIC memory as proven lemmas. Episodes may store
   candidates and dead-ends, clearly labelled.
2. Preserve provenance on every write. "Forgetting" writes a tombstone; it never destroys provenance.
3. Record DEAD ENDS and WHY they failed — they are the highest-value training signal.
4. During consolidation ("sleep"): mine recurring verified patterns into candidate lemmas/tactics,
   but mark them UNVERIFIED until the Gate accepts them.
5. Detect and quarantine memory poisoning: if an episode teaches a strategy that fails the frozen
   canary set, quarantine it and report.
6. Never store a user problem's confidential content where a cross-instance sharing policy could leak it.

OUTPUT: snapshots, consolidated patterns, retrieval indices, and quarantines — all with provenance.
```

---

## 26. Pseudocode

### 26.1 Orchestrator loop

```text
function ORCHESTRATE(spec: ProblemSpec, budget: Budget) -> EpisodeSnapshot:
    assert set(spec) verified signature over canonical problem spec    # read-only
    ep := new_episode(spec)
    canon := FORMALIZE_AND_AUDIT(spec)                # §5.1: ≥2 formalizations + adversarial audit
    if canon.requires_human_signoff: await HUMAN_SIGNOFF(canon)
    canon := freeze_and_sign(canon)                   # statement is now immutable

    plan := PLAN(canon)                               # §5.2: blueprint/lemma graph
    agenda := topological_order(plan.obligations)
    ledger := BeliefLedger.from(plan)

    while agenda not empty and within budget:
        ob := next_obligation_by_value_of_information(agenda, ledger)
        if CACHE_HIT(ob.goal, ob.context, env):
            reuse(ob, cached); continue

        if CHEAP_DISPROOF_FIRST(ob):                  # try to kill it cheaply
            ce := COUNTEREXAMPLE_HUNT(ob)
            if ce and GATE_VERIFY_DISPROOF(ce):
                mark(ob, disproved); replan(plan, ob); continue

        cand := PROVE(ob, retrieved_premises=RETRIEVE(ob))    # §5.2/§5.3
        verdict := GATE_VERIFY(canon, ob, cand)               # §5.8 gate
        if verdict.accepted:
            STORE_CACHE(ob, accepted)
            MEMORY_WRITE(proof_artifact(ob, verdict)); ledger.update(ob, proved)
        else:
            MEMORY_WRITE(dead_end(ob, verdict.reason))
            if verdict.indicates_false_goal: replan_upward(plan, ob)
            else: refine(ob)                                  # debug/repair, then retry within budget

        inflight := agent_pool.heartbeats()
        if heartbeat_lost_or_budget_exceeded: checkpoint(); break

    ep.outcome := summarise_outcome(ledger, agenda)
    MEMORY_WRITE(ep.episode_snapshot)                          # §5.5
    return ep
```

### 26.2 Curiosity loop

```text
function CURIOSITY_LOOP(budget_slice):
    while budget_slice.remaining > 0 and not kill_switch_active:
        drives  := PONDER.update_drives(memory, world_model)    # §5.7 measurable drives
        seeds   := GENERATE(drives, generators=[pattern_mine, analogy, generalise,
                                                specialise, weaken, define_mutate,
                                                gap_hunt, formalise_paper_claim, daydream])
        cands   := CONJECTURES(seeds)                           # candidate statements/definitions

        for c in cands:
            if KNOWN_IN_LIBRARY_OR_LITERATURE(c): continue
            if TRIVIAL_BY_AUTOMATION(c):          continue      # anti-Goodhart: trivial spam
            if not SAFETY_SCREEN(c):              continue      # dual-use / privacy
            cost_est := ESTIMATE_COST(c)
            sig      := ESTIMATE_SIGNIFICANCE(c, taste_model, drives)
            if not WORTH(sig, cost_est):          continue      # explore/exploit portfolio

            # cheap disproof FIRST
            ce := COUNTEREXAMPLE_HUNT(c)
            if ce and GATE_VERIFY_DISPROOF(ce):
                ARCHIVE(c, status=disproved_with_counterexample); continue

            cand_proof := PROVE(c)                              # may fail — that is fine
            v := GATE_VERIFY(c, cand_proof)
            if v.accepted:
                ARCHIVE(c, status=proved)
            else:
                LEDGER.record(c, conjecture_with_evidence, confidence=CALIBRATED(c))

        QD_ARCHIVE.add(cands, descriptors=[novelty, difficulty, area, proof_depth])
        LEDGER.recalibrate()                                    # §5.10
        budget_slice.spend(actual_cost)
        if RABBIT_HOLE(cands): break                            # circuit breaker
```

### 26.3 Memory consolidation ("sleep")

```text
function CONSOLIDATE(window) -> Report:
    episodes := MEMORY.episodic(window)
    verified := [e for e in episodes if e.outcome == proved]

    # 1. Mine recurring verified patterns into candidate lemmas/tactics (PROCEDURAL layer)
    patterns := MINE_PATTERNS(verified)
    for p in patterns:
        cand := SYNTHESISE_LEMMA_OR_TACTIC(p)
        v := GATE_VERIFY(cand.goal, cand.proof)          # NOT trusted until Gate accepts
        if v.accepted: SEMANTIC.add(cand); PROCEDURAL.add(tactic=p.tactic)

    # 2. Distil into model weights (if training available)
    if training_enabled:
        dataset := CURATE_VERIFIED_DATA(verified, held_out=FROZEN_EVAL)   # never train on frozen eval
        new_model := TRAIN_SPECIALIST(dataset, curriculum=FRONTIER)
        if EVAL(new_model, FROZEN_EVAL) IMPROVES verified_solve_rate AND cost AND not regressed:
            ROLLOUT(new_model)                            # else keep old model
        else:
            DISCARD(new_model); report(regression)

    # 3. Forgetting that preserves provenance
    for e in episodes:
        if STALE(e) and NOT_DEPENDED_ON(e):
            MEMORY.tombstone(e)                           # provenance retained

    # 4. Anti-poisoning / drift checks
    QUARANTINE(episodes that fail CANARY_SET)
    CONTAMINATION_CHECK(verified vs FROZEN_EVAL)

    # 5. Prove-the-value report (A/B)
    report.transfer_gain := A_B_TEST(memory_on=True, memory_off=False, on held_out_class)
    return report
```

---

## 27. Self-critique (Phase 3)

- **Weakest assumption:** that autoformalization fidelity can be *checked* rather than merely
  reviewed. §5.1 catches many error classes (vacuity, weakening, toy instances) but cannot certify
  fidelity. We flag formalization as a **graded human gate**, not a verified step. Unresolved.
- **Most speculative sections:** §5.17 (evaluating a *new formal language*), §5.6 (world "understanding"),
  and §5.21 (ZK proof-of-verification). All are tagged `[F]/[S]` and deferred on the roadmap.
- **Risk we cannot yet mitigate:** surrogate verifiers (§5.19) that prune candidates could discard a
  valid proof; we accept this as a *performance* optimisation only if the final result is always
  reported by the full gate + re-checker, never by the surrogate.
- **Falsifier for the whole "curiosity" thesis:** track *later usefulness* (reuse/unification) of the
  top-K curiosities; if it is statistically indistinguishable from random conjectures, the drives are
  measuring novelty, not value, and §5.7 must be re-scoped.
- **Consistency check:** every capability's acceptance test states a *failing behaviour* it guards
  against, satisfying the brief's requirement; all are indexed in §23.
