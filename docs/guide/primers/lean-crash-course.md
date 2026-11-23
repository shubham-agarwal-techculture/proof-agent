# Lean Crash Course

*Can you read a little code but have never touched Lean? Start here.*

## Why this primer exists

The rest of the guide talks about Lean proofs, tactics, and snippets. This primer gives you just enough
Lean 4 to read those snippets without stopping — and, crucially, it uses **only code that actually appears
in this repository**, so nothing here is invented or Mathlib-specific. It unblocks
[Level T2 — Practitioner](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md),
which walks the real files.

Everything below is real Lean from [`skeleton/`](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton),
pinned at `leanprover/lean4:v4.35.0`.

---

## 1. What Lean is

**Lean 4** is a programming language whose *other* job is stating and machine-checking mathematics. It is
two things at once:

1. a way to **state** an exact claim (a proposition, as a *type*), and
2. a way to **prove** it, in a form a small trusted checker (the **kernel**) can verify.

You write a declaration, and Lean either accepts it (the kernel is satisfied) or complains. This is why
the project's skeleton can *build* and *run tests* — Lean is doing real checking, not just string matching.

---

## 2. Values and types

Everything in Lean has a **type**. You will meet these in the repo:

| Type | Meaning | Where you see it here |
|---|---|---|
| `Nat` | natural numbers `0, 1, 2, …` | `∀ n : Nat, n + 0 = n`, a diagnostic `line : Nat` |
| `String` | text | `contentHash`, `producer := "agent-02"` |
| `Bool` | `true` / `false` | `hasToken : String → String → Bool` |
| `List α` | a finite sequence of `α`s | `allowedAxioms : List String` |
| `Array α` | a finite sequence, indexed | `load : … → IO (Array MemEntry)` |
| `Option α` | either `some a` or `none` | `scanBanned : String → Option RejectReason` |
| `UInt64` | a 64-bit unsigned integer | the FNV-1a hash in [Memory.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Memory.lean) |

Types are written with a colon: `n : Nat` reads "`n` is a natural number." A function type uses an arrow:
`String → Bool` is "a function from `String` to `Bool`."

---

## 3. Declarations: `example`, `theorem`, `def`, and the `by` block

**`def`** names a *value* (data or a function). From
[VerifierGate.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean):

```lean
def allowedAxioms : List String := ["propext", "Classical.choice", "Quot.sound"]
```

Read: "define `allowedAxioms` as the list of these three strings." A function is a `def` with parameters:

```lean
def hasToken (src tok : String) : Bool := (src.splitOn tok).length > 1
```

**`theorem`** names a *proved claim*. This is real Lean you can check (it is the check-server example in
the [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md)):

```lean
theorem a : 1 + 1 = 2 := rfl
```

Read: "here is a theorem whose *statement* is `1 + 1 = 2`, and its *proof* is `rfl`." Everything after
`:=` is the proof.

**`example`** is `theorem` without a name — a throwaway claim you state just to check it. The classic
example, from [Level T0](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md):

```lean
example : ∀ n : Nat, n + 0 = n := by
  intro n
  rfl
```

A proof introduced with **`by`** switches Lean into **tactic mode**: instead of writing one big term, you
give *tactics* (proof commands), one per line, and Lean applies them to the current goal (what remains to
be proved).

---

## 4. Tactics: the proof commands

Here are the tactics this repo actually uses:

