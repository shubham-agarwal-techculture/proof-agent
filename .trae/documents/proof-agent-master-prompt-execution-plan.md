# Plan: Execute the "Master Prompt — Agentic, Curious, Memory-Rich Theorem-Proving System on Lean 4 + Mathlib"

## 1. Summary

The repository currently contains **only** the source brief
[Master Prompt … .md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/Master%20Prompt%20Design%20an%20Agentic%2C%20Curious%2C%20Memory-Rich%20Theorem-Proving%20System%20on.md).
There is no code, no docs, no Lean project.

"Working it through" means **executing the brief**: act as the brief's four-person design team
(Lean engineer / multi-agent architect / automated-reasoning+RL researcher / safety engineer) and
produce the full design deliverable across the brief's **Phases 0–9**, tagged
`[exists today] / [near-term] / [frontier] / [speculative]`, with Mermaid diagrams, schemas,
pseudocode, worked examples, roadmap, red-team pre-mortem, and a one-page decision memo — plus an
optional but included **Phase 9 walking skeleton** (runnable Lean 4 + Mathlib project, orchestrator,
Lean REPL tool, memory store, prover loop, verifier gate with adversarial tests).

Because the brief can exceed a single output, content is split into a **`docs/` design set**
(one file per phase) plus a **`skeleton/` Lean project**. This plan is decision-complete: the
executor writes exactly the files below without making further choices.

**Verification note (honesty):** Today's environment date is **2026-11-23**. Phase 0 requires web
research; the executor MUST run live web searches and cite sources, and MUST mark any unverified
tool/version/benchmark claim as unverified rather than asserting it. No citations may be invented.

---

## 2. Current State Analysis

| Item | State |
|---|---|
| Working dir | `d:\projects-shubham\02.06.2026\personal_projects\proof-agent` |
| Existing files | 1 markdown brief only |
| Code | none |
| Lean toolchain | unknown / not present in repo (must be checked at execution time) |
| Memory (`.trae/memory`) | no project entry for this repo (greenfield) |
| Git | not confirmed; check `git status` before any commit (do not commit unless asked) |

Consequences for the plan:
- Everything is **created from scratch**; no refactoring of existing code is possible or needed.
- The deliverable is primarily **documentation/design** with one **optional executable prototype**.
- The brief itself defines the required structure (Sections 4 invariants, 5.1–5.22 capabilities,
  Phases 0–9, Section 7 quality bar). The plan mirrors that structure exactly so the result is
  auditable against the brief.

---

## 3. Assumptions & Decisions (defaults for the blank Parameters, brief §3)

The brief says: *"Fill in what you know. For anything left blank, choose a sensible default and
state it explicitly."* Since the user did not supply values, the executor assumes the following and
**states them at the top of the deliverable**:

| Parameter | Chosen default | Rationale |
|---|---|---|
| Primary users | Research mathematicians (primary); scientists/engineers (secondary); near-autonomous operation under human gates | Highest-value, Mathlib-rich entry point |
| Initial domains | Combinatorics + number theory → analysis/probability → algorithms/complexity → control → program verification | Matches Mathlib density and brief §3 example |
| Compute / budget | v0–v1: one 8-GPU node; v3–v4: scale-out via cloud burst to ≥1,000 GPUs; assume ~US$50k/month (stated assumption) | Keeps MVP affordable, allows scale study |
| Team & timeline | 4 engineers + 1 Lean/Mathlib expert; 18 months to v2 | Stated default |
| Deployment / licensing | Hybrid (cloud burst for ephemeral agents; on-prem/isolated for trusted core); Lean 4 + Mathlib under Apache-2.0 (open) | Trusted-core isolation is an invariant |
| Model access | Frontier closed models for reasoning + open-weight specialist provers (DeepSeek-Prover-class) that can be fine-tuned/RL'd | Enables §5.18 training flywheel |
| Real-world interfaces v1 | None (core). v3: read-only sensors → v3.5: simulated actuators → v4: real actuators with human approval | Conservative actuator posture |
| Safety posture | Balanced (conservative for actuators) | Matches invariants §4 |
| Hard constraints | User-problem confidentiality; license compliance (Lean/Mathlib/third-party); no export-controlled reasoning content | Stated |
| Capability packs in scope | **All of §5.10–§5.22** (plus core §5.1–§5.9) | Brief's default "all" option |
| Longest autonomous run | v1: days; v4: months-long campaigns | Matches §5.10 |

