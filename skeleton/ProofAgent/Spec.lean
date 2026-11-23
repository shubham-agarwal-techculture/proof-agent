/-
  ProofAgent/Spec.lean — the core, content-addressed artifacts (invariant #3).

  This is the "spec" side of the trusted boundary: what the *human* signed (a `ProblemSpec`)
  and what an *untrusted* agent *claims* to have proved (a `Claim`).  Nothing here is trusted;
  the gate in `VerifierGate.lean` is what decides.
-/
namespace ProofAgent

/-- A signed problem statement.  `specHash` is the content hash of the *elaborated* goal type —
    the reference the gate compares against (Phase 1 A1, invariant #2). -/
structure ProblemSpec where
  id             : String
  /-- Human-readable statement (never used for trust decisions). -/
  statement      : String
  /-- Content hash of the elaborated goal type; the signed reference. -/
  specHash       : String
  /-- If true, a real-world claim requires human sign-off (invariants #2, #8). -/
  safetyCritical : Bool := false
  /-- Intake domain, e.g. "mathematics", "control", "protocol". -/
  domain         : String := "mathematics"
  deriving Repr, Inhabited

/-- A proposal from an untrusted agent.  Assumed hostile: it may carry `sorry`, extra axioms,
    altered statements, `unsafe`/`implemented_by`, kernel-bypass options, etc. -/
structure Claim where
  /-- The hash of the statement the agent *claims* it proved.  Checked against `spec.specHash`. -/
  specHash    : String
  /-- Producer id (agent/model/version) for provenance. -/
  producer    : String
  /-- The Lean source text of the proposed proof. -/
  proofText   : String
  /-- Content hashes of memory artifacts the agent cites as premises (for poisoning analysis). -/
  derivesFrom : List String := []
  deriving Repr, Inhabited

end ProofAgent
