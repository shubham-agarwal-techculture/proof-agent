# Phase 4 — Worked Examples (a–e)

Each trace lists: **agents**, **tool calls**, **memory reads/writes**, **costs**, **failures**.
Costs are illustrative order-of-magnitude figures with stated assumptions (not measured). Concrete
Lean identifiers are **illustrative**; names in the pinned Mathlib are a re-verify item (Phase 0).

Assume the environment pin: **Lean `<L>` + Mathlib `<M>`** (to be fixed at build time), gate = kernel
+ independent re-checker (nanoda/con-leche/lean4lean-class) + axiom allow-list + statement match.

---

## (a) Research-level problem in a Mathlib-rich area

**Problem (spec).** Prove a weighted Vandermonde-type identity that is *not* directly in Mathlib:
for all `n : ℕ`,

  `∑ k in range (n+1), (choose n k)^2 * k = n * choose (2*n-1) (n-1)`  (illustrative).

Goal type = prove; stakes = research; budget = US$25, GPU 2h.

| # | Actor | Action | Tools | Memory | Cost (cum.) |
|---|---|---|---|---|---|
| 1 | Workbench | Build `ProblemSpec`; sign | — | write `spec:<h>` | $0 |
| 2 | Formalizer | 2 formalizations: (i) `Finset.sum` over `range`, (ii) `Nat.choose` recursion form; back-translations | `lean.elaborate`, `retrieval.search` | read `spec`, write `form:i`, `form:ii` | $0.30 |
| 3 | Statement Auditor | Non-vacuity: hypotheses none → OK; toy instance `n=3`: `LHS=3·9+3·9+9 = ...` check via `norm_num`/`decide`; anchor: implies unweighted Vandermonde (known) | `lean.check`, `counterexample.search` | read `form:*` | $0.60 |
| 4 | Human | Sign-off (low stakes → auto-approved by policy, logged) | — | write signed canonical `form:i` | $0 |
| 5 | Strategist | Blueprint: goal → (5a) `k·C(n,k)=n·C(n-1,k-1)` pointwise; (5b) apply Vandermonde; (5c) combine | planner | read semantic: `Nat.choose` lemmas | $0.80 |
| 6 | Librarian | Retrieve: `Nat.choose`, `Nat.mul_choose_eq`, `Finset.sum_...`, `Nat.sum_range_choose` | `retrieval.search` (symbolic+embedding) | read semantic | $0.90 |
| 7 | Prover (cheap 7B) | Attempt 5a pointwise: **fails** — off-by-index (`k=0` term) | Lean REPL | write dead-end | $1.20 |
| 8 | Debugger | Diagnosis: `k=0` contributes 0; need `k·C(n,k)=n·C(n-1,k-1)` for `k≥1`, plus split sum | Lean REPL | read dead-end | $1.40 |
| 9 | Prover (large) | 5a→5b→5c; `Finset.sum_range_succ'` + `Nat.mul_choose_eq` + `Finset.sum_congr`; whole proof compiles | Lean REPL | — | $3.10 |
| 10 | **Gate** | kernel OK; hygiene OK; axioms = `{propext, Classical.choice, Quot.sound}`; statement match vs signed hash OK; **independent re-check accept** | re-checker CLI | write `proof:<h>`, `Claim{proved}` | $3.20 |
| 11 | Memory Curator | Snapshot episode: dead-end (the `k=0` pitfall), insight (`split off zero term`), reuse tag | memory | write `ep:<h>` | $3.20 |

**Failure surfaced & valuable:** the cheap prover's indexing error is recorded as a **reusable
dead-end** ("when summing `k·C(n,k)`, split `k=0` first"). Consolidation later turns this into a
**tactic macro** `sum_mul_choose_split`.

**Cost:** ~$3.20 and ~14 min GPU; **verified** at step 10. **Falsifier for the claim "memory helps":**
re-run the *same* problem with memory disabled; if the dead-end is re-encountered at equal cost, the
transfer gain is zero.

---

## (b) Outside mathematics — a control-law stability bound (exposes the model gap)

**Problem.** A team asserts: *"Our discrete-time controller is safe because the state norm decays."*
Informal: plant `x_{k+1} = A x_k + B u_k`, `u_k = -K x_k`, so closed loop `x_{k+1} = (A - B K) x_k`.
They want: **for all initial `x_0`, `‖x_k‖ ≤ C ρ^k ‖x_0‖`** with `ρ < 1`, and an explicit certified
bound on `ρ` and `C` given interval uncertainty in `A`.

Goal type = derive_bound + verify_program; stakes = **safety_critical**; budget = US$200, GPU 6h.

