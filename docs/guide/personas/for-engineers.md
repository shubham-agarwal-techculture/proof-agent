# For Engineers

*For software engineers interested in trust boundaries, reproducibility, and building systems whose
correctness does not depend on the correctness of their cleverest parts.*

## In one line

ProofAgent draws a hard trust boundary: a small, total, deterministic gate is the only component
trusted to certify results, everything clever (agents, planning, tools) is untrusted and sits outside,
and all state is append-only, content-addressed, and provenance-carrying — the familiar "small trusted
core" pattern applied to theorem proving.

## Why this matters to you

If you have built anything security-relevant, "small trusted core / untrusted periphery" is an old
friend: a tiny trusted computing base (TCB) you can audit, with all the surface area pushed outward.
ProofAgent makes the pattern literal. The trusted gate is the only module whose "yes" counts; agents,
planning, and tools are untrusted and live outside the boundary.

The gate is a **total, deterministic function**: for every input it returns a verdict, with no "maybe"
and no exception path. That is a safety property, not a style preference — it is what makes "rejections
never enter verified memory" structural rather than a matter of careful coding. There is simply no
branch from a rejection to a persisted, verified entry.

The codebase is deliberately dependency-light. It pins Lean `leanprover/lean4:v4.35.0` and has **no
Mathlib dependency**, so `lake build` completes in seconds and the trusted base stays small and
auditable. The banned-token list and the axiom allow-list `{propext, Classical.choice, Quot.sound}` are
plain *data*, so the audited surface can be read, diffed, and extended with sign-off.

Storage follows patterns you already use. Memory is an **append-only JSONL log**; entries are
content-addressed (deduped by key) and never mutated, and each carries provenance (`hash`, `statement`,
`producer`, `status`). `insert` is idempotent — a second identical insert is a no-op — and a rejection
never reaches storage at all. That is "fail closed" made concrete.

The tool layer is a line-oriented JSON request/response server (`lake exe checkServer`) with `op`
dispatch and request-id echo — the MCP-tool shape in miniature, and a good model for wrapping expensive
external processes behind a stable, testable protocol. Malformed input gets a structured error, never a
crash.

Extensions are meant to be small and reviewable: add a banned construct or change the allow-list, and
pair it with a new adversarial test. Changing the axiom allow-list is explicitly a *policy exception
that must be signed and logged, never silent*, because it weakens a safety property.

Honesty is enforced in the artifact, too. The README and code notes state what is deliberately **not**
implemented: elaborated-`Expr` matching, `#print axioms` wiring, an independent re-checker, interactive
goal stepping, and SHA-256 content hashing (the skeleton uses FNV-1a only as a stable dedup key).
"Verified" here means "the gate said yes," not "a second kernel agreed."

## What to take away

- **Total and deterministic by design.** The gate always returns a verdict; totality is a safety property, not style. This is what makes "rejections never enter memory" structural rather than a coding convention.
- **Minimal trusted base, explicit.** No Mathlib in the trusted path; a pinned toolchain; the trusted policy is *data*, so it can be reviewed, diffed, and changed with sign-off.
- **Append-only + content-addressed + provenance.** Content-addressed entries give dedup, cache, revocation, and "which bad premise contaminated which conclusion?" analysis — today in one JSONL file, as the single-node seed of a distributed design.
- **"Compiled ≠ verified" (A1).** The check tool reports *compilation*; a `sorry` proof compiles and is accepted there, then rejected by the gate. Keep those two words separate in any pipeline you build.
- **Extend via data, test adversarially.** Policy lives in data; every change comes with a new rejection test. An axiom allow-list change is a signed, logged event — treat it as a security change.
- **Built vs designed is stated.** The trusted core and three tools are `[exists today]`; agents, retrieval, curiosity, sensors, and federation are `[near-term]`–`[speculative]` design. Do not mistake the skeleton for the system.

## Where each principle lives in the skeleton

| Invariant / pattern | Where it lives |
|---|---|
| Trusted core / untrusted periphery | `ProofAgent/VerifierGate.lean` is the only trusted module |
| Total, deterministic decision | `gate` returns a `Verdict` for every input |
| Minimal trusted base (no Mathlib) | `lakefile.toml` pins Lean 4.35.0 with no external deps |
| Append-only, content-addressed store | `ProofAgent/Memory.lean` (`insert` dedups; never mutates) |
| Fail-closed persistence | `ProofAgent/Orchestrator.lean` writes only on `.verified` |
| Tool-as-service | `ProofAgent/Tools/CheckServer.lean` JSON request/response loop |

## The build-and-run loop

Everything you need is short and dependency-light:

```powershell
cd skeleton
lake build                                   # builds the trusted core (seconds)
lake env lean tests/adversarial.lean         # cheats rejected, honest accepted
lake env lean tests/memory.lean              # store ops, dedup, gate→persist
lake env lean tests/leancheck.lean           # compile outcomes (incl. sorry)
lake env lean tests/goals.lean               # initial goal read-back
```

The pinned toolchain is `leanprover/lean4:v4.35.0`; if `lake` is not on your path, prepend elan's shim
directory for the session. `lake build` succeeds and each suite exits `0`.

## A safe-contribution checklist

- **Touch the gate last, and only with a test.** Any change to the gate's policy should arrive with a new adversarial case in `tests/adversarial.lean`.
- **Never let a rejection reach storage.** Keep the propose→verify→record invariant; the orchestrator is the place that enforces it.
- **Treat the allow-list as security data.** Adding an axiom is a signed, logged policy exception, not a convenience.
- **Keep the trusted base small.** Resist adding dependencies to the trusted path; put them in the *pipeline*, not the gate.
- **Update the maturity labels.** If you build something previously "designed," say so — honesty is part of the artifact.

## Failure handling: what "fail closed" means here

The interesting engineering is in the negative paths, and they are worth copying:

- **No partial credit.** The gate returns a single verdict; there is no "mostly verified" and no
  warning-only acceptance. A claim is in or it is out.
- **Reject on doubt.** Unknown axiom, mismatched statement hash, banned token — all reject. New
  information defaults to *distrust*, not acceptance.
- **The error path never persists.** The failure mode people get wrong in real systems is quietly writing
  a half-good result; here the only write is on `.verified`, so a rejected claim has no route into storage.
- **Malformed input is not a crash.** The tool server answers bad requests with a structured error, so a
  noisy caller degrades a response rather than the process.

## What is deliberately absent (and why)

The design's omissions are choices, not oversights — and they are among the safest things to read first:

- **No Mathlib in the trusted path.** External libraries would enlarge the audited base and slow the
  build; the toolchain is pinned and dependency-light instead.
- **No distributed store yet.** Memory is one append-only JSONL file — the single-node seed of a design
  that could later be content-addressed across nodes.
- **No second kernel, yet.** An independent re-checker is planned; today "verified" is the gate's word
  alone, and the artifact says so rather than implying more.
- **SHA-256 is not in place.** Content addressing today uses FNV-1a as a *stable dedup key* only — fine
  for dedup, not offered as cryptographic integrity. Knowing which is which is the whole point.

## Where to go next

- **Practitioner tier — build, run, extend:** [t2-practitioner.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md).
- **The code's own README (layout, commands, recorded test output):** [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md).
- **The design's threat model and failure modes:** [phase-7-red-team.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md).
- **Definitions, plainly and precisely:** [glossary.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
- **The overall map of this guide:** [README.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/README.md).
