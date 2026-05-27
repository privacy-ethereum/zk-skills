# Audited RLN Guidance

Use this note when the user asks for the original, stable, or audited RLN implementation, or when the task is a general RLN app and no v3-specific features are requested.

## Positioning

This route covers the established Circom-based RLN flow for anonymous rate-limited applications: registration, signaling, verification, duplicate detection, and enforcement. It is the right file for practical app-building tasks where the user wants audited RLN behavior and does not need the Semaphore V4-based v3 design.

## Implementation Choices

Start from the official RLN docs and Circom artifacts for the version the app uses. Keep the proof payload, hashing, and verifier format aligned with those artifacts.

For app work:

- define the membership tree and registration flow first;
- define the epoch and message limit before touching proof code;
- keep the proof payload field names consistent across client, server, and contract code;
- store duplicate-detection data with a unique constraint where possible;
- avoid custom circuit changes unless the user explicitly asks for protocol work.

## App Design Checklist

Before writing code, record:

- anonymous action being rate-limited;
- desired rate limit per epoch;
- epoch definition and clock/block source;
- group membership source and who can register;
- whether users stake anything and what slashing means;
- exact public proof payload accepted by the verifier;
- message hash function and serialization;
- duplicate detection key, usually nullifier plus epoch/rate slot context;
- behavior for valid first message, duplicate message, invalid proof, stale epoch, and unknown root;
- storage needed for roots, members, nullifiers, shares, and slashing evidence;
- privacy limits from metadata such as IPs, timestamps, relays, or small group size.

## Common App Patterns

### Anonymous Chat Or Posting

Use one RLN group per community, room, or relay network. Define an epoch such as one minute, one hour, or one block range. Each post includes the message hash, epoch, proof, nullifier, and share values required by the chosen RLN verifier.

Verifier behavior:

- reject proofs for unknown or stale roots;
- reject epochs outside an accepted clock skew;
- reject invalid message hashing or serialization;
- accept the first valid message for a nullifier/rate slot;
- treat a second valid message for the same slot as spam evidence.

### Anonymous API Access

Use RLN when users need anonymous access to a resource with a fair-use cap. The API gateway verifies proofs and stores nullifiers per epoch. If slashing is not implemented, the app can still block repeated nullifiers, but be clear that this is rate limiting without economic punishment.

### Staked Membership And Slashing

Use a contract or registry where users submit commitments and stake. If duplicate shares reveal the user's secret or enough slashing evidence, implement removal/slashing with official or audited contracts where available. Do not build a production slashing contract from memory.

## Practical Build Steps

1. Add identity or secret generation.
2. Register the user's commitment in the group.
3. Build the message hashing function.
4. Generate the RLN proof for `message`, `epoch`, and app identifier.
5. Verify the proof in the backend or contract.
6. Store the nullifier/share data needed to detect duplicate use.
7. Add the enforcement path: reject, block, remove, slash, or flag.
8. Test valid first use, duplicate use, wrong epoch, wrong message hash, and non-member proofs.

## Verification

For an audited RLN integration, add tests for:

- registration commitment generation;
- valid proof for a registered member;
- rejection for non-members and stale roots;
- first message accepted in an epoch;
- duplicate message or repeated slot detected;
- different epoch accepted as a fresh rate window;
- invalid message hash rejected;
- slashing or blocking path triggered only with valid duplicate evidence.

For security-sensitive work, also run dependency audits, inspect circuit/contract provenance, and verify that proof artifacts match the circuit and verifier used by the app.

## Output Expectations

When using this route, include the implementation source, package versions or commits, proof format, verifier location, tests run, and any audit assumptions that matter for the app.
