---
name: rln
description: Route, build, adapt, and debug Rate-Limiting Nullifier (RLN) applications. Use when a user wants privacy-preserving rate limits, anonymous chat or posting with spam deterrence, nullifier-based abuse detection, RLN registration/signaling/slashing flows, RLN V3 with Semaphore V4 or Noir, or guidance on choosing an RLN version.
---

# RLN

## Overview

Use this skill to help an agent turn a product goal such as "anonymous users can post once per epoch" or "detect and penalize anonymous spam without identifying honest users" into a practical RLN design or prototype.

RLN is a privacy-preserving rate-limiting pattern for anonymous systems. A user registers a commitment in a Merkle tree, sends messages with zero-knowledge proofs, and exposes public values that make repeated use of the same rate slot detectable. Depending on the deployment, exceeding the rate limit can reveal enough information to slash a stake, remove a user, or block future messages.

This file is the routing layer. Pick the relevant version note before giving code-level guidance:

- `references/rln-audited.md`: audited RLN guidance for the established Circom implementation.
- `references/rln-v3.md`: RLN V3 guidance for the Semaphore V4-based implementation with LeanIMT, EdDSA, Circom, and Noir paths.
- `references/rln-implementation.md`: compact implementation card with payload shape, duplicate detection, audited/v3 notes, and tests.

## Version Routing

Route based on the version or technical requirement. If the user names a version, use that version directly.

Use the audited RLN note when:

- the user asks for the original, stable, or audited RLN implementation;
- the task is a general RLN app and the user does not mention Semaphore V4, Noir, LeanIMT, or v3;
- the user wants practical app guidance around registration, signaling, verification, duplicate detection, or slashing.

For code-level planning on this route, also read `references/rln-implementation.md`.

Use RLN V3 when:

- the user explicitly mentions `rln-v3`, Semaphore V4, LeanIMT, EdDSA, Noir, browser benchmarks, or the Rate-Limiting-Nullifier/rln-v3 repository;
- the user wants the newer Semaphore V4 group/identity structure;
- the user wants to work with the Circom or Noir implementation in `rln-v3`;
- the user wants benchmark or app guidance for the v3 repository.

For code-level planning on this route, also read `references/rln-implementation.md`.

If both versions fit, offer both directly:

- audited RLN: established and security-audited;
- RLN V3: based on Semaphore V4, uses EdDSA and LeanIMT, includes Circom and Noir implementations, and should be described with the caveat that the v3 circuits have not been separately audited.

## Common Workflow

1. Clarify the abuse problem: spam, denial of service, anonymous posting limits, invite abuse, or rate-limited access.
2. Decide whether RLN is the right primitive. Use RLN when the app needs anonymous membership plus per-epoch rate limiting or punishable spam. Use Semaphore when the app only needs one signal per scope. Use normal account or IP rate limiting when anonymity is not required.
3. Route to audited RLN or RLN V3.
4. Read `references/rln-implementation.md` and use its field names at the app boundary.
5. Define the epoch: time window, block window, room window, topic window, or application-specific round.
6. Define the rate limit: usually one message per epoch for simple RLN, or `messageLimit` slots when the chosen circuit/library supports it.
7. Define registration: identity commitment or rate commitment, stake or no stake, group tree, member lifecycle, and withdrawal/removal path.
8. Define signaling: message hash, epoch, external nullifier, proof payload, nullifier, share values, and verification endpoint.
9. Define spam handling with `references/rln-implementation.md`: duplicate evidence, secret recovery if supported, slashing/removal/blocking behavior, and UX for honest users.
10. Build the smallest verifiable prototype first, then add staking, decentralized storage, relays, or production circuits only after the core flow works.

## Working RLN App Definition

An implementation is not a working RLN app merely because it has an anonymous-looking UI, server counters, or mock verification. To call the result working, the app must have:

- a real registration or an explicit registration model that derives public commitments from private user secrets;
- group or Merkle membership state and root handling;
- epoch-bound signal generation with an app-specific identifier or external nullifier;
- real proof generation against the selected audited or v3 circuit/artifact path;
- real proof verification before accepting a signal;
- nullifier/share handling from verified public outputs;
- duplicate detection and evidence storage from RLN public outputs, not from user IDs or client claims;
- behavioral tests for valid, duplicate, next-epoch, multi-user, non-member or invalid-proof, wrong-message or wrong-epoch, and stale-root cases.

