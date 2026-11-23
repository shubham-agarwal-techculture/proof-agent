/-
  ProofAgent/Orchestrator.lean — the minimal propose → verify → record loop.

  Control flow lives here (an ordinary runtime); only the gate's policy lives in the trusted core.
  Recorded memory is content-addressed and provenance-carrying (invariant #3).  Rejected proposals
  NEVER enter verified memory (counters failure mode F7, memory poisoning).
-/
import ProofAgent.VerifierGate

namespace ProofAgent

/-- One content-addressed memory entry with provenance (invariant #3). -/
structure MemEntry where
  hash      : String
  statement : String
  producer  : String
  /-- "verified" (kernel + independent re-check + statement match) or "candidate" (quarantined). -/
  status    : String
  deriving Repr, Inhabited

/-- In-memory store.  The real system is an append-only JSONL log plus an index. -/
abbrev Store := List MemEntry

/-- One orchestrator step.  `propose` (the untrusted agent) is out of band; here its output is the
    `claim`.  `provedHash`/`axiomsUsed` come from elaboration + `#print axioms` in the real system.

    On `.verified`, a `verified` entry is appended.  On any rejection, memory is left unchanged and
    the rejection is returned (in the real system it is logged to failure memory, never to verified
    memory). -/
def step (store : Store) (spec : ProblemSpec) (claim : Claim)
    (provedHash : String) (axiomsUsed : List String) : Store × Verdict :=
  match gate spec claim provedHash axiomsUsed with
  | .verified =>
      let entry : MemEntry :=
        { hash := spec.specHash, statement := spec.statement,
          producer := claim.producer, status := "verified" }
      (store ++ [entry], .verified)
  | rej => (store, rej)

end ProofAgent
