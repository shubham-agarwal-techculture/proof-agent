# Phase 8 — Decision Memo (one page)

**To:** the funder / technical lead · **From:** the four-person design team · **Re:** Agentic,
curious, memory-rich theorem-proving system on Lean 4 + Mathlib
**Date:** 2026-11-23 · **Status:** design complete; decision requested

---

**The one-sentence thesis.** Build a **trusted verification core + compounding memory** and treat
agents as a cheap, elastic, *untrusted* frontier — because the bottleneck is verified truth, not
ideas, and more agents stop helping well before 10³ on any single theorem.

**What to build first (in this order).**

1. **The verifier gate** — reject `sorry`/`native_decide`/`unsafe`/`implemented_by`/`partial`/
   `skipKernelTC`; statement-match to a signed spec; axiom allow-list `{propext, Classical.choice,
   Quot.sound}`; **independent re-check** before anything is called *verified*.
2. **Memory** — content-addressed artifacts, working/episodic/semantic/procedural layers, dedup/cache
   and a dead-end register. This is the compounding engine and the biggest cost lever.
3. **Instrumentation** — measure demand rate, verifier capacity, dedup factor, retrieval precision,
   cost/verified theorem, GPU-s/lemma. *Without this, nothing here is falsifiable.*
4. **Then** retrieval, then better single-agent reasoning, then curation, and **agents last**.

**What to cut (for now).**

- **Actuators** — real actuation is v4 and human-gated only; simulation first, never irreversible
  without the model-gap machinery.
- **Swarms beyond ~100 per theorem** — depth does not parallelize (proof-DAG speedup ceiling ≈ 2–3×).
- **Federation (sharing across instances)** — defer to v3 and restrict to *verified-artifact pull*;
  it imports supply-chain risk into invariant #1.
- **Open-ended discovery** — stage it at v2+ **behind a frozen evaluator**; it never touches the core.

**What to bet on (falsifiable).**

- **B1 — Verification/memory throughput beats agent count.** *Test:* fixed verifier budget,
  N ∈ {10,100,1000} on one hard problem; find the knee in time-to-solve and cost/lemma.
- **B2 — Fidelity is the real risk, not raw capability.** *Test:* a real paper → Lean intake where a
  dropped hypothesis is caught by the statement auditor.
- **B3 — Compounding memory is super-linear.** *Test:* cost/lemma falls as dedup `d` rises, then
  rises again once `d` saturates (the U-shaped curve).

**What to decide this week.**

1. **Approve the parameter defaults** (Phase 1: research-math users; combinatorics+number-theory first;
   1–2 8-GPU nodes, ≤ US$50k/mo; 4 engineers + 1 Lean expert). Any override changes cost, not shape.
2. **Fund the 90-day MVP** with the four-part demo: (i) live rejection of every cheat class, (ii)
   statement-audit catching a sloppy formalization, (iii) the N-sweep knee (or its honest absence),
   (iv) checkpoint/restart with dead-end reuse.
3. **Adopt the trust rule as policy:** "compiled ≠ verified"; `verified` requires an independent
   re-check of a statement-matched, axiom-audited export. Nothing reaches memory otherwise.
4. **Name the human gates:** definition admission to the shared library, and any `safety_critical`
   claim about the real world. (Both are irreducible; automation cannot own them.)

**What we are least sure of (watch, don't hide).** Fidelity work may double the MVP timeline (Phase 1
Q1); the independent re-checkers may share assumptions (F4); retrieval and dedup may decay at portfolio
scale (F16). Each has a **kill criterion** (Phase 6) and an **early-warning signal** (Phase 7).

**Ask.** Approve (1)–(4) and fund the 90-day MVP. Everything else is sequencing and can be revisited
without re-architecting.

---
*Supporting detail: Phase 0 landscape · Phase 1 framing · Phase 2 architecture · Phase 3 deep dives ·
Phase 4 worked examples · Phase 5 scale & economics · Phase 6 roadmap · Phase 7 red-team ·
Phase 9 walking skeleton. See `docs/README.md`.*
