# RLN Implementation Card

Use this when an agent needs to build or test a small RLN app, especially anonymous chat or posting with one message per epoch.

## Verified Baseline

Checked on 2026-06-02:

- `Rate-Limiting-Nullifier/rln-docs` describes registration, signaling, duplicate detection via public nullifiers, and optional withdrawal/slashing;
- the classic/audited route should be treated as implementation-specific: pin the exact circuit, verifier, artifacts, and contract path;
- `Rate-Limiting-Nullifier/rln-v3` is a Semaphore V4-based implementation/benchmark reference with `browser/proof`, `node`, `circuits/circom`, and `circuits/noir`;
- observed v3 proof generation uses `Identity` and `Group` from `@semaphore-protocol/core`;
- observed v3 proof shape includes `y`, `merkleTreeDepth`, `merkleTreeRoot`, `nullifier`, `message`, `scope`, and `points`;
- v3 should still carry the caveat that its circuits have not been separately audited unless upstream docs change.

## Completion Gate

Do not describe a build as a working RLN app until accepted signals pass real proof verification for the selected route. Server counters, mock verifiers, hardcoded public outputs, client-claimed nullifiers, and fixture-only proof JSON can be used while scaffolding, but the final answer must mark the app incomplete if any of those still decide message acceptance.

For an app-facing prototype, "real" means:

- commitments are derived from private user secrets;
- group membership/root data is used in proof generation;
- proof generation runs against the selected circuit/artifact path;
- verification runs before the signal is accepted;
- duplicate detection uses verified public outputs, usually `(appId, epoch, nullifier)`, not profile IDs or client counters.

## App Payload

Normalize implementation-specific values into this shape at the app boundary:

```typescript
type RlnSignalPayload = {
  appId: string
  epoch: string
  rlnIdentifier: string
  externalNullifier: string
  messageId: string
  userMessageLimit: string
  message: string
  messageHash: string
  merkleTreeRoot: string
  nullifier: string
  share: { x?: string; y: string }
  proof: unknown
}
```

For v3, map `y` to `share.y`. Define what v3 `scope` means in the app before storing it; usually it should correspond to the epoch/app-specific external-nullifier concept, not a Semaphore voting scope.

## Backend Flow

1. Derive or validate `epoch` server-side.
2. Derive or validate `externalNullifier` from `rlnIdentifier` and `epoch`.
3. Hash `message` with the selected implementation's expected hash function.
4. Reject unknown or stale `merkleTreeRoot`.
5. Verify the proof.
6. Insert the signal under `(appId, epoch, nullifier)`.
7. If insertion conflicts, load the first valid signal and store duplicate evidence.

Duplicate rejection is not slashing. Slashing needs valid duplicate evidence in the selected implementation's expected format and a tested enforcement path.

## Storage

```sql
create table rln_signals (
  id text primary key,
  app_id text not null,
  epoch text not null,
  rln_identifier text not null,
  external_nullifier text not null,
  message_id text not null,
  user_message_limit text not null,
  message_hash text not null,
  merkle_tree_root text not null,
  nullifier text not null,
  share_y text not null,
  proof_json jsonb not null,
  created_at timestamptz not null default now(),
  unique (app_id, epoch, nullifier)
);

create table rln_duplicate_evidence (
  id text primary key,
  app_id text not null,
  epoch text not null,
  nullifier text not null,
  first_signal_id text not null,
  second_signal_json jsonb not null,
  created_at timestamptz not null default now()
);
```

Store both messages or message hashes, both shares, proof references, root, epoch, and verifier version for duplicate evidence. Do not store live user secrets.

## Route Notes

Audited route:

- use when the user asks for stable/audited RLN or does not mention v3;
- pin the implementation repo, circuit artifacts, verifier artifacts, hash functions, and contract path;
- expect one-message-per-epoch unless the selected implementation supports more.

V3 route:

- use only when the user asks for `rln-v3`, Semaphore V4, LeanIMT, EdDSA, Circom, Noir, Node, or browser benchmarks;
- inspect `browser/proof/generate-proof.ts`, `verify-proof.ts`, `hash.ts`, and `types.ts`;
- treat repo code as reference/benchmark material, not a polished app SDK.

## Audited Circom RLN Proof Path

For the audited route, prefer a Dockerized local proof path instead of host-global Circom/snarkjs installs:

1. Pin and vendor or otherwise lock the audited `Rate-Limiting-Nullifier/circom-rln` source commit.
2. Build Circom and `snarkjs` in a container.
3. Compile the upstream `rln.circom` circuit without editing it unless the user asked for protocol work.
4. Generate local eval proving artifacts for development, then export the verification key.
5. In the app, generate the witness/proof for registered users and verify with `snarkjs.groth16.verify` before accepting a signal.
6. Store duplicate evidence from the verified public outputs, including both conflicting messages or hashes, both shares, root, epoch, verifier version, and proof references.

Local ptau/zkey artifacts are acceptable for development and evaluation, but do not present them as production trusted setup material. Production work needs a provenance story for circuit source, ptau, zkey, verification key, and verifier contract or backend verifier.

## Behavioral Test Matrix

- registered member proof is accepted;
- first valid signal in an epoch is accepted;
- second valid signal with the same `(appId, epoch, nullifier)` is rejected or recorded as duplicate evidence;
- same registered user in a new epoch is accepted when proof is valid for that epoch;
- two registered users in the same epoch are both accepted when their valid public outputs do not collide;
- unregistered or non-member user is rejected;
- tampered proof is rejected;
- tampered message, message hash, epoch, external nullifier, or root is rejected;
- unknown or stale root is rejected or handled according to an explicitly documented root-sync policy;
- mock verifier path, if present, cannot be the final acceptance path.

## Security Checks

- never log `identitySecret`, `a0`, wallet-signature seeds, or recovered live secrets;
- use a unique `rlnIdentifier` per app/deployment;
- do not accept client-provided epochs blindly;
- do not hash messages with ad hoc string concatenation;
- do not mix Semaphore `scope` vocabulary into RLN code without an explicit mapping;
- do not claim v3 audit coverage beyond what upstream states.
