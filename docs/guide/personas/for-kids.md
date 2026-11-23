# For Kids

*For readers aged about 10–13 who like puzzles and want to know what this "proof machine" is.*

## In one line

A **proof** is a careful argument that something is true *every single time*, not just in the few cases
you tried — and **ProofAgent** is a plan for a team of helper robots that try to write proofs, watched
over by one very strict checking robot whose "yes" is the only "yes" that counts.

## Why this matters to you

Think about a puzzle: you see `2, 4, 6, 8, …` and you guess `10`. But what if the real rule was "even
numbers, then a giant jump"? With only four numbers you *can't know*. In math, guessing from examples is
not enough; you need a **proof** — a reason that works for *every* case, including the ones nobody has
ever checked. This whole project is built on that one idea.

Now imagine a robot writes proofs for you, so you don't have to. Wonderful... until it cheats by
accident. In a proof language called **Lean**, there is a cheat word, `sorry`, that means *"pretend this
is proved — I give up."* A file with `sorry` in it will still **build** without an error! So a robot
that only asked "did it build?" would happily hand you a fake proof. That is the trap this project is
built to avoid.

A real proof, by the way, can be short and clear. Here is one, written in Lean:

```lean
example : ∀ n : Nat, n + 0 = n := by
  intro n
  rfl
```

Read it as: "For every number `n`, `n + 0 = n`. Proof: pick any number (`intro n`), and it's true by
the very meaning of adding zero (`rfl`). Done."

The fix for cheating comes from a very old idea: **a king and a stamp**.

```
  Many helpers (NOT trusted)         One tiny checker (trusted)
  +-----------------------+          +------------------------+
  | robots write ideas    |          | is this the signed     |
  | wrong ideas welcome   |  ----->  |   question?            |
  | they can't be trusted | propose  | any cheat word?        |
  +-----------------------+          | sneaky assumptions?    |
                                     |  YES -> stamp it (ok)  |
                                     |  NO  -> throw away     |
                                     +------------------------+
```

Lots of helpers may *write* anything they like. Only the little trusted machine with the stamp gets to
say "this one is official." Ideas are cheap; the stamp is precious.

Why not just trust the helpers? Because there might be *millions* of them guessing at once, and some
will be wrong or even trying to trick you. It is much easier to build one small, simple machine you can
check *completely* than to check millions of clever robots. Grown-ups use this trick everywhere: keep
the part you must trust as tiny as possible, and let everything else be as wild and creative as it
wants.

There is one more clever part: the **memory** — a big notebook where the stamped proofs go, so the
robots can reuse them instead of solving the same puzzle twice. The rule is strict: when the stamp says
"no," that idea is thrown away and **never** goes in the notebook, so one fake proof can't sneak in and
trick every robot that comes later. (The grown-ups call that "no memory poisoning" — a fancy way of
saying "don't let a lie quietly become a fact.")

Do you have to be a maths genius to help? No. The helpers can be as silly or as clever as they like,
because the stamp decides. That means the *idea-makers* can be cheap and plentiful, and only the
*checker* needs to be careful — the opposite of the usual plan, where you hunt for the one smartest
robot and trust it completely.

One last grown-up secret: this project is honest about what it has and hasn't done. The little checking
robot really exists and works today. The huge team of proof-hunting robots is still just a drawing.
Saying *which* is which is a big part of being a good scientist.

Here are the main ways to cheat, in plain words:

| The cheat | What it means | The guard |
|---|---|---|
| `sorry` | "Pretend this is proved." | The stamp throws it out. |
| Proving a different question | Proving something easier and claiming victory. | The stamp checks it's the *signed* question. |
| Sneaky assumptions | Quietly assuming something just as hard. | The stamp checks which assumptions were used. |
| Poisoning the memory | Feeding a lie into the notebook. | "No" ideas never go in the notebook. |

## What to take away

- **Checking examples is not proving.** `3 + 0 = 3`, `7 + 0 = 7`, `100 + 0 = 100` are nice, but the *proof* is the sentence "adding zero never changes a number — for every number."
- **The checker must be small to be trusted.** A huge, clever checker might secretly be broken. ProofAgent keeps the trusted part tiny and puts everything big and clever *outside* the trust.
- **Beware the cheat word `sorry`.** It means "pretend this is done." The strict stamp throws out any proof that uses it — along with a few other sneaky tricks.
- **"It built" is not "it's proved."** A machine that only checks "did it compile?" can be fooled. ProofAgent asks the tougher question: "did the stamp say yes?"
- **No cheating your way in.** If the helpers prove a *different, easier* question, or quietly assume something they shouldn't, the checker catches that too.
- **The little robot is real; the big team is a plan.** The small, honest loop (propose → check → remember) is built and tested today. The fancy proof-hunting robots, and the idea of thousands of them working together, are still just plans on paper. Good builders say which is which.

## Where to go next

- **Start at the very beginning — no math background needed:** [t0-high-schooler.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md).
- **Stuck on a word?** Look it up in the [glossary.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
- **Want the whole map of this guide?** Open the [README.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/README.md).
- **Ready for something a little harder?** Try [t1-intuition.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