If a mock verifier, server-side counter, hardcoded proof, client-claimed nullifier, or fixture-only proof path remains, mark the implementation as incomplete. Mocks are acceptable only as temporary scaffolding while building the product shell or storage model.

## Shared App Model

A practical RLN app has three phases:

- registration: create or receive a user's secret, derive a public commitment, and add that commitment to a group tree;
- signaling: generate a proof that the sender is in the group and that the public RLN values were computed correctly for the message and epoch;
- punishment or rejection: detect overuse of a rate slot, then slash, remove, block, or flag the sender depending on the system.

Core values to keep straight:

- `identitySecret` or `a0`: private user secret; never reveal for honest users;
- `identityCommitment`: public registration value derived from the private secret;
- `epoch`: rate-limit time window;
- `rlnIdentifier`: application-specific random field value;
- `externalNullifier`: usually derived from epoch and app identifier so use in one RLN app or epoch cannot be linked to another;
- `messageId`: slot index for circuits that support more than one message per epoch;
- `message`: content or content hash being sent;
- `share`: public point tied to the message and the user's hidden polynomial;
- `nullifier`: public value that lets verifiers associate duplicate use of the same rate slot without identifying honest users.

Do not casually rename these values in code. RLN bugs often come from mixing up Semaphore-style nullifiers, app scopes, epochs, and RLN shares.

## Product-Agnostic Lifecycle Checklist

Every RLN app should make these components explicit, even if the product UX is domain-specific:

- identity manager: creates, stores, imports, or receives private user secrets without logging live secrets;
- commitment derivation: derives the public registration value with the selected implementation's expected hash/field format;
- registration and group state: inserts commitments, tracks roots, and defines membership lifecycle;
- epoch manager: derives the current rate-limit window server-side or validates it against a trusted source;
- proof generator: creates proofs from message, epoch, membership path, and private secret;
- verifier: rejects invalid proofs, stale roots, wrong message hashes, and wrong epochs before storage;
- signal store: stores accepted verified signals and public outputs;
- duplicate evidence store: stores both valid conflicting signals and proof metadata needed for later enforcement;
- abuse response: defines reject, block, remove, slash, or flag behavior without confusing rejection with slashing.

The UI does not need a prescribed design, but the app should expose or make clear registration status, current epoch/rate-limit window, proof generation and verification state, duplicate rejection reason, and group/root sync state or rationale.

## Recommended References

- PSE project page: https://pse.dev/projects/rln
- RLN docs: https://rate-limiting-nullifier.github.io/rln-docs/
- RLN GitHub organization: https://github.com/Rate-Limiting-Nullifier
- Original overview article: https://pse.dev/en/blog/rate-limiting-nullifier-rln
- RLN V3 repository: https://github.com/Rate-Limiting-Nullifier/rln-v3

## When Not To Use RLN

- The app does not need anonymity. Use ordinary authenticated rate limiting.
- The app only needs one anonymous action per poll or proposal. Use Semaphore.
- The app needs private credentials, age proofs, passport checks, or email ownership. Combine another identity proof system with Semaphore or RLN.
- The app's abuse response cannot use slashing, removal, blocking, or another concrete penalty.

## Shared Security Rules

- Never log or commit `identitySecret`, `a0`, seed phrases, wallet signatures used as secrets, or recovered secrets from live users.
- Do not reuse an RLN app identifier across unrelated apps.
- Do not accept client-provided epochs blindly; derive or validate them server-side.
- Do not hash messages with ad hoc string concatenation. Use explicit serialization and the hash function expected by the chosen library/circuit.
- Do not treat duplicate rejection as slashing. Slashing requires enough valid evidence and a correct contract or enforcement path.
- Do not promise privacy if the anonymity set is tiny, transport metadata is exposed, or the app stores unique timing and device fingerprints.
- Pin dependency versions or commits.

## Output Expectations

When building an RLN integration, produce:

- the selected route: audited RLN or RLN V3;
- why that route fits the task;
- registration and group membership model;
- epoch, rate limit, and app identifier;
- proof payload format and verification path;
- nullifier/share storage and duplicate detection logic;
- punishment, slashing, removal, or blocking behavior;
- commands used for build and tests;
- audit status and privacy limitations.
- whether the final implementation uses real proof verification or remains incomplete because mocks/scaffolding are still present.

When only planning, produce the same information without code edits and clearly mark unknowns such as deployed contracts, proof artifact source, audit requirements, or slashing requirements.

Before finishing implementation work, run the security, payload, duplicate, root, and epoch checks in `references/rln-implementation.md`.
