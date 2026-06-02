---
name: semaphore
description: Build, adapt, and debug Semaphore V4 applications. Use when a user wants anonymous voting, anonymous feedback, group membership proofs, nullifier-based double-spend prevention, off-chain Semaphore proof generation, on-chain Semaphore group management, or integration with Semaphore identities, groups, proofs, contracts, or subgraphs.
---

# Semaphore

## Overview

Use this skill to help an agent turn a product goal such as "let verified members vote anonymously" or "let conference attendees submit one private feedback message" into a working Semaphore integration.

Semaphore is useful when an app needs a user to prove group membership and send a message without revealing which group member sent it. The practical building blocks are:

- identities: private keys, public keys, and public identity commitments;
- groups: Merkle trees containing identity commitments;
- proofs: zero-knowledge proofs over membership, a message, and a scope;
- nullifiers: public values used to reject duplicate signals for the same scope.

Current app-building should target Semaphore V4 unless the existing codebase already uses an older version.

## Workflow

1. Clarify the action the user wants to protect: vote, post, endorse, claim, join, or submit feedback.
2. Decide whether Semaphore is appropriate: the app needs anonymous group membership, not private arbitrary computation or private credentials by itself.
3. Define the group source: off-chain list, on-chain group, allowlist, token ownership snapshot, credential proof, or admin-managed registry.
4. Define the scope: ballot id, proposal id, room id, campaign id, epoch, or another value that determines where one identity may only signal once.
5. Define the message: the vote choice, feedback hash, post hash, endorsement target, claim data, or another public value.
6. Choose the integration path: off-chain proof verification for prototypes, on-chain validation for contracts, or a hybrid app with off-chain proof generation and on-chain validation.
7. Implement identity creation or recovery, group loading, proof generation, proof submission, verification, and duplicate-nullifier handling.
8. Test with multiple identities, duplicate submissions, stale groups, invalid proofs, and small anonymity sets.

## Recommended References

- Semaphore docs: https://docs.semaphore.pse.dev/
- JavaScript SDK TypeDoc: https://js.semaphore.pse.dev/
- GitHub repository: https://github.com/semaphore-protocol/semaphore
- Deployed contracts: https://docs.semaphore.pse.dev/deployed-contracts
- CLI templates: `npx @semaphore-protocol/cli create my-app --template monorepo-ethers`
- Implementation card: `references/semaphore-v4-implementation.md`

## Implementation Choices

For one-shot app work, read `references/semaphore-v4-implementation.md` before writing code. It contains the verified V4 proof shape, off-chain verifier route, database constraints for used nullifiers, browser artifact notes, and required tests.

Prefer `@semaphore-protocol/core` for new JavaScript or TypeScript app code when the app needs identity, group, and proof utilities together. Use the narrower packages when the codebase already imports them:

- `@semaphore-protocol/identity` for `Identity`;
- `@semaphore-protocol/group` for `Group`;
- `@semaphore-protocol/proof` for `generateProof` and `verifyProof`;
- `@semaphore-protocol/contracts` for Solidity interfaces and on-chain validation;
- `@semaphore-protocol/data` for loading on-chain group data from supported networks.

For a fast prototype, build off-chain first:

```typescript
import { Identity } from "@semaphore-protocol/identity"
import { Group } from "@semaphore-protocol/group"
import { generateProof, verifyProof } from "@semaphore-protocol/proof"

const identity = new Identity()
const group = new Group([identity.commitment])
const message = 1
const scope = group.root

const proof = await generateProof(identity, group, message, scope)
const valid = await verifyProof(proof)
```

For an on-chain app, keep proof generation in the client or backend and validate with the Semaphore contract. Use `Semaphore.sol` or `ISemaphore.sol` from `@semaphore-protocol/contracts`; do not write a custom verifier unless the app has a specific reason and tests.

## App Design Checklist

Before writing code, record:

