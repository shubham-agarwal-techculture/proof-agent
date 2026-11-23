# Level T0 — Start Here (High-School Reader)

*No prior background assumed. If you can add whole numbers and you've seen `x + 1 = 1 + x`, you can
read this. Every word that might be new is explained the first time it appears, and every one is also
in the [glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).*

---

## 1. What is a "proof", really?

In school, "prove it" often means "show the numbers work out." But in mathematics a **proof** is
something stronger: it's a careful chain of reasoning that shows a statement is true **in every
possible case, forever** — including the cases nobody has checked.

Example. You notice:

- `3 + 0 = 3` ✔
- `7 + 0 = 7` ✔
- `100 + 0 = 100` ✔

You've checked three cases. A proof explains **why it must be true for every number at once**: "adding
zero changes nothing, by definition of `+`." That "why" is the proof.

Two words you'll see everywhere:

- A **theorem** (or **lemma**) is a statement that has been proved — e.g. "for every number `n`,
  `n + 0 = n`."
- A **conjecture** is a statement we *believe* but have **not** proved. Famous ones (like Goldbach's
  conjecture: every even number above 2 is the sum of two primes) have been checked for enormous
  ranges and are still unproven. Checking cases is not proving.

> **Why this matters here:** the whole project exists because "checked a lot of cases" and "proved"
> are different, and confusing them is dangerous.

---

## 2. Why would a *computer* check a proof?

A human proof can contain mistakes. Even great mathematicians have written proofs with errors that
stood for years. A proof written in a special, super-strict language can be **checked by machine**,
line by line, with no room for hand-waving.

The computer doesn't get tired and doesn't get convinced by the author's reputation. If the proof
passes, the statement is true — *provided the checker itself is correct.*

That last part is the catch, and it is the heart of this project, so let's state it plainly:

> A computer-checked proof is only as trustworthy as the **checker**.

So the smart design is to make the checker **small**. A big, complicated checker might itself have a
bug. A tiny checker can be read and trusted by people. ProofAgent follows this rule obsessively: the
trusted part is kept as small as possible, and everything big and clever is kept *outside* the trust.

---

## 3. What is Lean?

**Lean** is a programming language for writing mathematics in a way a computer can check. It is both:

1. a way to *state* a theorem (say exactly what you claim is true), and
2. a way to *prove* it, step by step, in a form the machine can verify.

You write something like this (this is real Lean from the project):

```lean
example : ∀ n : Nat, n + 0 = n := by
  intro n
  rfl
```

Read it as: "Claim: for every natural number `n`, `n + 0 = n`. Proof: let `n` be an arbitrary number
(intro n), and then it's true by the very definition of adding zero (rfl) — done."

The bit that does the checking is called the **kernel**. The kernel is the tiny, trusted engine deep
inside Lean. Everything else (the friendly tools, the automation, the fancy proof search) is *outside*
the kernel and is *not* trusted. If the kernel says the proof is good, it's good.

This "small trusted kernel + big untrusted helpers" split is a standard idea in security, and it's
exactly the idea ProofAgent is built on.

> **Different phrase, same idea:** think of a **king and a stamp**. The king's royal seal (the kernel)
> is the only thing that makes a document official. Anyone can *write* a document (agents); only the
> seal makes it law.

---

## 4. The one big idea of ProofAgent

Here it is, in one sentence:

> **Untrusted agents propose; the trusted kernel disposes.**

Meaning:

- **Agents** = computer programs (often powered by AI / large language models) that *suggest* proofs.
  They are allowed to be creative, wrong, or even to try to cheat. We assume they might be hostile.
- **Kernel / gate** = the small trusted checker that *accepts* or *rejects* each suggestion. Its "yes"
  is the only thing that counts.
- A suggestion that passes is **recorded** (remembered). A suggestion that fails is thrown away.

Why build it this way? Because making *ideas* is now cheap, but *trustworthy truth* is expensive. If
you can't tell good ideas from confident-sounding nonsense, more ideas don't help — they just add
noise. So you invest in the strict checker and in a good memory of things already proved, and you let
the idea-generators (agents) be cheap and disposable.

This is why the project's slogan is: **"LLM proposes, kernel disposes."** (LLM = Large Language Model,
the kind of AI behind chatbots.)

---

## 5. What could go wrong — and how ProofAgent guards against it

When an AI (or a person) wants to look impressive, it can "cheat" without realizing it. The guards are
called the **failure modes**. Here are the most important ones, in plain words:

| The cheat | What it means | The guard |
|---|---|---|
| **`sorry`** | A Lean keyword that means *"pretend this is proved — I give up."* A statement with `sorry` is **not** proved at all. | The gate **rejects** anything containing `sorry`. |
| **`native_decide` / `unsafe` / other tricks** | Special Lean features that can bypass the careful checking. | The gate **rejects** these too. |
| **Changing the question** | Proving a *different, easier* statement than the one asked, then claiming victory. | The gate compares a **fingerprint** (hash) of the statement the agent proved against the one the human signed off on. |
| **Smuggling in extra assumptions** | Proving something *by assuming it* (or assuming something just as hard), hidden in the fine print. | The gate audits which **axioms** (starting assumptions) the proof relied on; only a tiny approved list is allowed. |
| **Poisoning the memory** | Feeding a *bad* result into the store of "known truths," so later proofs are built on sand. | **Rejections never enter verified memory.** Ever. |

The phrase "**compiled ≠ verified**" captures a subtle trap: a proof containing `sorry` will still
*compile* (Lean politely warns you, but doesn't stop). So "it compiled" is **not** the same as "it is
proved." Only the gate's verdict counts. This distinction is a first-class rule in the project.

---

## 6. What "plain-language" version of the machine exists today?

There is a real, small, **working** program in this project (in the [`skeleton/`](../../skeleton)
folder) — a "walking skeleton," like a simple robot that walks one step so you can see the mechanics
work. It:

1. takes a **statement** (the theorem to prove) and a **proposed proof**,
2. runs it through the **gate** (the strict checker described above),
3. **only if it passes**, writes it into a memory file.

Its test suites deliberately include **cheating proofs** and confirm the gate **rejects every one**,
and an **honest proof** the gate **accepts**. That's the whole trusted loop, small enough to read in an
afternoon.

What it does **not** yet do: search for proofs cleverly, read research papers, run for days on its
own, or "sense the world." Those are the bigger goals — designed, and written down as the "final"
system — but the small honest core is the part you can actually run right now.

---

## 7. Where to go next

- **Still curious, no math background needed:** stop here, then skim the [glossary](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
- **Want the full "how it works" with mechanisms:** go to [Level T1 — Intuition](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **Want to build and run it:** go to [Level T2 — Practitioner](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t2-practitioner.md).
- **Are you a researcher/engineer:** the deep argument is in [Level T3 — Expert](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t3-expert.md).

---

### T0 in one paragraph

A **proof** is a rigorous argument that a statement is true in every case. **Lean** is a language a
computer can use to *state* and *check* such proofs, using a tiny trusted **kernel**. **ProofAgent**
is a design — plus a small working skeleton — for a system where lots of cheap, untrusted AI **agents
propose** proofs and a small, strict **gate disposes**: it rejects known cheats (`sorry`, statement
swapping, smuggled assumptions), and only what passes is remembered. Because "it compiled" isn't "it's
proved," the project keeps the trusted part tiny and makes honesty a rule, not a hope.
