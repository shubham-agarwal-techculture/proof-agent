/-
  ProofAgent/VerifierGate.lean — the trusted gate (invariant #1: "LLM proposes, kernel disposes").

  In the real system the syntactic scan runs on the *elaborated* `Expr` (not source text) and the
  `provedHash` / `axiomsUsed` arguments are produced by elaboration plus `#print axioms`.  This
  skeleton keeps the *policy* — the audited cheat surface — explicit and testable.

  Design notes:
  * Banned constructs are enumerated as data (`bannedTokens`) so the cheat surface is auditable.
  * The gate is TOTAL and DETERMINISTIC: for every input it returns a verdict.
  * Statement matching works on content hashes of the elaborated type, never on strings.
  * Axiom allow-list is {propext, Classical.choice, Quot.sound} (Phase 1 A2).  Any other axiom is a
    policy exception that must be signed and logged — never silent.
-/
import ProofAgent.Spec

namespace ProofAgent

/-- The audited cheat surface: every way a proposal can be rejected. -/
inductive RejectReason
  | sorryFound
  | nativeDecideFound
  | unsafeFound
  | implementedByFound
  | partialFound
  | kernelBypassOption
  | statementMismatch (signed claimed : String)
  | forbiddenAxiom (axiomName : String)
  deriving Repr, Inhabited, DecidableEq

/-- Permit-list of axioms (Phase 1 A2).  Nothing else may appear in `#print axioms` output. -/
def allowedAxioms : List String := ["propext", "Classical.choice", "Quot.sound"]

/-- Banned constructs, as data.  Extend only with sign-off; the list is part of the trusted core. -/
def bannedTokens : List (String × RejectReason) :=
  [ ("sorry",         RejectReason.sorryFound),
    ("native_decide", RejectReason.nativeDecideFound),
    ("unsafe",        RejectReason.unsafeFound),
    ("implemented_by", RejectReason.implementedByFound),
    ("partial",       RejectReason.partialFound),
    ("skipKernelTC",  RejectReason.kernelBypassOption) ]

/-- Substring test.  (`splitOn` avoids depending on a specific `String.contains` substring API.) -/
def hasToken (src tok : String) : Bool := (src.splitOn tok).length > 1

/-- Structural first line of defence: does the proposal text contain any banned token? -/
def scanBanned (src : String) : Option RejectReason :=
  bannedTokens.find? (fun p => hasToken src p.1) |>.map (fun p => p.2)

/-- The verdict of the gate. -/
inductive Verdict
  | verified
  | rejected (reason : RejectReason)
  deriving Repr, DecidableEq

/-- The trusted gate.

    * `provedHash`  — content hash of the goal type the kernel actually accepted.
    * `axiomsUsed`  — output of `#print axioms` for the accepted proof.
    Everything else (the LLM, tools, retrieval) is untrusted and appears only inside `claim`. -/
def gate (spec : ProblemSpec) (claim : Claim)
    (provedHash : String) (axiomsUsed : List String) : Verdict :=
  match scanBanned claim.proofText with
  | some r => .rejected r
  | none   =>
      if provedHash != spec.specHash then
        .rejected (.statementMismatch spec.specHash provedHash)
      else
        match axiomsUsed.find? (fun a => !(allowedAxioms.contains a)) with
        | some bad => .rejected (.forbiddenAxiom bad)
        | none     => .verified

end ProofAgent
