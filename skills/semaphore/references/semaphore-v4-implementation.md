# Semaphore V4 Implementation Card

Use this card when an agent needs to build a small Semaphore V4 app, especially an off-chain verifier for anonymous voting, feedback, claims, or posting.

## Verified Baseline

Checked against `semaphore-protocol/semaphore` and npm on 2026-06-02, and re-confirmed in a local Semaphore eval on 2026-06-09:

- current npm packages seen: `@semaphore-protocol/core`, `@semaphore-protocol/proof`, and `@semaphore-protocol/contracts` at `4.14.2`;
- `@semaphore-protocol/core` re-exports `Identity`, `Group`, `generateProof`, and `verifyProof`;
- `generateProof(identity, groupOrMerkleProof, message, scope, merkleTreeDepth?, snarkArtifacts?)` returns a `SemaphoreProof`;
- `verifyProof(proof)` returns `Promise<boolean>`;
- the proof shape is `merkleTreeDepth`, `merkleTreeRoot`, `message`, `nullifier`, `scope`, `points`;
- the Solidity interface uses `ISemaphore.SemaphoreProof` with the same fields and `validateProof(groupId, proof)`.
- npm `4.14.2` publishes Solidity files at package-root paths such as `@semaphore-protocol/contracts/Semaphore.sol`, `@semaphore-protocol/contracts/base/SemaphoreVerifier.sol`, and `@semaphore-protocol/contracts/interfaces/ISemaphore.sol`.

Re-check package versions and TypeDoc before pinning production code.

## Install

For app prototypes:

```bash
npm install @semaphore-protocol/core
```

For split imports:

```bash
npm install @semaphore-protocol/identity @semaphore-protocol/group @semaphore-protocol/proof
```

For Solidity validation:

```bash
npm install @semaphore-protocol/contracts
```

## Client Proof Path

```typescript
import { Identity, Group, generateProof } from "@semaphore-protocol/core"

const identity = Identity.import(exportedIdentity)
const group = new Group(identityCommitments)
const message = voteChoiceOrHash
const scope = ballotId

const proof = await generateProof(identity, group, message, scope)
```

Keep `scope` stable and app-specific. For a ballot, use the ballot or proposal id. For a room or event, use that room or event id. The same identity can only produce one accepted signal for a given scope if the verifier stores used nullifiers.

## Proof Payload

Accept this JSON from the client:

```typescript
type SemaphoreActionPayload = {
  groupId: string
  scope: string
  message: string
  proof: {
    merkleTreeDepth: number
    merkleTreeRoot: string
    nullifier: string
    message: string
    scope: string
    points: unknown[]
  }
}
```

Treat `payload.message` and `payload.scope` as the app-level values. Treat `proof.message` and `proof.scope` as the canonical converted values returned by the Semaphore library. Do not rename `nullifier` to `nullifierHash` in V4 code unless an older dependency requires it.

Do not compare raw text such as `"ballot-1"` directly to `proof.scope` unless the app already sends canonical numeric strings. Use one shared encoder for client and server.

## Backend Verifier Route

```typescript
import { verifyProof } from "@semaphore-protocol/core"
import { encodeBytes32String, toBigInt } from "ethers"

const encodeSemaphoreValue = (value: string): string => {
  // Match Semaphore's text-to-field behavior for short strings.
  try {
    return toBigInt(value).toString()
  } catch {
    return toBigInt(encodeBytes32String(value)).toString()
  }
}

app.post("/api/semaphore/actions", async (req, res) => {
  const { groupId, scope, message, proof } = req.body

  const expectedScope = await getExpectedScope(groupId)
  if (String(scope) !== String(expectedScope)) {
    return res.status(400).json({ error: "wrong_scope" })
  }

  const expectedProofScope = encodeSemaphoreValue(String(scope))
  const expectedProofMessage = encodeSemaphoreValue(String(message))

  if (String(proof.scope) !== expectedProofScope) {
    return res.status(400).json({ error: "proof_scope_mismatch" })
  }

  if (String(proof.message) !== expectedProofMessage) {
    return res.status(400).json({ error: "proof_message_mismatch" })
  }

  const trustedRoot = await isTrustedRoot(groupId, proof.merkleTreeRoot)
  if (!trustedRoot) {
    return res.status(400).json({ error: "unknown_or_stale_root" })
  }

  const valid = await verifyProof(proof)
  if (!valid) {
    return res.status(400).json({ error: "invalid_proof" })
  }

  try {
    await db.$transaction(async (tx) => {
      await tx.usedNullifier.create({
        data: {
          primitive: "semaphore",
          groupId,
          scope: String(scope),
          nullifier: String(proof.nullifier),
          merkleTreeRoot: String(proof.merkleTreeRoot),
          message: String(message)
        }
      })

      await tx.acceptedAction.create({
        data: { groupId, scope: String(scope), message: String(message) }
      })
    })
  } catch {
    return res.status(409).json({ error: "duplicate_nullifier" })
  }

  res.json({ ok: true })
})
```

