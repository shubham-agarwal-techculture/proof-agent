# How to Extend the Verifier Gate

*Change the trusted policy — add a banned token, adjust the axiom allow-list, or add a machine-checked example — the review-oriented way, without breaking totality, determinism, or invariant #1.*

`[exists today]` — the gate described here is the real, building, tested code in [`VerifierGate.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean). Treat every change to that file as a **security change**: it is the one file the whole design trusts.

The boundary rule: **untrusted agents propose; the trusted kernel disposes.** The gate must stay **total** (it returns a verdict for every input) and **deterministic** (the same input always yields the same verdict). Nothing you add may introduce a new axiom, a new dependency, or a branch that can silently "pass".

## 1. Read the gate before you change it

Open [`VerifierGate.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean) and confirm the three data-driven pieces:

- `RejectReason` — the enumerated cheat surface (`sorryFound`, `nativeDecideFound`, `unsafeFound`, `implementedByFound`, `partialFound`, `kernelBypassOption`, `statementMismatch`, `forbiddenAxiom`).
- `allowedAxioms := ["propext", "Classical.choice", "Quot.sound"]` — the permit-list (design A2).
- `bannedTokens : List (String × RejectReason)` — the banned constructs, as data.

`gate` walks them in a fixed order: `scanBanned` first (F1), then the statement-hash comparison (F2), then the axiom audit (F3), else `.verified`. Because the ban list is *data*, extending it adds no new control-flow branch — which is exactly why totality and determinism survive.

## 2. (a) Add a banned token

Three edits, then one test. We worked example a new ban on the `axiom` keyword (a raw way to assert a result into the environment).

**Step 2.1 — add a `RejectReason` constructor.** `RejectReason` must keep `deriving Repr, Inhabited, DecidableEq` (the tests print verdicts and the design relies on equality):

```lean
inductive RejectReason
  | sorryFound
  | nativeDecideFound
  | unsafeFound
  | implementedByFound
  | partialFound
  | kernelBypassOption
  | statementMismatch (signed claimed : String)
  | forbiddenAxiom (axiomName : String)
  | axiomDeclared                       -- new constructor
  deriving Repr, Inhabited, DecidableEq
```

**Step 2.2 — add the token pair to `bannedTokens`.** Put *more specific* tokens earlier: `scanBanned` uses `find?`, so the **first** matching token decides which `RejectReason` is reported when a proof text contains several.

```lean
def bannedTokens : List (String × RejectReason) :=
  [ ("axiom",         RejectReason.axiomDeclared),   -- new; placed first
    ("sorry",         RejectReason.sorryFound),
    ("native_decide", RejectReason.nativeDecideFound),
    ("unsafe",        RejectReason.unsafeFound),
    ("implemented_by",RejectReason.implementedByFound),
    ("partial",       RejectReason.partialFound),
    ("skipKernelTC",  RejectReason.kernelBypassOption) ]
```

**Step 2.3 — add an `#eval` assertion to `tests/adversarial.lean`.** A ban with no failing test is a ban you cannot trust. Add a claim and an expectation next to the existing ones:

```lean
/-- F3-adjacent: declaring a fresh axiom to assert the result. -/
def cAxiomDecl : Claim :=
  { specHash := "H_signed", producer := "agent-01",
    proofText := "axiom cheat : ∀ n : Nat, n + 0 = n" }

#eval gate spec cAxiomDecl "H_signed" []   -- rejected (axiomDeclared)
```

**Review checklist for a new token.**

- The token must be a substring that cannot appear *innocently* in a legitimate proof text. A false positive fails *closed* (it rejects an honest proof) — that is the safe direction, but keep it rare.
- Confirm the existing honest cases (`by simp`, `by rfl`, `by exact myHandWavedLemma`) still contain none of the banned substrings, so the suite's expected `verified` line is unchanged.
- Deriving clauses unchanged; no new axiom; no new import; `gate`'s shape untouched.

## 3. (b) Change the axiom allow-list

The allow-list is [`allowedAxioms`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean):

```lean
def allowedAxioms : List String := ["propext", "Classical.choice", "Quot.sound"]
```