- user action and threat model;
- group id or group construction rule;
- who may add, update, or remove group members;
- identity recovery strategy;
- scope value and why it prevents only the intended duplicate action;
- message encoding and whether large data should be hashed before proof generation;
- proof generation location: browser, mobile app, backend, or test script;
- verification location: backend, smart contract, or both;
- nullifier storage and duplicate rejection path;
- expected group size and anonymity set risks.

Use unique identity derivation prompts per application. If deriving identities from wallet signatures, use an app-specific message and warn against reusing the same signed message across apps because it can link identities.

Avoid groups with 1 or 2 members for real privacy. They can be useful in tests but should not be described as anonymous.

## Common App Patterns

### Anonymous Voting

Use a group for eligible voters. Use the ballot or proposal id as the scope. Use the vote choice or a hash of a structured ballot as the message. Store used nullifiers and reject duplicates.

Test:

- valid member can vote once;
- same identity cannot vote twice for the same scope;
- same identity can vote in a different scope if allowed;
- non-member proof fails;
- proof with tampered message fails.

### Anonymous Feedback

Use a group for eligible feedback authors. Use the event id, class id, or room id as the scope. Use a feedback hash as the message if the raw feedback should stay off-chain or be stored elsewhere.

Test duplicate nullifier rejection and moderation requirements. Semaphore proves group membership; it does not make abusive content safe.

### Anonymous Posting Or Signaling

Use a scope that represents a topic, epoch, channel, or campaign. If the app allows more than one message per period, plain Semaphore may be too restrictive; consider multiple scopes or RLN for privacy-preserving rate limits.

## Backend And Contract Guidance

For off-chain verification:

- verify the proof with `verifyProof`;
- check the proof's group root is trusted for the relevant group;
- check the scope is exactly the expected scope;
- check the message matches the submitted action;
- persist the nullifier before accepting side effects, or use a transaction/unique constraint to avoid races.

For on-chain verification:

- use the official Semaphore interface and deployed contract where practical;
- create or reference a group id;
- add members with identity commitments only, never private keys;
- call `validateProof(groupId, proof)` for submitted proofs;
- store accepted nullifiers or rely on the Semaphore contract behavior required by the chosen flow.

When loading on-chain groups off-chain, reconstruct the group from trusted subgraph or contract data and handle stale roots. Semaphore contracts may allow old roots for a configured duration; make that duration explicit in app behavior.

## Security And Privacy Rules

- Never log, commit, or transmit a Semaphore private key unless the user explicitly asked to export it.
- Never store identity private keys in plaintext local storage for a production app.
- Do not call a public identity commitment a private identifier; it is safe to share but linkable wherever reused.
- Do not use the same wallet-signature challenge across different apps.
- Do not accept a proof just because it verifies cryptographically; also check group, scope, message, root freshness, and nullifier uniqueness.
- Do not promise anonymity when the group is tiny, the group list is uniquely identifying, or the action metadata deanonymizes the user.

## Verification

For application code, run the repository's normal typecheck and test commands. Add focused tests for:

- identity creation/import;
- group membership and Merkle proof generation;
- proof generation and verification;
- duplicate nullifier rejection;
- invalid group, invalid scope, and invalid message;
- on-chain validation if contracts are touched.

For contract code, run unit tests against both valid and invalid proofs when fixtures are available. If proof generation is slow in CI, keep at least one integration test and use deterministic fixtures for faster unit tests.

Before finishing, run the security, duplicate-nullifier, root-freshness, and browser-artifact checks in `references/semaphore-v4-implementation.md`.

## Output Expectations

When building an app integration, produce:

- the group and membership model;
- identity creation or recovery strategy;
- scope and message definitions;
- proof generation and verification code path;
- nullifier duplicate handling;
- commands used for build and tests;
- known privacy limitations and remaining setup steps.

When only planning, produce the same information without code edits and clearly mark unknowns such as group source, network, deployed contract address, or identity recovery requirements.
