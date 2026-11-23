# For Teachers

*For teachers of mathematics, logic, or computing who want to teach proof, rigor, and healthy
skepticism about computers and AI.*

## In one line

ProofAgent is a worked example — and a small, running program — of the gap between "it looks right / it
compiles" and "it is actually proved," built around one tiny trusted checker, and it makes an unusually
clean classroom case study for what a proof is, why checking matters, and how to reason about trusting
a machine.

## Why this matters to you

The hardest thing to teach about proof is that it is *not* the same as "it worked for the examples we
tried." Students reasonably believe that a pattern holding five times will hold forever. ProofAgent
takes that intuition seriously by building a machine around the distinction, and by making it concrete
rather than abstract. The machine splits **compiled** ("the computer read my text without complaint")
from **verified** ("a small trusted checker confirmed the claim against the statement a human signed off
on"). That gap is something you can *point at*, run, and argue with — not just assert.

It is also, quietly, a lesson about trusting technology. In Lean (the proof language here), a fake proof
containing the word `sorry` still *builds*. A student who assumes "the computer said OK, so it must be
right" has just made the same mistake as trusting a confident-sounding answer with no working shown.
The project turns this into a rule and a slogan — *"compiled ≠ verified"* — which is a clean, memorable
way to teach the difference between *looks finished* and *is correct*. You can run it as a live
demonstration: show a "proof" that builds, then show the strict checker rejecting it.

The third lesson is about how ideas become knowledge. ProofAgent stores the results that were
*verified* and refuses to store the ones that were rejected, so a wrong idea can never quietly become
an assumption for later work. That is a crisp model of how a class — or a field — should build on
established results while quarantining unproven claims. It invites a discussion question students
rarely hear: *how do we decide what to remember and build on, and what to set aside?*

The project also gives you a vocabulary for the *ways reasoning goes wrong*. Its catalogue of "failure
modes" is really a list of cheats, and each one mirrors a human rhetorical habit:

| In ProofAgent (the cheat) | The human habit it mirrors |
|---|---|
| the word `sorry` ("pretend it's proved") | saying "obviously" and moving on |
| proving a *different, easier* statement | answering an easier question than the one asked |
| smuggling in extra assumptions (axioms) | assuming your conclusion, or hiding a premise in fine print |
| proving against a *weakened* statement | quietly dropping a condition ("for all inputs") |

That table alone is a lesson in reading arguments skeptically — and it works in an English class as
much as a maths one.

Finally, the project models **intellectual honesty** for students. It states plainly what exists
(`[exists today]`: a small, tested core) and what is only designed (`[near-term]`, `[frontier]`,
`[speculative]`: the large, clever system). That is exactly the discipline you want in a student's work:
say what you actually showed, and be clear about what you only hoped would be true.

And a practical point: you do **not** need Lean, or any code, to use the *ideas*. The core messages —
proof versus checking cases; trust a small careful check over a confident answer; separate "it built"
from "it's proved" — can be taught and discussed entirely on paper. The running program is a bonus for
a curious student, not a prerequisite.

## What to take away

- **A ready-made "gotcha" for the classroom.** The cheat word `sorry` lets a Lean file *compile* while proving nothing. Asking students "does this build?" then "is it *proved*?" is a memorable, hands-on distinction. `[exists today]` — the small program runs.
- **The "small trusted checker" idea generalises.** ProofAgent keeps the part that must be right tiny (like a royal seal) and treats all the clever helper software as untrusted — a pattern students meet again in security and in evaluating sources.
- **The failure modes are reasoning mistakes, not coding quirks.** Pretending, answering the wrong question, and assuming your conclusion are the same errors in essays as in proofs; naming them helps students spot them anywhere.
- **Honesty is built into the artifact.** The project labels its own claims by maturity and refuses to present unbuilt parts as done — a habit worth naming when you grade or critique student work.
- **"It built" is not "it's proved."** Say this often; it is the most transferable idea here, and it applies to AI answers, search results, and arguments alike.
- **The scale system is a plan, not a fact.** The design is explicit that the big agentic system is *designed, not built*; only the small trusted core exists and is tested. Modelling that distinction is itself a lesson.

## A 30-minute lesson sketch

The ideas work with no code at all; the running program is an optional finale.

1. **Warm-up (5 min).** Show `3 + 0 = 3`, `7 + 0 = 7`, `100 + 0 = 100`. Ask: does that *prove* `n + 0 = n` for every number? Draw out the difference between checking cases and proving.
2. **The trap (5 min).** Introduce the cheat word `sorry`. The key surprise: a proof containing `sorry` still *builds* — so "it compiled" is not "it's proved."
3. **The king and the stamp (5 min).** Many helpers may propose ideas; one small, strict checker decides. Ask whose word the class would trust, and why a *small* checker is easier to trust than a clever one.
4. **The cheats table (5 min).** Map each ProofAgent cheat to the human habit it mirrors — pretending, answering the wrong question, assuming your conclusion.
5. **Memory (5 min).** Explain that rejected ideas are *never* stored, so a wrong claim can't quietly become a fact later. Ask why that matters in class discussion too.
6. **Wrap-up (5 min).** Return to the slogan: *"it built" is not "it's proved."* Ask students where else that applies (search results, AI answers, arguments).

## Common student questions (and short answers)

- **"If the computer checked it, why is trusting it still a problem?"** A machine-checked proof is only as trustworthy as the *checker*. So ProofAgent keeps the checker tiny — small enough for a person to audit — and keeps everything big and clever *outside* the trust.
- **"If it compiled, why isn't it proved?"** Because Lean lets you write the cheat word `sorry`, which means "pretend it's proved," and the file still *builds*. The gate is what rejects it. That is the project's slogan: *compiled ≠ verified*.
- **"Can the AI just change the question to something easier?"** It can try. The gate compares a fingerprint of the statement it proved against the statement a human signed off on, so a swapped statement is rejected.
- **"Why not just use the smartest AI?"** Because the design's bet is that the bottleneck is *checking*, not *suggesting*. The idea-generators can be cheap and plentiful; only the checker needs care.
- **"What happens to wrong ideas?"** They are discarded and *never* stored as "known truths," so a mistake can't quietly become an assumption for later work.

## What the running program actually does (so you can demo it)

The small program (a "walking skeleton") performs one honest loop: take a proposed proof, run it through
the strict gate, and — only if the gate accepts it — write it into a memory file. Its test suites
deliberately include *cheating* proofs and confirm the gate rejects every one, alongside one honest
proof the gate accepts. It builds and its tests pass on the pinned Lean toolchain, with no extra
libraries. Exact commands are in the [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md).

## An activity students can do on paper

You can run the whole lesson with no computer:

1. **Invent a pattern.** Write four numbers that follow a rule (`1, 2, 4, 8, …`). Have a partner guess the rule. Show that the same four numbers fit *many* rules, so "it fits the examples" is not a proof.
2. **Write the honest version.** State the rule "for every number," and ask students to justify it for *all* cases, not just the ones on the board.
3. **Play the checker.** One student is the "stamp": they may only say yes if the argument covers every case and adds no hidden assumptions. Anyone who answers "obviously" gets sent back.
4. **Add a cheat.** Have one student try to slip in "…and just assume the rule is true." Watch the class catch it — that is the real "smuggled assumption" cheat in disguise.

The point students should carry out the door: a small, strict check on the *whole* claim beats a confident-sounding argument about examples.

## Vocabulary you can reuse

A few terms from the project are worth naming precisely in class, because the whole lesson is about keeping them apart:

- **Claim** — a proposed proof, not yet accepted. Everything untrusted starts here.
- **Gate / stamp** — the one component whose "yes" counts; it checks the claim against the *signed* statement.
- **Compiled** — "the computer read my file without complaint." The weak word.
- **Verified** — "the trusted checker accepted this against the statement a human signed." The strong word.
- **Memory** — the notebook of *accepted* results only; rejected ideas never enter it.

Naming these keeps "it built," "it's proved," and "it's remembered" as three separate ideas — exactly the separation the project is built on.

## Where to go next

- **The plain-language starting point (no math assumed):** [t0-high-schooler.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md).
- **The "how it works and why" level:** [t1-intuition.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **Any term, defined simply and precisely:** [glossary.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
- **If a student wants to run it:** the [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md) shows the build and test commands.
- **The overall map of this guide:** [README.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/README.md).
