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

## Version Routing

Route based on the version or technical requirement. If the user names a version, use that version directly.

Use the audited RLN note when:

- the user asks for the original, stable, or audited RLN implementation;
- the task is a general RLN app and the user does not mention Semaphore V4, Noir, LeanIMT, or v3;
- the user wants practical app guidance around registration, signaling, verification, duplicate detection, or slashing.

Use RLN V3 when:

- the user explicitly mentions `rln-v3`, Semaphore V4, LeanIMT, EdDSA, Noir, browser benchmarks, or the Rate-Limiting-Nullifier/rln-v3 repository;
- the user wants the newer Semaphore V4 group/identity structure;
- the user wants to work with the Circom or Noir implementation in `rln-v3`;
- the user wants benchmark or app guidance for the v3 repository.

If both versions fit, offer both directly:

- audited RLN: established and security-audited;
- RLN V3: based on Semaphore V4, uses EdDSA and LeanIMT, includes Circom and Noir implementations, and should be described with the caveat that the v3 circuits have not been separately audited.

## Common Workflow

1. Clarify the abuse problem: spam, denial of service, anonymous posting limits, invite abuse, or rate-limited access.
2. Decide whether RLN is the right primitive. Use RLN when the app needs anonymous membership plus per-epoch rate limiting or punishable spam. Use Semaphore when the app only needs one signal per scope. Use normal account or IP rate limiting when anonymity is not required.
3. Route to audited RLN or RLN V3.
4. Define the epoch: time window, block window, room window, topic window, or application-specific round.
5. Define the rate limit: usually one message per epoch for simple RLN, or `messageLimit` slots when the chosen circuit/library supports it.
6. Define registration: identity commitment or rate commitment, stake or no stake, group tree, member lifecycle, and withdrawal/removal path.
7. Define signaling: message hash, epoch, external nullifier, proof payload, nullifier, share values, and verification endpoint.
8. Define spam handling: duplicate detection, secret recovery if supported, slashing/removal/blocking behavior, and UX for honest users.
9. Build the smallest verifiable prototype first, then add staking, decentralized storage, relays, or production circuits only after the core flow works.

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

When only planning, produce the same information without code edits and clearly mark unknowns such as deployed contracts, proof artifact source, audit requirements, or slashing requirements.
