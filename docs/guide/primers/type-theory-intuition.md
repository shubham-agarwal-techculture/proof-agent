# Type-Theory Intuition

*A working programmer who wants to understand why Lean "checks" anything at all. Start here.*

## Why this primer exists

You can use this project perfectly well without knowing any type theory. But three of its design choices —
why the kernel is small and trusted, why the gate compares *elaborated* expressions rather than source text,
and why "compiled ≠ verified" — only really click once you have one intuition: **in Lean, a proof is a
program, and a proposition is a type.**

This primer gives you that intuition, and nothing more formalism than it takes to make the ideas land. It
unblocks [Level T1 — Intuition](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md)
and [Level T3 — Expert](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md).

Related terms live in the [glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).

---

## 1. The headline: propositions are types, proofs are programs

In ordinary programming, values have types: the value `3` has type `Nat`. Lean turns this around and uses
the *same* machinery for logic:

- A **proposition** (a statement that is true or false) is treated as a **type**.
- A **proof** of that proposition is treated as a **value** of that type.

This correspondence is called **Curry–Howard** (also "propositions as types"). You do not need the theory
to use it; you need the picture:

```
   type        ↔  proposition
   value       ↔  proof
   type-checks ↔  proof is valid
```

If the proposition "there is a value of type `T`" is true, you say the type is *inhabited*, and any
inhabiting value **is** the proof. If a type is uninhabited, the proposition is false — there is simply no
proof to be had.

---

## 2. A proposition is a type; a proof is a value

Look at real Lean from this repo (the check-server example in the
[skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md)):

```lean
theorem a : 1 + 1 = 2 := rfl
```

Read it with the correspondence in mind:

- `1 + 1 = 2` is the **proposition** — but Lean sees it as a **type**.
- `rfl` is the **proof** — Lean sees it as a **value** of that type.
- Because `rfl` type-checks against `1 + 1 = 2`, the proposition is true.

And the classic universal statement from
[Level T0](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md):

```lean
example : ∀ n : Nat, n + 0 = n := by
  intro n
  rfl
```

The statement `∀ n : Nat, n + 0 = n` is a type — intuitively, the type of *functions* that, given any
`n : Nat`, return a proof that `n + 0 = n`. The proof `intro n; rfl` is such a function: "take any `n`,
and here is the proof for it." Goal-directed reasoning and function-writing are the same activity.

This is why so many Lean errors are *type errors*: "these two things don't line up" is both a programming
error and a logic error, because they are the same error.

---

## 3. What the kernel does: it type-checks, and it does not trust you

The **kernel** is the tiny, trusted engine at the center of Lean. Its whole job is: given a claimed value
and a claimed type, check that the value really does have that type — and that every step is built from a
small set of rules it trusts (definitions, applications, and the approved axioms).

Two consequences worth internalizing:

- **The kernel is the referee.** Everything else — the parser, the friendly errors, the tactics, the
  automation, this project's agents — is a *helper* that tries to construct the value. Only the kernel's
  verdict is authoritative. That is the project's rule in miniature:
  **"untrusted agents propose; the trusted kernel disposes."**
