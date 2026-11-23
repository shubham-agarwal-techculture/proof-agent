/-
  ProofAgent/Memory.lean — the append-only, content-addressed memory store (design §5.5).

  This is the "real" replacement for the in-memory `Store`: entries are serialised as JSONL
  (one JSON object per line) and appended to disk.  Content-addressing + content-level dedup
  implement invariant #3 (provenance) and the Phase-5 dedup lever, and the append-only discipline
  counters failure mode F7 (memory poisoning).

  The hashing is a non-cryptographic FNV-1a used *only* to give entries a stable content key in the
  skeleton; the production system uses SHA-256 over the canonical artifact bytes.
-/
import Lean.Data.Json

open Lean

namespace ProofAgent

/-- One content-addressed memory entry with provenance (invariant #3). -/
structure MemEntry where
  hash      : String
  statement : String
  producer  : String
  /-- "verified" (kernel + independent re-check + statement match) or "candidate" (quarantined). -/
  status    : String
  deriving Repr, Inhabited, BEq

/-- In-memory view of a store (mirrors the on-disk log). -/
abbrev Store := List MemEntry

/-- FNV-1a (64-bit) over the UTF-16 code units of a string.  Non-cryptographic; skeleton only. -/
def fnv1a (s : String) : UInt64 :=
  s.toList.foldl
    (fun h c => (h ^^^ c.toNat.toUInt64) * 1099511628211)
    14695981039346656037

/-- Stable content key for a string. -/
def contentHash (s : String) : String := toString (fnv1a s)

/-- Content address of an entry: hash of its canonical content. -/
def MemEntry.key (e : MemEntry) : String :=
  contentHash (e.hash ++ "|" ++ e.statement ++ "|" ++ e.producer ++ "|" ++ e.status)

/-- JSON encoding of an entry (canonical field order). -/
def MemEntry.toJson (e : MemEntry) : Json :=
  Json.mkObj [ ("hash", Json.str e.hash), ("statement", Json.str e.statement),
               ("producer", Json.str e.producer), ("status", Json.str e.status) ]

/-- JSON decoding of an entry; fails on any missing/ill-typed field. -/
def MemEntry.ofJson? (j : Json) : Except String MemEntry := do
  let hash      ← j.getObjValAs? String "hash"
  let statement ← j.getObjValAs? String "statement"
  let producer  ← j.getObjValAs? String "producer"
  let status    ← j.getObjValAs? String "status"
  return { hash, statement, producer, status }

/-- Append one JSON line to the log (creates the file if absent). -/
def appendLine (path : System.FilePath) (line : String) : IO Unit := do
  let h ← IO.FS.Handle.mk path IO.FS.Mode.append
  h.putStrLn line

/-- Read and parse the whole log.  Blank lines are skipped; malformed lines are dropped (a real store
    would quarantine them to failure memory). -/
def load (path : System.FilePath) : IO (Array MemEntry) := do
  if !(← path.pathExists) then return #[]
  let content ← IO.FS.readFile path
  let lines := (content.splitOn "\n").filter (fun l => l ≠ "")
  let mut acc : Array MemEntry := #[]
  for l in lines do
    match Json.parse l >>= MemEntry.ofJson? with
    | .ok e    => acc := acc.push e
    | .error _ => pure ()
  return acc

/-- Insert an entry unless an entry with the same content key already exists (dedup).
    Returns `true` iff a new line was appended.  Append-only: entries are never mutated. -/
def insert (path : System.FilePath) (e : MemEntry) : IO Bool := do
  let entries ← load path
  if entries.any (fun x => x.key == e.key) then
    return false
  else
    appendLine path (Json.compress e.toJson)
    return true

/-- Number of entries currently in the log. -/
def size (path : System.FilePath) : IO Nat := do
  return (← load path).size

end ProofAgent