The nullifier insert and action side effect must be in one transaction or protected by a unique constraint. Otherwise two concurrent submissions can both pass the duplicate check.

## Prisma And SQL

```prisma
model UsedNullifier {
  id             String   @id @default(cuid())
  primitive      String
  groupId        String
  scope          String
  nullifier      String
  merkleTreeRoot String
  message        String
  createdAt      DateTime @default(now())

  @@unique([primitive, groupId, scope, nullifier])
  @@index([groupId, scope])
}
```

```sql
create table used_nullifiers (
  id text primary key,
  primitive text not null,
  group_id text not null,
  scope text not null,
  nullifier text not null,
  merkle_tree_root text not null,
  message text not null,
  created_at timestamptz not null default now(),
  unique (primitive, group_id, scope, nullifier)
);
```

## Required Tests

- valid member proof is accepted once;
- same proof or same identity/scope is rejected as `duplicate_nullifier`;
- proof for a different scope is rejected before side effects;
- proof for a tampered message is rejected before side effects;
- proof for an unknown or stale root is rejected;
- non-member or untrusted-root proof is rejected;
- two concurrent duplicate submissions only create one accepted action.

For a practical non-member negative test, do not expect Semaphore to generate a proof for an identity that is missing from the same group. Instead, generate a valid proof against an alternate group/root and assert the verifier or contract rejects that root as untrusted or not part of the registered group.

## Security Checks

- Never log, commit, or transmit `Identity.export()` values, wallet signature challenges used to derive identities, or private keys.
- Do not store production identity exports in plaintext local storage.
- Do not call a group of one or two users anonymous.
- Do not reuse the same identity derivation challenge across unrelated applications.
- Do not treat identity commitments as private identifiers; they are public but linkable if reused.
- Check that timing, wallet address, IP address, transaction metadata, and content do not deanonymize the action.

## Troubleshooting Checks

- Valid-looking proof rejected: compare public `proof.message`, `proof.scope`, expected message, and expected scope.
- Duplicate accepted: check the unique constraint on `(primitive, groupId, scope, nullifier)`.
- Stale root rejected: compare `proof.merkleTreeRoot` with the trusted current and recently accepted roots.
- Browser proof slow: check artifact loading, cold-cache behavior, and proof-generation UX.
- Contract reverts after off-chain verification succeeds: check `groupId`, root duration, duplicate nullifier, and exact `ISemaphore.SemaphoreProof` field order.

## Browser Artifacts

The proof package can fetch SNARK artifacts automatically through `@zk-kit/artifacts`, but browser apps should still plan for artifact loading:

- show progress and handle proof generation latency;
- make wasm/zkey access explicit if the app needs offline, pinned, or self-hosted artifacts;
- pass `{ wasm, zkey }` to `generateProof` when artifact provenance matters;
- check bundler behavior in the actual framework before promising that automatic artifact downloads work in production.

## Minimal On-Chain Notes

For contract work, use `@semaphore-protocol/contracts/interfaces/ISemaphore.sol`. The V4 proof struct is:

```solidity
struct SemaphoreProof {
    uint256 merkleTreeDepth;
    uint256 merkleTreeRoot;
    uint256 nullifier;
    uint256 message;
    uint256 scope;
    uint256[8] points;
}
```

Call `semaphore.validateProof(groupId, proof)` for state-changing validation. The Semaphore contract stores nullifiers for the group and reverts on duplicates. Keep group creation, member management, and root duration behavior explicit in tests.

For a small local Solidity harness:

- import `@semaphore-protocol/contracts/Semaphore.sol`, `@semaphore-protocol/contracts/base/SemaphoreVerifier.sol`, and `@semaphore-protocol/contracts/interfaces/ISemaphore.sol`;
- add a local import wrapper such as `OfficialSemaphoreImports.sol` if the chosen Solidity toolchain does not emit deployable artifacts for package contracts;
- deploy `PoseidonT3` from `poseidon-solidity/PoseidonT3.sol` and link it into `Semaphore`;
- deploy the official `SemaphoreVerifier`, then the official `Semaphore`;
- write the app contract so it checks `proof.message` and `proof.scope`, calls `semaphore.validateProof(groupId, proof)`, and only then changes app state;
- register only identity commitments on-chain, never identity secrets;
- test a duplicate signal by reusing the same identity and scope, and test a second valid signal with a different registered identity.

If host native Solidity tooling fails before compilation, a Docker Node LTS workflow is an acceptable eval path. Keep Docker as reproducibility guidance, not as a requirement for every Semaphore app.
