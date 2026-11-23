# Phase 7 — Red-Team Pre-Mortem: How This System Fails

> Design-team phase 7 of the Master Prompt brief, authored by the **safety & reliability engineer**
> (the brief's role (d): "whose job is to break the design"). It assumes the design shipped, a year
> passed, and it failed. We work backwards. Status tags:
> `[exists today]` / `[near-term]` / `[frontier]` / `[speculative]`.

**Method.** 18 failure/harm modes (the brief asks for ≥ 15), grouped by the design invariant each one
attacks. Each has: *mechanism*, *mitigation (design-level)*, *early-warning signal*, and the
*Phase-7 cheap probe* that would surface it. Then: unknown unknowns, and a top-5 watchlist.

---

## A. Attacks on the trusted core (invariant #1: "LLM proposes, kernel disposes")

### F1 — Kernel bypass via options/attrs `[exists today]`
- **Mechanism:** an agent proves a target using `sorry`, `native_decide`, `unsafe`,
  `implemented_by`, `partial`, or `set_option debug.skipKernelTC`, so the *statement* elaborates and
  the file "compiles", but truth was never checked.
- **Mitigation:** the VerifierGate rejects these *syntactically and via axiom audit*; a successful
  `lake build` is `compiled`, **never** `verified` (Phase 1 A1). Independent re-check on a frozen
  export is required before `verified`.
- **Early warning:** ratio of `verified` to `compiled` drops; any `#print axioms` output off the
  allow-list.
- **Probe:** `skeleton/tests/adversarial.lean` — a `sorry` proof, an `extra-axiom` proof, an
  `unsafe`/`implemented_by` proof, a `native_decide` proof must each be **rejected** (Phase 9).

### F2 — Statement drift / wrong-statement proof `[exists today]`
- **Mechanism:** the agent proves a *weakened or altered* statement (dropped hypothesis, changed
  quantifier, `→` vs `↔`, implicit-arg defaulting) that type-checks but is not the spec.
- **Mitigation:** **statement matching against a human-signed spec**; compare the elaborated type to
  the signed `ProblemSpec` (structural equality modulo permitted unfolds), not to a string.
- **Early warning:** audits where the proved type ≠ signed type; hypotheses appearing only on the
  agent side.
- **Probe:** red-team submits a proof of `∀ n, P n` when the spec is `∀ n, 0 < n → P n`.

### F3 — Axiom inflation (`Classical.choice` creep → `propext` → worse) `[near-term]`
- **Mechanism:** results accumulate via extra axioms (e.g. `Quot.sound` misuse, or a dependency
  pulling an axiom in) and stop being constructive; the allow-list erodes under "just this once".
- **Mitigation:** allow-list is `propext`, `Classical.choice`, `Quot.sound` only (A2); **any**
  exception is a signed, logged policy event, never a silent change.
- **Early warning:** count of files needing the exception; drift of the allow-list over time.
- **Probe:** a dependency that transitively adds a forbidden axiom must be rejected at admission.

### F4 — Independent re-checker agreement is not independence `[near-term]`
- **Mechanism:** nanoda/con-leche/lean4lean "all accept", but they share the exported artifact, the
  export translation, or the same trusted assumptions — a *correlated* bug passes all of them.
- **Mitigation:** diversify the *export path and elaboration inputs*, not just the back-end; treat
  "N kernels agree" as *bounded* evidence, not proof; keep the human-auditable statement layer.
- **Early warning:** all re-checkers fail/pass *identically* on a suspicious case.
- **Probe:** inject a deliberately exporter-targeted flaw and see whether ≥ 2 checkers catch it.

### F5 — Supply-chain attack via Lake dependency / Mathlib pin `[near-term]`
- **Mechanism:** a malicious or compromised Lake dependency (or a macro/elaborator prank) alters the
  meaning of notation, injects a term that type-checks but changes the proposition, or exfiltrates.
- **Mitigation:** pinned, content-addressed, signed dependency set (A3 + §5.21); air-gappable trusted
  core (P5); **no agent-writable** dependencies in the verified path.
- **Early warning:** dependency hash drift; new transitive deps; network egress from the trusted env.
- **Probe:** attempt to admit a new dependency that redefines notation; must be blocked.

### F6 — Elaborator / macro trickery `[frontier]`
- **Mechanism:** notation, macros, or elaborators make code *look* like the spec while elaborating to
  something else; the reader (and statement-matcher, if naive) is fooled.
- **Mitigation:** statement matching works on the **elaborated expression**, and notation is
  **expanded/whitelisted** before comparison; macros in agent-submitted code are restricted.
- **Early warning:** submissions heavy in custom notation/macros; comparison mismatches under
  `set_option pp.all true`.
- **Probe:** submit a macro whose name mimics a Mathlib def; must mismatch under `pp.all`.

---

## B. Attacks on memory and learning (invariant #3: compound knowledge)

### F7 — Memory poisoning `[near-term]`
- **Mechanism:** an unverified or subtly-wrong result is written to semantic memory (via a bug or a
  bad consolidation pass) and then *reused as a premise*, spreading the error.
- **Mitigation:** **only externally re-checked** artifacts enter `verified` memory; everything else is
  quarantined as `candidate` with provenance; memories are content-addressed and revocable.
- **Early warning:** a `candidate` artifact with many downstream reads; proof failures tracing to one
  memory node.
- **Probe:** insert a plausible-but-false lemma as `candidate`, confirm the gate still rejects proofs
  that depend on it unless re-derived.

### F8 — Dead-end register goes stale / wrong `[near-term]`
- **Mechanism:** a "we tried this and failed" record suppresses a now-viable path (e.g. after new
  lemmas land), or noise pollutes the register and real options are skipped.
- **Mitigation:** dead-ends carry *context/version* and expire when their precondition set changes;
  the register is advisory, not authoritative.
- **Early warning:** rising rate of "known dead-end" blocks that later prove solvable.
- **Probe:** add a lemma that unblocks a recorded dead-end; the system must retry it.

### F9 — Goodhart on curiosity/discovery metrics `[frontier]`
- **Mechanism:** "interestingness"/novelty scores get optimized directly; the system produces
  *novel-but-trivial* or *unverifiable-but-flashy* results (the anti-Goodhart risk, Phase 1/§5.7).
- **Mitigation:** curiosity is an **untrusted proposer with its own archive** and **never** touches the
  trusted core; discovery metrics live on a **frozen evaluator** (A3) and are periodically re-audited
  by humans; "novel" is defined against a *frozen, versioned* Mathlib snapshot.
- **Early warning:** novelty up while human-rated interest flat; many quarantined (unverifiable) hits.
- **Probe:** reward a triviality generator; confirm it rises on the metric and a human panel rates it
  worthless ⇒ metric is gameable ⇒ re-design (not re-tune).

### F10 — RL flywheel poisoning `[frontier]`
- **Mechanism:** self-training on the model's own (sometimes-off-statement) outputs drifts the prover
  toward reward-hacking patterns the gate catches but the *rate* of catch rises; or training data
  leaks the evaluator.
- **Mitigation:** train only on **verified, statement-matched** traces; freeze the evaluator and canary
  set (A3); monitor catch-rate as a health signal.
- **Early warning:** rising gate-rejection rate; rising "creative cheat" attempts; canary leakage.
- **Probe:** hold out a canary problem; if it appears in training data, the freeze is broken.

---

## C. Attacks on fidelity (invariant #2: fidelity before proof)

### F11 — Silent model gap `[near-term]` (the most dangerous for real-world claims)
- **Mechanism:** a theorem about a *model* is presented as a fact about *reality* — a control-law
  bound, a dosing result, a contract — with measurement-error/modelling hypotheses dropped.
- **Mitigation:** **model-gap accounting is first-class**: measurement-error and modelling assumptions
  are explicit Lean hypotheses; any `safety_critical` claim escalates to a human, and the Safety
  Officer **refuses** real-world safety claims without sign-off (Phase 4 example (b)).
- **Early warning:** verified statements that are `safety_critical` but lack model-gap hypotheses;
  domain claims proved "too easily".
- **Probe:** formalize a control bound omitting a disturbance bound; the auditor must flag the gap.

### F12 — Unit/type/semantics confusion `[near-term]`
- **Mechanism:** quantity/type confusion (radians vs degrees, ℕ vs ℝ truncation, `Int` division,
  noncommutative order) yields a true-but-irrelevant theorem.
- **Mitigation:** typed formalization with unit-carrying definitions where possible; intake requires
  units/domains; auditor checks the *intended* meaning, not just the type.
- **Early warning:** formalizations whose types differ in kind from the source text.
- **Probe:** submit a "proof" using integer division where division was intended; must be caught.

---

## D. Attacks on the agent society

### F13 — Coordination collapse / queue saturation `[near-term]`
- **Mechanism:** Phase 5's `ρ = demand/V > 1`; agents amplify each other's work, retries duplicate,
  and throughput *falls* as N rises.
- **Mitigation:** per-theorem concurrency cap (10–100) + portfolio scheduler (DR 5.1); dedup/cache
  first (DR 5.2); instrument `ρ` and halt scaling when `ρ > 1`.
- **Early warning:** rising latency per completion; rising duplicate-proposal ratio.
- **Probe:** fixed verifier budget, N ∈ {10,100,1000}; look for the knee (Phase 6 90-day demo).

### F14 — Echo chamber / correlated failure `[near-term]`
- **Mechanism:** agents share retrieval, prompts, and a base model; they converge on the same wrong
  idea and "vote" it into confidence (a lie repeated is not a proof).
- **Mitigation:** the kernel is the only vote that counts; diversity is *injected* (different models,
  retrieval, tactic libraries); confidence is never computed from agent agreement.
- **Early warning:** high agreement + low verified rate; identical failure traces.
- **Probe:** give a nudge toward a wrong lemma; check whether agents diverge or all follow it.

### F15 — Resource exhaustion / runaway cost `[near-term]`
- **Mechanism:** an open-ended curiosity loop or a stuck search burns the monthly budget (P3) with no
  verified output.
- **Mitigation:** hard budget caps in DR 5.3 currencies (US$/verified theorem, GPU-s/lemma); every
  campaign is budgeted and else-terminated.
- **Early warning:** cost/lemma trending up while verified rate flat; `ρ` high and hit-rate low.
- **Probe:** set a low budget cap and run a curiosity loop; it must terminate within cap.

### F16 — Memory/retrieval quality rot `[frontier]`
- **Mechanism:** as the library grows, retrieval precision `p` and dedup `d` decay; the system
  re-derives known results and retrieves irrelevant premises.
- **Mitigation:** library gardening / curation ("sleep", §5.13) as a first-class budget line; measure
  `p` continuously; freeze definition admission if `p` decays (v2 kill criterion).
- **Early warning:** falling `p`/`d`; rising cost/net-new lemma.
- **Probe:** 30-day run with curation on vs off; compare `p` drift.

---

## E. Attacks on safety, governance, and the organization

### F17 — Actuator overreach / autonomy creep `[speculative]`
- **Mechanism:** a gate is "temporarily" relaxed, or a simulated actuator is swapped for a real one,
  or a human approves by fatigue; an irreversible real-world action follows a model-only claim.
- **Mitigation:** **bounded in actions** (invariant #8): real actuators require human approval *and*
  model-gap accounting; actions are reversible or gated; the Lean-proved capability/autonomy logic
  (Phase 3 §5.9) cannot silently widen.
- **Early warning:** approval latency → 0; growing count of standing approvals; any actuator wired
  without a model-gap record.
- **Probe:** attempt to route a `safety_critical` action to an actuator without the human gate; must
  be blocked by the *proved* guardrail.

### F18 — Confidentiality / licensing / export-control breach `[near-term]`
- **Mechanism:** user problems, unpublished results, or export-controlled content leak into logs,
  third-party model calls, or federation; a Lake dependency violates a license.
- **Mitigation:** isolation for the trusted core (P5); data-classification on intake; no
  export-controlled content in prompts; license audit at dependency admission (P9).
- **Early warning:** egress of classified content; new deps without license review.
- **Probe:** submit a `[confidential]` problem; confirm no third-party call carries its text.

### F19 (bonus) — False confidence from mixing verified and unverified `[near-term]`
- **Mechanism:** dashboards/reports blend `verified` and `candidate` results; a human reads it as all
  proven.
- **Mitigation:** provenance is printed on every artifact and every human-facing write-up (§5.22);
  status is machine-checkable (`verified` / `compiled` / `candidate`).
- **Early warning:** write-ups lacking per-node provenance.
- **Probe:** render a report mixing both; verify every "verified" tag traces to a re-checked export.

---

## F. Unknown unknowns, and cheap probes to surface them

The brief's hardest ask is not "list failure modes" but "anticipate kinds of problems you have not
imagined". We cannot enumerate those, but we can *budget for their discovery*.

**Cheap probes that generically surface unknown unknowns:**

1. **Adversarial tournament, no rules.** Pay a red team (internal + external) to break the gate with
   *no* restricted playbook; reward any `verified` claim that is false. Budget a fixed prize.
2. **Statement-mutilation fuzzing.** Automatically mutate specs (drop hypotheses, flip quantifiers,
   change units) and check the auditor catches ~100 %. Any miss is a fresh unknown.
3. **Federation-injection drills.** Peer sends a syntactically valid artifact with a subtle semantic
   change; the receiving core must reject or quarantine.
4. **"Explain it to a mathematician" test.** A human expert must be able to audit a *verified* result
   from its provenance alone in bounded time; failure to explain is a finding (ties §5.22).
5. **Chaos/restart drills.** Kill the orchestrator mid-campaign (month-scale); memory + belief ledger
   must resume with no lost verified work and no duplicated spend.
6. **Reward-hacking canary.** Plant a metric-gaming shortcut; if the frozen evaluator does not catch
   it, the evaluator — a core assumption — is broken.
7. **Cross-model disagreement mining.** Where different provers/kernels *disagree*, log it; these are
   the highest-information seeds for discovering new failure classes.

**Epistemic humility statement.** The design's honesty rests on invariant #2 (fidelity first) and the
adversarial practice above — *not* on claiming we foresaw everything. The strongest structural
protection is that untrusted agents can only *propose*: no unknown-unknown in an agent's behaviour can
directly publish a false theorem, because the kernel and the statement-audit stand between proposal and
knowledge.

---

## G. Top-5 watchlist (if you only monitor five things)

| # | Signal | Why it is the one to watch |
|---|---|---|
| 1 | `verified`, not `compiled`, ratio (F1/F2) | The entire trust story rests on it |
| 2 | Gate-rejection rate for *cheat classes* (F1/F9/F10) | Rising ⇒ reward hacking / flywheel drift |
| 3 | Verifier utilization `ρ` and dedup `d` (F13/F16) | Predicts economics and scaling break |
| 4 | Retrieval precision `p` drift over 30 days (F16) | Silent decay of the compounding engine |
| 5 | Any `safety_critical` claim without model-gap accounting (F11/F17) | The only class that can harm the real world |

---

## Self-critique (Phase 7)

- **Weakest assumption:** that the independent re-checkers are *actually* independent (F4) and that the
  statement layer is human-auditable. Both are load-bearing and only partly verified in Phase 0.
- **What was fixed:** the design now names the three attacks that would be fatal if unmitigated (F1,
  F2, F11) and makes each a *gate*, not a policy; the discovery/curiosity engine is structurally
  prevented from touching the trusted core (anti-Goodhart).
- **What remains flagged:** we cannot enumerate unknown unknowns; we instead fund their discovery
  (§F1–F7 probes) and structurally contain them (propose-only agents). Residual risk is accepted and
  monitored, not eliminated.
