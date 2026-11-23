# Logic and Proofs

*New to formal logic, or fuzzy on what a "proof" actually is? Start here.*

## Why this primer exists

ProofAgent is a machine that *proves theorems* and *checks proofs*. Before any of the engineering makes
sense, you need a working feel for four things: what a **proof** is, what a **proposition** is, how a claim
is put together (hypotheses and a conclusion), and why a machine checking a proof is different from a
person nodding along.

This primer supplies exactly that vocabulary, at the level the rest of the guide assumes. It unblocks
[Level T0 — Start Here](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md)
and [Level T1 — Intuition](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
Every term defined here also appears in the [glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).

---

## 1. What a proof is (and what it is not)

A **proof** is a rigorous argument that a **statement** is true **in every case** — not just in the cases
anyone happened to check.

Compare the two habits:

- *Checking cases.* "1 + 0 = 1, 7 + 0 = 7, 100 + 0 = 100… looks true." This is **evidence**, not proof. It
  can always be wrong for the next case.
- *Giving a proof.* "Adding zero changes nothing, *by the definition of addition*." This explains *why the
  statement cannot fail*, for all numbers at once.

A statement we *believe* but have not proved is a **conjecture**. A statement that has been proved is a
**theorem** (or, if it is a small stepping-stone, a **lemma** — the two are the same thing, differing only
in importance). Conflating "checked a lot" with "proved" is the original sin this whole project is built to
avoid.

---

## 2. Propositions: statements that can be true or false

A **proposition** is a statement that has a definite truth value: it is either true or false, not
"sort of." "2 + 2 = 4" is a proposition. "2 + 2 is 5" is a proposition (a false one). "Close the door" is
*not* a proposition, because it is a command and has no truth value.

Two useful building blocks turn propositions into bigger propositions:

- **Not** (written `¬P`, "not P"): true exactly when `P` is false.
- **And / Or** (`P ∧ Q`, `P ∨ Q`): `P ∧ Q` is true when both are; `P ∨ Q` is true when at least one is.

The point of insisting on "definite truth value" is that only propositions can be proved. If a sentence
has no truth value, there is nothing to prove — and a machine will (rightly) refuse to check it.

---

## 3. Hypotheses, conclusions, and the shape of a claim

Most mathematical claims have the shape:

> **If** *[something is assumed]* **then** *[something follows]*.

- The assumed part is the **hypothesis** (also called a *premise* or *assumption*).
- The part that follows is the **conclusion**.

Example: *"If `n` is an even number, then `n + n` is even."* Here the hypothesis is "`n` is even" and the
conclusion is "`n + n` is even." A proof of such a claim commonly works like this: *assume* the hypothesis,
then *derive* the conclusion.

This distinction is not pedantry — it is where real mistakes live. A proof that silently drops a
hypothesis can "prove" a much stronger (and false) claim while looking perfectly valid. That is exactly the
**statement drift** problem this project treats as a first-class risk (failure mode **F2**).

---

## 4. Implication versus equivalence (`→` versus `↔`)

Two arrows dominate mathematical writing, and they are *not* interchangeable:

- **Implication** `P → Q` reads "if `P` then `Q`." It is true whenever `P` is false, or whenever both are
  true — it is **only** false in the one case where `P` is true and `Q` is false. Implication is
  *one-directional*.
- **Equivalence** `P ↔ Q` reads "`P` if and only if `Q`." It means both `P → Q` **and** `Q → P`. The two
  sides are true together or false together.

Why this matters:

- A statement of the form `P → Q` gives you permission to use `Q` *once you have established `P`*. It does
  **not** give you permission to use `P` from `Q`.
- Writing `→` where the author meant `↔` (or vice versa) changes the claim. In Lean these are genuinely
  different types, so a machine-checked proof of one is not a proof of the other. The glossary lists
  "`→` vs `↔`" explicitly as a statement-drift hazard.

---

## 5. Quantifiers: "for all" and "there exists"

Quantifiers say *how many* cases a claim covers. There are two, and they look deceptively similar:

- **Universal quantifier `∀`** — "for all," "for every." `∀ n : Nat, n + 0 = n` means the statement holds
  for every natural number `n` with no exceptions.
- **Existential quantifier `∃`** — "there exists," "for some." `∃ n : Nat, n + 0 = 1` means at least one
  natural number makes it true.

Swapping or weakening a quantifier changes the claim, often drastically:

| Claim | Strength |
|---|---|
| `∀ n : Nat, n + 0 = n` | says something about *every* `n` — the strong claim |
| `∃ n : Nat, n + 0 = n` | says only that *some* `n` works — much weaker |

Quantifiers also nest, and *order matters*: `∀ x, ∃ y, …` ("for every `x` there is a `y`") is a different
claim from `∃ y, ∀ x, …` ("there is a single `y` that works for every `x`"). Dropping a "for all," or
quietly reordering quantifiers, is a classic way to prove an easier statement than the one requested —
again, fidelity territory.

---

## 6. What "rigorous" means — and three proof styles

**Rigorous** means: every step follows from the previous ones by a rule that is stated and correct, with no
gaps and no appeals to intuition ("clearly…", "obviously…"). Rigor is what makes a proof *checkable* —
by a careful reader, or, if it is written in a machine-checkable language like Lean, by a computer.

The three proof styles you will meet most often:

**Direct proof.** Assume the hypothesis and reason forward to the conclusion.
*Claim:* if `n` is even then `n + n` is even. *Proof:* `n = 2k` for some whole number `k`; then
`n + n = 4k = 2(2k)`, which is even. (We used the hypothesis, in the first line, and never dropped it.)

**Proof by contradiction.** Assume the *negation* of what you want, and derive something impossible.
*Claim:* there is no largest whole number. *Proof:* suppose the largest whole number is `m`; then `m + 1` is
also a whole number and is larger than `m` — a contradiction. So the assumption was false.

**Proof by induction.** To prove a claim "for every natural number `n`," prove two things: the claim holds
at the start (**base case**), and *if* it holds for some `n` then it holds for `n + 1` (**inductive step**).
*Claim:* `1 + 2 + ⋯ + n = n(n+1)/2` for every `n ≥ 1`. *Proof:* the base case `n = 1` gives `1 = 1·2/2`, true;
the inductive step adds `n + 1` to both sides and simplifies. Induction is powerful precisely because it
covers infinitely many cases in two finite steps — the opposite of "checking cases."

Whichever style is used, a **counterexample** — a single case where the claim fails — is enough to *disprove*
a universal claim. Finding counterexamples is itself a job in the design (the "counterexample hunter"
role).

---

## 7. Why machine-checking matters — and where it stops

Human proofs contain human mistakes; famous proofs have stood for years before an error was found. A proof
written in a formal language can be checked by a **machine**: a program that verifies each step against a
fixed set of rules, never tiring, never swayed by the author's reputation.

The checker that does the checking is the **kernel** — the small, trusted engine inside a proof assistant
like Lean. ProofAgent's whole architecture follows from one consequence:

> A machine-checked proof is only as trustworthy as the **kernel**.

So the kernel is kept tiny and auditable, and everything large and clever (search, automation, and the AI
that writes candidate proofs) is kept *outside* the trust. That is the rule
**"untrusted agents propose; the trusted kernel disposes."**

But here is the limit, and it is the reason this project elevates a second risk above raw capability:

> The machine checks that the proof matches the **statement it was given**. It does **not** check that the
> statement says what you *meant*.

Suppose you intend "for all gains in the range, the controller is stable," but the formal statement you
hand to the machine drops "for all" — or the range condition. You can then produce a flawless,
kernel-checked proof of the *wrong statement*. Everything in the machinery says "verified." You are still
wrong, and now you are wrong with a certificate. The design calls this **fidelity**, and it is a
first-class risk ("fidelity before proof"): a theorem about a *model* is never automatically a fact about
*reality*. Machine-checking protects the step from statement to conclusion; it cannot protect the step from
intention to statement. That human/meaning step is guarded separately (a statement auditor, human sign-off
for real-world claims) — see [T1 §5](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).

A related trap worth naming now, because it defeats newcomers: **"compiled ≠ verified."** A proof assistant
can *compile* a file that contains `sorry` — a keyword meaning "pretend this is proved, I give up." It
merely warns. So "it built" is **not** "it is proved." Only the trusted gate's verdict counts. This is the
project's assumption **A1**.

---

## Common misconceptions

- **"Checking many cases is basically proving."** No. A million confirmed cases and a proof are different
  kinds of thing; only the proof covers the infinitely many cases nobody checked.
- **"A proof of `P → Q` also proves `Q → P`."** No. Implication is one-directional; equivalence (`↔`) is
  the two-directional statement, and it is a *different* claim.
- **"If a machine checked it, the result must be meaningful."** No. The machine checks proof-against-statement,
  not statement-against-intention. Proving the wrong (or an empty/weakened) statement is the **fidelity**
  risk, not something the kernel will catch.
- **"If it compiled, it's proved."** No — a file with `sorry` compiles with only a warning. Compiled is
  necessary, not sufficient; see **A1**.

---

## Where to go next

- **The friendly version of all this →** [Level T0 — Start Here](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md).
- **Mechanisms and reasons →** [Level T1 — Intuition](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **Now learn the language →** [Lean Crash Course](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/lean-crash-course.md).
- **Why "a proof is a program" →** [Type-Theory Intuition](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/type-theory-intuition.md).
- **Any term →** [Glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