| # | Actor | Action | Notes |
|---|---|---|---|
| 1 | Formalizer | Formalise the *model*, not the plant: `A`, `B`, `K` as matrices over `ℝ`; `x` as function `ℕ → ℝⁿ`; assumptions: **`ρ` is a certified bound with interval uncertainty `A ∈ [A_lo, A_hi]`**; **explicit measurement + model-error hypotheses** | **Model gap is explicit**: the theorem is *about the model* |
| 2 | Statement Auditor | Rejects a first formalization that silently changes `≤` to `<`, and one that omits the `k=0` case (`C` must dominate the initial term). Also flags that "safe" was never defined → asks human | Human defines "safe" = the decay bound holding. **Gate → human escalation fires** |
| 3 | Experimentalist | Interval arithmetic over the box `[A_lo, A_hi]`: compute worst-case spectral radius bound; produce an **interval certificate** (not trusted yet) | `lab.interval` |
| 4 | Prover | Prove the Lyapunov-type bound using a certified matrix inequality (SOS/interval certificate) reconstructed as a kernel-checkable proof | ATP/SMT bridge + `nlinarith` |
| 5 | **Gate** | Kernel + re-check accept; axioms OK; **statement match vs signed spec** confirms the bound matches the *model*. Certificate records **trusted-base assumptions**: numerical interval library, floating-point tie rules, the *assumption that the plant equals the model*. | This is the crux |
| 6 | Memory Curator | Record the episode AND a **model-gap record**: `assumes: plant = model(A,B,K)` | |
| 7 | Safety Officer | Report to humans: *"The verified bound is a fact about the model. Deployment safety additionally requires (i) validating `A ∈ [A_lo,A_hi]` against the real plant, (ii) a runtime monitor/shield because actuators are gated."* | **Refuses to claim real-world safety** |

**The model gap, made concrete.** The system proves
`⊢ ∀ x₀, ‖x_k‖ ≤ C ρᵏ ‖x₀‖  under hypotheses {interval A, model=plant}`
and **labels it** `kernel-verified (about the model)`. It never emits "the controller is safe". The
Safety Officer's report is the human-facing artifact; actuation requires a capability token + shield
(§5.6/§5.9). **Failure avoided:** the dominant failure mode here is not a false proof — it is
**proving the wrong theorem about the world**.

---

## (c) Curiosity episode: sensor → anomaly → conjecture → proof/disproof → memory → follow-up

| # | Actor | Action | Tools | Memory | Cost |
|---|---|---|---|---|---|
| 1 | Stream adapter | Ingest telemetry: a sequence of counts `a_n` with a subtle drift in the ratio `a_{n+1}/a_n` | `sensor.*` | write `WorldEvent` | $0.02 |
| 2 | World model | Prediction error spikes; anomaly attention fires; flag `ratio → ≈ φ` (golden ratio) | — | read/write world memory | $0.05 |
| 3 | Curiosity (ponder) | Drive: world-model prediction error + novelty. Draft conjecture: *"the ratios are partial quotients converging to a fixed algebraic number"* — **with measurement-error hypotheses** | generators | read semantic | $0.20 |
| 4 | Formalizer | Formalise: `∃ α, (Ratio sequence) → α` over `ℝ`, plus an explicit hypothesis that the observed data is within `ε` of the model | `lean.elaborate` | write `form` | $0.30 |
| 5 | Triage | Novelty: not in library/literature (checked) → keep; triviality: not trivial; **cheap disproof first** | `retrieval.search`, `counterexample.search` | — | $0.35 |
| 6 | Counterexample Hunter | Numerically finds the sequence actually converges to **√2**, not φ → conjecture (as stated, with φ implied) is **false** | `lab.numeric`, `lab.pslq` | write dead-end | $0.60 |
| 7 | Curiosity (revise) | Update: conjecture becomes *"converges to √2"*; re-triage; **cheap disproof again** fails to refute | — | — | $0.65 |
| 8 | Prover | Prove convergence to √2 (a nontrivial but tractable real-analysis lemma, given the recurrence) | Lean REPL, ATP | — | $2.40 |
| 9 | **Gate** | accept; axioms OK; statement match OK | re-checker | write `proof`, `Claim{proved}` | $2.50 |
| 10 | Memory Curator | Record: verified claim + the *wrong-φ* dead-end + the modelling hypothesis. Belief ledger: conjecture→proved | memory | write `ep`, update ledger | $2.50 |
| 11 | Curiosity (follow-up) | Serendipity engine collides this episode with a stored quadratic-irrational-continued-fractions episode → proposes a **general follow-up**: *"which recurrences of form X have ratios converging to a fixed quadratic irrational?"* → new program (§5.10) | — | write new `ProblemSpec` seed | $2.55 |

**Value check (anti-Goodhart).** The ✓ claim must later be **reused** (e.g., cited by the general
follow-up) to count as a curiosity *win*, not mere novelty.