- **`intro n`** — "let `n` be an arbitrary value." It discharges a `∀` (or an implication's hypothesis) by
  introducing a name for it. In the example above, `intro n` handles the `∀ n : Nat`.
- **`rfl`** — "this holds by *definitional equality*"; the two sides of the `=` are the same after Lean
  unfolds definitions. It proves `1 + 1 = 2` and `n + 0 = n` (addition of zero is built in).
- **`simp`** — "simplify using a library of known equalities, then close the goal." The honest proof in
  the adversarial tests is literally `by simp` for `∀ n : Nat, n + 0 = n`.
- **`skip`** — "do nothing." It leaves the goal untouched. The goal-state tool uses it on purpose (see §6).
- **`decide`** — "compute the answer with a decision procedure." It proves propositions that are *decidable*
  by computation. From [adversarial.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/adversarial.lean):

  ```lean
  example : allowedAxioms.contains "propext" = true := by decide
  ```
- **`exact e`** — "close the goal with the term `e`." A cheat claim in the tests is `by exact myHandWavedLemma`
  (rejected by the gate for other reasons).

Tactic mode is a *convenience layer*: whether you write `rfl` or the underlying term, the kernel checks the
same thing.

---

## 5. Running vs proving: `#eval` versus `by decide`

Two ideas are easy to confuse, and this repo separates them sharply.

**`#eval`** *runs* an expression and prints its value. It is a command for the user, not a proof. From
[adversarial.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/adversarial.lean):

```lean
#eval gate spec cOk     "H_signed" ["propext"]            -- verified
```

This executes the gate and prints the verdict. It says nothing *to the kernel*; it just shows output when
you run the file.

**`by decide`** *proves* a decidable proposition, in the kernel. It is a real proof. The tests use it for the
axiom allow-list:

```lean
example : allowedAxioms.contains "propext" = true := by decide
example : allowedAxioms.contains "RiemannHypothesis" = false := by decide
```

Why not just use `by decide` for the whole gate? Because `allowedAxioms.contains` is pure `String` equality,
which the kernel can reduce — but the gate's textual scan goes through `String.splitOn`, which is
`@[extern]` and therefore **does not reduce in the kernel**. So the gate *verdicts* are shown with `#eval`,
while the *allow-list logic* gets machine-checked `by decide` examples. This is a genuine design point, not a
style choice (see §7 and [T2 §10](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md)).

---

## 6. The pinned toolchain, and how files are run

The project pins its Lean version in
[lean-toolchain](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/lean-toolchain):

```text
leanprover/lean4:v4.35.0
```

`lean-toolchain` is read by **elan**, Lean's toolchain manager, so everyone builds with the same Lean. The
skeleton has **no Mathlib dependency by design**, so the trusted base stays small and the build takes
seconds.

Two ways to run Lean code here (from the `skeleton/` folder):

```powershell
lake build                          # build the library
lake env lean tests/goals.lean      # run one file, with the pinned toolchain on PATH
```

`lake env lean <file>` runs a single file using the project's pinned Lean and its local packages.

The goal-state tool shows a neat trick built on `by skip`: to read the *initial goal* of a statement, it
wraps it in a no-progress proof (from
[GoalState.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/GoalState.lean)):

```lean
example : <statement> := by
  skip
```

Lean then reports the untouched goal, which the tool parses. (Reading a goal is *not* proving it: the tests
show that a **false** statement like `1 + 1 = 3` still yields a goal. Only the gate adjudicates truth.)

---

## 7. Gotchas actually hit in this repo

These are real errors encountered while writing the skeleton; each changed the code.

- **`show` is a reserved keyword.** A helper called `show` fails to parse
  (`unexpected token 'show'; expected identifier`). The fix here: it was renamed to **`showGoal`** in
  [tests/goals.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/tests/goals.lean).
- **`String.splitOn` is `@[extern]`, so `by decide` cannot reduce it.** That is why the gate's substring test
  (`(src.splitOn tok).length > 1`) is exercised with `#eval`, while only the pure `String`-equality
  allow-list is provable with `by decide`.
- **Unknown identifiers auto-bind as implicit variables.** Write an unknown name in a type position and Lean
  may silently treat it as a fresh variable, so a "not a proposition" statement still *elaborates*. The
  goal-state tool guards against this: `GoalState.ok` is `true` only when the sole error is the
  unsolved-goals report — hence the deliberate ill-typed test case `List 1`.
- **Inline `if/else` in a `do` block needs an explicit result type.** The branches can unify to `Unit`
  without a hint. The fix in
  [CheckServer.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Tools/CheckServer.lean)
  was to extract a helper with an explicit return type: `respond (j : Json) : IO (List (String × Json))`.
- **A recursive runtime loop needs `partial`.** Lean insists on termination proofs by default; a
  genuinely non-terminating loop is marked `partial def serve : IO Unit`.

---

## Common misconceptions

- **"`#eval` proves things."** No — `#eval` *runs* and prints. Only a real proof (e.g. `by decide`, `rfl`)
  say anything *to the kernel*.
- **"`theorem` and `def` and `example` are different languages."** They are the same language: `def` names a
  value, `theorem` names a proof, and `example` is an unnamed `theorem`. All three use the same `:=` and
  `by` machinery.
- **"If Lean accepts a file, every claim in it is proved."** No — a file containing `sorry` still
  *compiles*. This is the **A1** trap ("compiled ≠ verified").
- **"I need Mathlib to do anything."** Not here: the skeleton deliberately depends only on Lean core, to keep
  the trusted base small.

---

## Where to go next

- **Build and run the real files →** [Level T2 — Practitioner](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md).
- **The intuition behind all this →** [Level T1 — Intuition](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **Why "a proof is a program" →** [Type-Theory Intuition](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/type-theory-intuition.md).
- **What a proof even is →** [Logic and Proofs](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/logic-and-proofs.md).
- **Any term →** [Glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
