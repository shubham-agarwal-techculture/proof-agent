/-
  ProofAgent/Orchestrator.lean — the minimal propose → verify → record loop.

  Control flow lives here (an ordinary runtime); only the gate's policy lives in the trusted core.
  Recorded memory is content-addressed and provenance-carrying (invariant #3).  Rejected proposals
  NEVER enter verified memory (counters failure mode F7, memory poisoning).
-/
import ProofAgent.VerifierGate
import ProofAgent.Memory

namespace ProofAgent

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

/-- End-to-end: run the gate, and only on `.verified` persist the entry to the append-only JSONL
    store (deduped by content key).  Rejections are never persisted to verified memory. -/
def verifyAndRecord (path : System.FilePath) (spec : ProblemSpec) (claim : Claim)
    (provedHash : String) (axiomsUsed : List String) : IO Verdict := do
  let v := gate spec claim provedHash axiomsUsed
  match v with
  | .verified =>
      let _ ← insert path
        { hash := spec.specHash, statement := spec.statement,
          producer := claim.producer, status := "verified" }
      return v
  | _ => return v

end ProofAgent