---

## (d) Literature audit: formalize a published proof, find the gap

| # | Actor | Action | Tools | Memory | Cost |
|---|---|---|---|---|---|
| 1 | Literature scout | Ingests a paper proving a theorem `T` with a lemma `L` whose stated hypotheses omit a regularity condition | reading pipeline | write extracted claims | $0.40 |
| 2 | Blueprint builder | Reconstructs the paper's dependency DAG: `T ← L ← M` | — | write `plan` | $0.50 |
| 3 | Formalizer | Formalises `T`, `L`, `M` as stated in the paper; each step traced to a citation | `lean.elaborate` | write `form` | $1.10 |
| 4 | Prover | Proves `M` ✓; **`L` fails to prove as stated** | Lean REPL | write dead-end | $2.00 |
| 5 | Counterexample Hunter | Finds a counterexample to `L` **as stated** (a degenerate case the paper hand-waved) → the gap is **real**, not a formalization artifact | `lab` + Lean | write counterexample | $2.80 |
| 6 | Generalizer | Proposes the **missing hypothesis** `h`; `L` with `h` becomes provable | Lean REPL | — | $3.20 |
| 7 | Prover | Proves `L_sealed = L ∧ h`; then `T` follows | Lean REPL, ATP | — | $4.60 |
| 8 | **Gate** | verifies: (i) counterexample to `L` (disproof claim), (ii) `L ∧ h` proof, (iii) `T` proof. All accepted, axioms OK | re-checker | write certificates + claims | $4.80 |
| 9 | Explainer | Writes a **referee-style report**: "Lemma `L` requires hypothesis `h`; without it, counterexample `<h>`. With `h`, `T` is verified." | — | write report | $5.00 |
| 10 | Memory Curator | Record lesson: "papers often omit regularity hypotheses for degenerate cases" → feeds the Statement Auditor's heuristics | memory | write | $5.00 |

**Failure avoided:** parroting a flawed paper. **Machine-checked evidence:** the counterexample is a
verified Lean term; the repair is a verified lemma.

---

## (e) Months-long campaign on an open problem

**Setting.** A curated open conjecture `C` (from a formalized-conjecture repo), stakes = research,
budget = US$60k over ~3 months, human PI in the loop.

**Week 1 — program plan.**
- Program planner decomposes `C` into hypotheses `H1…H7`, each with a **lemma roadmap** and
  **pivot/kill criteria**.
- Belief ledger initialises `P(C) = 0.08` (from literature + expert prior), each `P(Hi)`.
- VoI scheduler allocates the first tranche of compute to `H3` (highest expected information per US$).

**Weeks 2–6 — partial results (counted as wins).**
- `H3` proves a **special case** (e.g. `n` even). Gate verifies. Ledger: `P(C) → 0.11`.
- `H5` attempt yields a **reduction** to a known theorem. Ledger update; VoI shifts budget.
- `H2` is **disproved as stated**; the Generalizer proposes a corrected `H2'`; ledger re-balances.
- A `sorry` in an external Lean project (spotted by gap-hunting) is closed en route.

**Weeks 7–10 — the slog.**
- `H7` resists; three dead strategies recorded. VoI scheduler **defunds** it (stop-loss). Ledger:
  `P(C) → 0.09`. **This is a scheduled pivot, not a failure.**
- Human PI contributes an insight from a recent talk → `H7'` reformulated; budget re-allocated.

**Weeks 11–13 — human collaboration & write-up.**
- Polymath-style review queue: PI + 2 collaborators review the blueprint dashboard.
- Partial results packaged with **Lean links**; reproducibility package prepared for referees.

**Outcome (honest reporting).** `C` still open; **five verified partial results** shipped; belief
ledger accurately tracked (falsifiable: Brier score over resolved subgoals is reported). Campaign
survives restarts via checkpoint/resume (Phase 2 diagram H). **Cost:** ~US$41k of the US$60k budget;
the remainder is not spent because the VoI scheduler found no tractable path — **not spending budget
is a success**, per the stop-loss design.

---

## Cross-example self-critique

- **(a)** assumes Mathlib contains the needed intermediate lemmas; if it does not, the cost triples
  and the library-extension strategy (§5.1) engages. Illustrative names are flagged.
- **(b)** is the most important example: it shows the system **cannot and must not** claim real-world
  safety; the deliverable is a *verified model bound* + a *model-gap record* + a *runtime shield*.
- **(c)/(d)/(e)** all count **partial and negative results** as first-class outcomes, matching §5.10.
- **Common failure prevented across all five:** none of the traces ever lets an untrusted agent mark
  something "proved" — the Gate alone does, and only after independent re-check.