Additional decisions the executor must make explicitly (mini decision records, brief §7):

1. **Output split** → one `docs/` file per phase (manageable, matches brief §7 "continue section by section").
2. **Diagram format** → Mermaid only (brief §7 mandate).
3. **Schema format** → JSON Schema *and* a Lean `structure` sketch for each core artifact (brief §3 Phase 3).
4. **Walking skeleton** → include it; implement minimal verifier gate with adversarial rejection tests. Mark toolchain/version claims unverified unless actually built.
5. **Naming/language** → English (user's language).

---

## 4. Deliverable Structure (files to create)

All paths relative to the project root. Use a stable, numbered layout.

```
proof-agent/
├─ docs/
│  ├─ README.md                      # TOC, executive summary, parameters table, how to read
│  ├─ phase-0-landscape.md           # web-researched SOA + citations, exists-vs-claimed
│  ├─ phase-1-framing.md             # assumptions + 5 highest-leverage questions
│  ├─ phase-2-architecture.md        # layers, trust boundary, schemas, protocols, storage, diagrams A–H
│  ├─ phase-3-deep-dives.md          # §5.1–§5.22 + 5 agent system prompts + schemas + pseudocode
│  ├─ phase-4-worked-examples.md     # 5 traced examples (a)–(e)
│  ├─ phase-5-scale-economics.md     # capacity model, scale ladder 10^0/10^3/10^6/10^9, cost per lemma
│  ├─ phase-6-roadmap.md             # MVP→v1→v2→v3→v4, exit/kill criteria, 90-day demo
│  ├─ phase-7-red-team.md            # 15 failure/harm modes + unknown unknowns + cheap probes
│  ├─ phase-8-decision-memo.md       # one page: build/cut/bet/decide-this-week
│  └─ phase-9-walking-skeleton.md    # design + how-to-run of the prototype; links to /skeleton
└─ skeleton/                         # Phase 9 executable prototype (see §5, Step 10)
   ├─ README.md
   ├─ lean-toolchain
   ├─ lakefile.toml
   ├─ ProofAgent/
   │  ├─ Orchestrator.lean
   │  ├─ VerifierGate.lean
   │  └─ Spec.lean
   ├─ tests/
   │  └─ adversarial.lean
   └─ (python or lean driver for orchestrator if needed)
```

### 4.1 Content contract per design file (decision-complete)

- **`docs/README.md`** — one-paragraph mission; the parameters table from §3; the invariants listed
  verbatim-by-reference; TOC linking every phase file; a "how to read / status tags" legend.
- **`docs/phase-0-landscape.md`** — must cover, each with `[exists today]/[near-term]/[frontier]`
  tag and sources: Lean 4 + Mathlib (current version, tooling, conventions); AI provers &
  autoformalization (AlphaProof, AlphaGeometry, DeepSeek-Prover, Kimina-Prover, Goedel-Prover,
  Seed-Prover, Aristotle); agent frameworks/protocols (MCP-style tool servers, A2A); open-ended /
  curiosity systems (FunSearch, AlphaEvolve, Voyager-style skills, Ramanujan Machine, POET/OMNI,
  ADAS, Darwin Gödel Machine); benchmarks (miniF2F, ProofNet, PutnamBench — verify saturation
  status). Every claim either cited or marked unverified.
- **`docs/phase-1-framing.md`** — restate parameter defaults; list the 5 questions whose answers
  would most change the design; proceed on defaults.
- **`docs/phase-2-architecture.md`** — layered diagram; trusted/untrusted boundary; component
  inventory; protocol/schema overview; storage & content-addressing; deployment topologies laptop
  → data-center; **8 Mermaid diagrams (A–H)** exactly as brief §Phase 2 requires (new problem E2E;
  memory-augmented reuse; sensor→conjecture→proof→knowledge; curiosity loop; failure & recovery;
  scale-out 10^3→10^9; literature audit; months-long campaign).
- **`docs/phase-3-deep-dives.md`** — §5.1–§5.22 each with design / key algorithms / interfaces &
  schemas / failure modes / metrics / open research questions; plus: **5 agent system prompts**
  (conductor, formalizer, statement auditor, prover, memory curator); schemas for `ProblemSpec`,
  `Claim`, `ProofCertificate`, `EpisodeSnapshot`, `ActionRequest` (JSON Schema + Lean `structure`);
  **pseudocode** for orchestrator loop, curiosity loop, memory consolidation; per-capability
  **acceptance test** (input / expected behaviour / pass-fail metric / failure guarded).
- **`docs/phase-4-worked-examples.md`** — five end-to-end traces (a)–(e) with agents, tool calls,
  memory reads/writes, costs, failures.
- **`docs/phase-5-scale-economics.md`** — capacity model; scale ladder with back-of-envelope numbers
  at 10^0/10^3/10^6/10^9 agents; bottleneck analysis (proof dependency structure, coordination
  overhead, verifier throughput, retrieval quality); where more agents stop helping; cost per
  verified lemma; energy; where to invest first.
- **`docs/phase-6-roadmap.md`** — stages MVP→v1→v2→v3→v4, each with scope, exit criteria, risks,
  staffing, kill criteria; a 90-day demo that convinces a skeptic; placement of §5.10–§5.22
  capability packs with justification for deferrals.
- **`docs/phase-7-red-team.md`** — pre-mortem: 15 likeliest failure/harm modes with mitigations and
  early-warning signals; unknown unknowns; cheap experiments to surface them.
- **`docs/phase-8-decision-memo.md`** — one page: what to build first, what to cut, what to bet on,
  what to decide this week.
- **`docs/phase-9-walking-skeleton.md`** — describes and links the `/skeleton` project; states what
  was actually built/verified vs. design-only.

Every phase file ends with a **self-critique pass** (weakest assumptions; what was fixed; what
remains flagged) as brief §7 requires. Every major decision uses a **mini decision record**
(context / options / decision / consequences), and every major claim names the **falsifying
experiment**.

---

## 5. Execution Steps

**Step 0 — Environment probe (read-only).** `git status`; check for Lean via
`elan --version` / `lake --version`. Record results; if absent, the skeleton is authored but its
build is marked "not executed here".

**Step 1 — Phase 0 research.** Run live `WebSearch`/`WebFetch` for each area in §4.1's phase-0 list
(current as of 2026-11-23). Collect URLs. Separate *exists* from *claimed*. Write
`docs/phase-0-landscape.md` with inline citations and a Sources section. Mark anything not
confirmed as unverified.

**Step 2 — Phase 1.** Write `docs/phase-1-framing.md` (defaults + the 5 highest-leverage questions).

**Step 3 — Phase 2.** Write `docs/phase-2-architecture.md` including all 8 Mermaid diagrams,
the trust boundary, and the component/protocol schema overview.

**Step 4 — Phase 3.** Write the large `docs/phase-3-deep-dives.md`: §5.1–§5.22, 5 system prompts,
5 schemas (JSON + Lean), 3 pseudocode blocks, and per-capability acceptance tests.

**Step 5 — Phase 4.** Write `docs/phase-4-worked-examples.md` (traces a–e).

**Step 6 — Phase 5.** Write `docs/phase-5-scale-economics.md` (ladder + bottlenecks + costs).

**Step 7 — Phase 6.** Write `docs/phase-6-roadmap.md` (MVP→v4 + 90-day demo + pack placement).

**Step 8 — Phases 7 & 8.** Write `docs/phase-7-red-team.md` (15 modes) and
`docs/phase-8-decision-memo.md` (one page).

**Step 9 — `docs/README.md` index** linking all phase files, parameters table, status-tag legend.

**Step 10 — Phase 9 walking skeleton (code).** Build `skeleton/`:
- `lean-toolchain` (pin a Lean version — verified at Step 0 or marked unverified),
- `lakefile.toml` (depend on Mathlib),
- `ProofAgent/Spec.lean` — `ProblemSpec`-lite + `Claim` structures,
- `ProofAgent/VerifierGate.lean` — the trusted gate: reject `sorry`, `native_decide`, `unsafe`,
  `implemented_by`, `partial`, `set_option … skipKernelTC`; run `#print axioms` allow-list
  (`propext`, `Classical.choice`, `Quot.sound`); compare proved statement against the signed spec,
- `ProofAgent/Orchestrator.lean` + minimal driver — propose→verify→record loop with a content-
  addressed in-memory/JSONL memory store,
- `tests/adversarial.lean` — proofs that **must be rejected** (sorry-based, extra-axiom,
  wrong-statement, kernel-bypass) alongside a proof that must pass,
- `skeleton/README.md` — how to run.
- Attempt `lake build`/tests; if toolchain unavailable, mark unverified. Write
  `docs/phase-9-walking-skeleton.md`.

**Step 11 — Final pass.** Cross-check the deliverable against the brief's §7 quality bar and §6
phase order; ensure no invented citations; ensure every capability pack §5.10–§5.22 is placed on the
roadmap. Report the file list to the user.

---

## 6. Verification steps

1. **Completeness vs. brief:** every brief Section (4, 5.1–5.22, Phases 0–9, §7) has a
   corresponding section in `docs/`. Checkable by grep for headings.
2. **Diagrams:** 8 Mermaid blocks exist in `phase-2-architecture.md` (grep ` ```mermaid `).
3. **Schemas:** 5 artifacts (`ProblemSpec`, `Claim`, `ProofCertificate`, `EpisodeSnapshot`,
   `ActionRequest`) appear as both JSON Schema and Lean `structure`.
4. **Pseudocode:** orchestrator, curiosity, memory-consolidation blocks present.
5. **Worked examples:** 5 traces (a)–(e) present.
6. **Red-team:** exactly ≥15 failure modes listed.
7. **Per-capability acceptance tests:** each of §5.1–§5.22 has input/expected/metric/failure-guarded.
8. **Decision records:** ≥1 mini decision record per major decision; each major claim names a
   falsifying experiment.
9. **Sources:** Phase 0 has ≥1 citation per surveyed area; no fabricated links (spot-check each URL).
10. **Skeleton:** if Lean is installed, `lake build` and `tests/adversarial.lean` run and the
    adversarial cases are rejected / the honest case accepted. If not installed, this is explicitly
    marked unverified in both `skeleton/README.md` and `docs/phase-9-walking-skeleton.md`.

---

## 7. Risks & Open Questions

- **Web access / staleness:** Phase 0 depends on live search; if a source is unreachable, mark the
  claim unverified (do not invent). *Not blocking.*
- **Output size:** the design is large; splitting per phase (decision 1) keeps each file writable.
- **Lean toolchain absence:** skeleton may be authored but un-built; explicitly flagged. *Not blocking.*
- **Parameter choices:** defaults are assumed; the user may later override any row of the §3 table
  without redoing the structure.
- **Scope:** all §5.10–§5.22 packs included by default; executor will tag depth so boilerplate stays
  shallow and hard sections (formalization fidelity, verifier hardening, perception→Lean bridge,
  memory consolidation, curiosity engine) get the most depth, per brief §7.