- **The kernel is small on purpose.** A checker you can read is a checker you can trust. If the trusted
  part were huge, its own bugs would become your proof bugs. The whole architecture (invariant #1) is built
  to keep this core minimal — which is exactly why the skeleton has **no Mathlib dependency** and a tiny
  [VerifierGate.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean).

---

## 4. From source text to `Expr`: what "elaboration" is

When you write:

```lean
example : ∀ n : Nat, n + 0 = n := by
  intro n
  rfl
```

what the kernel actually checks is **not** that text. Before checking, Lean goes through **elaboration**:
it parses the text, resolves every name, fills in implicit arguments, expands notations and macros, and
produces an internal term called an **elaborated expression**, or **`Expr`**.

The `Expr` is the fully-resolved, unambiguous thing — the actual tree of constructors that the kernel
type-checks. The surface text is just a convenience for humans; the `Expr` is what has meaning.

Why this distinction matters: two different-looking texts can elaborate to the *same* `Expr`, and — more
dangerously — the *same-looking* text can elaborate to *different* `Expr`s in different contexts. Notation
and macros are chosen by the environment, so "what the source says" and "what it means" can diverge. (Lean
can print the fully-resolved form; the glossary notes `pp.all`.)

---

## 5. Why the gate compares the elaborated form (or its hash), not the source text

This is where the intuition pays off. The gate's second rule checks **statement match**: does the statement
the agent proved equal the statement a human signed? The project does this on the *elaborated* form — in the
design, a hash of the elaborated goal type — and **never on source text**.

The reason is the divergence from §4. If you matched on text:

- An agent could use **notation or a macro** that *looks* like the spec but elaborates to a different
  statement. Re-checking the source text would miss it. This is failure mode **F6** (elaborator/macro
  trickery).
- An agent could exploit that the "same" string means different things in different contexts, proving a
  *different* statement while the text reads correctly. That is **F2** (statement drift).

The elaborated `Expr` cannot be fooled this way, because it *is* the meaning the kernel saw. So the trusted
reference is a hash of the **elaborated type** — and in the design `[near-term]` the real gate inspects that
`Expr` directly, plus `#print axioms` and an independent re-check. The skeleton is honest that it currently uses a
**textual scan as a stand-in**; the comment in
[VerifierGate.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/VerifierGate.lean)
says so explicitly, and
[Spec.lean](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/ProofAgent/Spec.lean)
documents `specHash` as "the content hash of the *elaborated* goal type."

---

## 6. The security model: a small trusted kernel plus big untrusted helpers

Put §3 and §5 together and you get the security model this whole system is built on — the same one used in
operating systems and cryptography: **minimize the trusted computing base.**

- **Trusted (small):** the kernel, plus (in the real design) an independent re-checker, a statement matcher,
  and an axiom auditor. This is L0 in the layered architecture.
- **Untrusted (large):** the parser, tactics, automation, retrieval, and — above all — the AI agents that
  *propose* candidate proofs. They may be wrong, slow, or hostile, and that is fine, because they never
  decide anything.

The gate sits exactly on that boundary. Its whole value is that it can be small *because* everything big is
kept outside the trust. If you ever find yourself trusting the proposer, you have left the model behind.

> A natural question: why not make the *whole* proof assistant trusted and skip the boundary? Because then a
> single bug anywhere — in notation, in a tactic, in an import — could crown a false theorem. Keeping the
> trusted core tiny keeps the surprise surface tiny.

---

## 7. Where `sorry` and `axiom` fit

Two Lean features are worth placing in this picture, because the gate treats them as hazards:

- **`sorry`** is a proof *placeholder*: it lets any proposition type-check, but with only a warning — it is
  like handing the kernel a hole and promising to fill it later. In `Expr` terms, it inhabits the type
  without a real proof term. **"Everything type-checks" is therefore not "everything is proved"** — the A1
  trap. The gate rejects `sorry` outright (failure mode F1).
- **An axiom** is a type declared to be inhabited *by decree*, with no program supplied. Using one silently
  strengthens what a theorem assumes. So the gate audits the axioms a proof relies on against a fixed
  allow-list, `{propext, Classical.choice, Quot.sound}` — anything else is a signed, logged policy exception
  (failure mode F3, assumption A2).

Both are examples of the same lesson: *the kernel checks the term it is given; it does not police how the
term was built or what assumptions were smuggled in.* That policing is the gate's job.

---

## Common misconceptions

- **"A proof is a text document the machine reads carefully."** Not quite: the machine works on the
  **elaborated `Expr`**, not the text. The text is for humans; the `Expr` is what gets checked.
- **"If two proofs look identical as text, they prove the same thing."** No — notation and macros decide
  what text *means*, and the same text can elaborate differently. This is exactly why the gate never matches
  on source text.
- **"A big, capable proof assistant is more trustworthy than a small one."** The opposite for the *trusted
  core*: trust is a liability to be minimized. Capability belongs in the untrusted helpers.
- **"`sorry` and `axiom` are harmless conveniences."** They can make anything type-check without a genuine
  proof, so both are gate-level hazards (F1, F3), not conveniences.

---

## Where to go next

- **The mechanisms and reasons →** [Level T1 — Intuition](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **The full argument, including independence caveats →** [Level T3 — Expert](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md).
- **Learn the syntax first →** [Lean Crash Course](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/lean-crash-course.md).
- **What a proof is, in plain language →** [Logic and Proofs](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/primers/logic-and-proofs.md).
- **Any term →** [Glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
