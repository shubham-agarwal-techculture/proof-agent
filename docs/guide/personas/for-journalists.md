# For Journalists

*For reporters and writers covering AI, mathematics, or verification, who need to separate what is real
from what is aspiration.*

## In one line

ProofAgent is a design record plus a small, working "walking skeleton" for an **agentic theorem-proving
system on Lean 4**, whose one-line rule — *untrusted agents propose; the trusted kernel disposes* — is
the real story, not any claim of automated mathematical discovery.

## Why this matters to you

The first job of a careful story is to separate what exists from what is planned. ProofAgent is a
**design plus a small working skeleton**. The trusted core — a gate that rejects cheating proofs and
admits only honest, on-statement, allow-listed-axiom results — plus an append-only content-addressed
memory, the propose→verify→record loop, and three tools are **built and tested** (four test suites pass
on Lean 4.35.0). The agentic system, retrieval, curiosity, sensors, and federation are **designed, not
built**. Quote that distinction; the project states it itself.

The one idea worth explaining is the slogan: *"untrusted agents propose; the trusted kernel disposes."* A
small, strict checker is the only thing whose "yes" counts; everything clever is untrusted. That is the
hook, and it is genuinely interesting without exaggeration — it inverts the usual "make the AI smarter"
framing.

There is a subtle, quotable trap: **a `sorry` proof still compiles.** In Lean, the word `sorry` means
"pretend this is proved," yet a file containing it still *builds*. So "it built" is not "it's proved."
The project calls this **compiled ≠ verified** and makes it a rule. That detail shows rigor rather than
hype, and it generalises well beyond maths.

Do not claim it solves famous problems or outperforms mathematicians. The design reports **no benchmark
results**, because the system that would produce them does not exist. It states falsifiable bets (for
example, B1 on verification versus agent count) explicitly so they can be tested later — not because
they are proven now.

Be precise about "verified," too. In the skeleton, a result is "verified" when the trusted gate accepts
it; the design's stronger notion — an **independent re-checker** that agrees — is designed but not
built. Do not report the skeleton's "verified" as if a second, independent kernel had confirmed it.

The human story is real as well: the design puts **humans in the loop where it matters** (admitting
definitions, and any safety-critical claim about the real world), and it warns that the scariest risk is
not unsolved maths but **fidelity** — proving a statement that looks like the intended one but isn't.

## What to take away

- **It is a design + a small tested skeleton, not a product.** The trusted core, memory, orchestrator, and tools are real; the "agentic system" is designed. Say which is which.
- **The hook is the inversion.** *Untrusted agents propose; the trusted kernel disposes.* Keep the focus on the trust boundary, not on agent cleverness.
- **The quotable trap: "compiled ≠ verified."** A `sorry` proof still builds; the gate is what rejects it. This is the sharpest, most honest detail in the project.
- **No benchmarks, no solved-theorem claims.** The design explicitly reports none, because the scale system is unbuilt. Treat every number as a labelled assumption, not a result.
- **"Verified" carries a footnote.** In the skeleton it means "the gate said yes"; the independent re-checker is designed, not built. Don't inflate it.
- **The design is honest about its own gaps.** It labels maturity (`[exists today]` … `[speculative]`), and names its weakest links. Quote those labels — they are the story.

## Claims to avoid — and what to say instead

| Tempting claim | Accurate phrasing |
|---|---|
| "An AI that proves theorems on its own" | "A design, plus a small tested skeleton; the agentic prover is not built" |
| "It replaces mathematicians" | "It proposes candidates; humans still own definitions and real-world claims" |
| "It solved `<famous problem>`" | No such claim is made; there are no benchmark results to cite |
| "It's a product / a startup" | It is a design record plus a working proof-of-policy |
| "Its proofs are checked by many kernels" | In the skeleton, "verified" means the gate accepted it; the independent re-checker is designed, not built |
| "It compiles, so it's proven" | "Compiled ≠ verified" — a `sorry` proof compiles and is still rejected |

## Suggested framings

- **Lead with the inversion.** Most "AI for maths" stories are about making the AI smarter; this one is about making the *checking* trustworthy — untrusted agents propose, a tiny trusted checker disposes.
- **Use the fridge-door fact.** Say "in Lean, a proof containing `sorry` still compiles," then explain *compiled ≠ verified*. It is concrete, checkable, and memorable.
- **Frame it as infrastructure, not conquest.** A design record plus a working proof-of-policy, aimed at *reliable* machine-checked results — not at beating humans.
- **Quote the honesty.** "The scale system is designed, not built." Starting with the project's own caveat is a story in itself.
- **Show the failure modes.** The design's pre-mortem — attacks on the trusted core, on memory, on meaning — is rich material that is hard to hand-wave.

## A short glossary for a story

- **Lean** — a programming language for stating and machine-checking mathematics.
- **Kernel** — the tiny trusted engine inside Lean that performs the check.
- **Proof assistant** — software you use to write and check proofs.
- **`sorry`** — Lean's "pretend this is proved" placeholder; the file still compiles.
- **`compiled ≠ verified`** — "it built" is not "it's proved."
- **Trusted core** — the small component whose verdict is the only one trusted.

## Six questions worth asking the team

1. **What is built today, versus designed?** The honest answer names a small, tested gate, memory, and
   tools — and an unbuilt scale system.
2. **Where are the benchmark results?** There are none; the system that would produce them does not exist.
3. **What does "verified" mean here?** In the skeleton, the trusted gate accepted it — not a second,
   independent kernel.
4. **What is the biggest risk?** Fidelity: proving a lookalike statement rather than the one that was
   meant, which the design treats as first-class.
5. **What would prove the central claim wrong?** An agent-count sweep at fixed verifier budget that
   *keeps* paying off would falsify the design's own bet (B1).
6. **Who owns meaning?** Humans — for admitting definitions and for real-world, safety-critical claims.

## Three explainers, at three lengths

- **One sentence.** A team proposes machine-checked proofs; a tiny trusted checker decides which ones
  count, so the clever part is never the part you have to trust.
- **One paragraph.** The trick is an old security idea — keep the trusted core small. In Lean, a proof can
  contain a placeholder (`sorry`) and still compile, so "it built" isn't "it's proved." A strict gate
  rejects the placeholder, mismatched statements, and smuggled assumptions, and only accepted results are
  remembered. The agentic system around it is designed, not built.
- **One caveat, to say first.** "Verified" in the running skeleton means the gate said yes; the stronger
  notion — a second, independent checker agreeing — is designed but not built. Say that before anyone
  calls it a done deal.

## Where to go next

- **The absolute-beginner level (good for background):** [t0-high-schooler.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t0-high-schooler.md).
- **The "how it works and why" level:** [t1-intuition.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/t1-intuition.md).
- **The one-page case:** [phase-8-decision-memo.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-8-decision-memo.md).
- **What could go wrong (the pre-mortem):** [phase-7-red-team.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/phase-7-red-team.md).
- **The code (and its own honesty notes):** [skeleton README](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/skeleton/README.md).
- **Definitions:** [glossary.md](file:///d:/projects-shubham/02.06.2026/personal_projects/proof-agent/docs/guide/glossary.md).