**Edit here only to *remove* freedom, or as a signed policy event.** The design rule is explicit: any *addition* weakens F3, and **any exception is a signed, logged policy event — never silent** (design A2; phase-9 §6 step 3, "add the signed-policy log for exceptions"). The skeleton has no policy log yet, so in this repository an allow-list change is a code change that must be reviewed and recorded, not a config tweak.

If — and only if — sign-off exists, add the name:

```lean
def allowedAxioms : List String := ["propext", "Classical.choice", "Quot.sound", "MySignedAxiom"]
```

Never delete a reviewer-visible list entry without the same sign-off, and never make the list depend on runtime input. The list is part of the trusted base; it must be readable, diffable, and static.

## 4. (c) Add a machine-checked example for the allow-list

Facts about the allow-list are pure `String` equality, which the kernel *can* reduce — so they can be proved with `by decide`. Add examples to [`tests/adversarial.lean`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/adversarial.lean), alongside the existing ones:

```lean
example : allowedAxioms.contains "propext" = true := by decide
example : allowedAxioms.contains "Quot.sound" = true := by decide
example : allowedAxioms.contains "RiemannHypothesis" = false := by decide
```

If you added a permitted axiom in step 3, pin it too:

```lean
example : allowedAxioms.contains "MySignedAxiom" = true := by decide
```

Do **not** try to prove `gate` verdicts with `by decide`: the textual scan calls `String.splitOn`, which is `@[extern]` and does not reduce in the kernel. Gate verdicts are therefore shown with `#eval`. (The real gate inspects the *elaborated* `Expr`, which is kernel-reducible — that upgrade is what would make `decide`-level proofs about the gate itself possible; phase-9 §6 step 2.)

## 5. Rebuild and re-run the suite

```powershell
cd skeleton
lake build
lake env lean tests/adversarial.lean
```

The adversarial suite is the executable form of F1/F2/F3 — it is the review artefact for a gate change.

## Verify it worked

For the worked example in step 2, `tests/adversarial.lean` must now print one extra `rejected (axiomDeclared)` line and still print exactly one `verified`; exit code `0`:

```text
ProofAgent.Verdict.rejected (ProofAgent.RejectReason.axiomDeclared)
...
ProofAgent.Verdict.verified
[{ hash := "H_signed", statement := "∀ n : Nat, n + 0 = n", producer := "agent-02", status := "verified" }]
```

And the machine-checked examples in step 4 must compile with no `sorry` (a `by decide` proof that fails will surface as a build error, which is the point).

Checklist:

- [ ] `lake build` succeeds (the gate still type-checks; `gate` is still total).
- [ ] `tests/adversarial.lean` shows all six original cheats still rejected, the new one rejected, and exactly one `verified`.
- [ ] The honest claim is still `verified` (no false positive from the new token).
- [ ] Every allow-list fact you rely on has a `by decide` example; no verdict is asserted via `decide`.
- [ ] No new axiom, no new dependency, `allowedAxioms` and `bannedTokens` still plain static data.

## Pitfalls

- **Adding a branch instead of data.** If you find yourself writing `if … then reject`, stop: the ban list is data by design. A new control-flow branch is where totality/determinism quietly break.
- **`find?` order.** Tokens are matched in list order; appending a broad token after a narrow one can hide the specific reason you meant to report.
- **Silent axiom additions.** Editing `allowedAxioms` without sign-off/manifest is exactly the failure the design forbids. Adding an axiom does not make a theorem more true; it makes the trust claim weaker.
- **Proving gate verdicts with `decide`.** `String.splitOn` is `@[extern]`; `decide` will hang or fail. Use `#eval` for verdicts and reserve `decide` for pure allow-list equality.
- **Forgetting the test.** A banned token with no `#eval` assertion is unverified policy.

## See also

- [VerifierGate.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean) — the file you are changing.
- [tests/adversarial.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/adversarial.lean) — the executable F1/F2/F3 tests.
- [add-a-tool.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/add-a-tool.md) — the other safe extension point (tools, not policy).
- [troubleshooting.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/how-to/troubleshooting.md) — `by decide` failures and other compiler errors.
- [phase-1-framing.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-1-framing.md) — A2, the axiom allow-list baseline.
- [phase-7-red-team.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md) — F1/F2/F3 and the rest of the failure modes.
- [phase-9-walking-skeleton.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-9-walking-skeleton.md) — §6, the "make it real" upgrade list.
