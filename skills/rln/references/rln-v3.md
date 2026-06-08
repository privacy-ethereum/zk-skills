# RLN V3 Guidance

Use this note when the user asks for RLN V3, Semaphore V4-based RLN, LeanIMT, EdDSA identities, Noir circuits, or the `Rate-Limiting-Nullifier/rln-v3` repository.

## Positioning

RLN V3 is the Semaphore V4-based RLN implementation and is available in both Circom and Noir. The repository README describes:

- EdDSA for the identity schema;
- LeanIMT for groups;
- dynamic tree depth, where one circuit with a maximum depth can support smaller current tree depths;
- Circom and Noir code in the repository;
- Node and browser benchmark folders.

Mention the audit status precisely: the v3 circuits have not been separately audited. Do not turn that into a blanket dismissal of the repository. It is a serious RLN implementation and should be offered when Semaphore V4, LeanIMT, EdDSA, Circom, or Noir support is relevant.

Keep the default routing clear: if the user asks for RLN generally and does not request V3, Semaphore V4, LeanIMT, EdDSA, Circom V3, or Noir, use the audited RLN route instead. Use V3 when the user explicitly wants the V3 architecture or one of its technical paths.

## References

- RLN V3 repository: https://github.com/Rate-Limiting-Nullifier/rln-v3
- Semaphore V4 docs: https://docs.semaphore.pse.dev/
- Semaphore V4 release context: https://github.com/semaphore-protocol/semaphore/releases/tag/v4.0.0

## Route Here When

- the user mentions `rln-v3`;
- the user wants Semaphore V4 compatibility;
- the user wants LeanIMT or dynamic tree depth;
- the user wants EdDSA identity alignment with Semaphore V4;
- the user asks for Noir circuits;
- the task uses the `node`, `browser`, `circuits`, Circom, or Noir code paths in the v3 repository.

If the user asks for production deployment, mention the v3 circuit audit caveat and ask whether they want v3 specifically or the audited implementation.

## Repository Shape

The `rln-v3` repository currently has separate areas for:

- `circuits`: circuit work and related instructions;
- `node`: Node.js benchmarks;
- `browser`: browser benchmarks and a live benchmark app;
- root README: high-level overview and navigation.

Before editing or copying code, inspect the relevant folder README and package files. Do not assume the browser, Node, Circom, and Noir paths expose identical APIs.

Treat the repository as implementation and benchmark material, not as a polished one-package app SDK. Pin the commit. If the repo has no release for the path being used, say that directly and cite the commit or artifact source.

## Implementation Guidance

For an app:

1. Decide whether the app needs Node, browser, Circom, or Noir.
2. Pin the `rln-v3` commit being used.
3. Record the exact circuit backend and proof artifacts.
4. Use Semaphore V4-style identity and group assumptions: EdDSA identities and LeanIMT groups.
5. Keep the verifier payload shape close to the repository examples.
6. Note that the v3 circuits have not been separately audited when security posture matters.

App acceptance requires more than `verifyProof(proof)`. Verification proves consistency of the proof's public outputs, but the app must still check:

- `merkleTreeRoot` is one of the app's registered or accepted roots;
- `message` or message hash matches the submitted signal;
- `scope` matches the server-derived epoch-bound app scope;
- `messageId` is inside `userMessageLimit`;
- duplicate detection uses the verified `nullifier` in the app's `(appId, epoch, nullifier)` key.

For V3, treat `scope` as the app's epoch-bound external-nullifier concept. Derive it from app identifier, RLN identifier, and epoch; do not accept arbitrary client-provided scopes.

## Circom App Prototype Path

Use this as the main RLN V3 app-prototype route today when the user asks for V3 and does not specifically require Noir.

Practical pattern:

1. Use `Identity` and `Group` from `@semaphore-protocol/core`.
2. Derive `rateCommitment = Poseidon(identityCommitment, userMessageLimit)`.
3. Build the group over rate commitments, not plain identity commitments.
4. Generate the Merkle proof for the rate commitment index.
5. Call the V3 Circom helper shape with explicit artifacts:
   `generateProof(identity, merkleProof, message, scope, messageId, userMessageLimit, artifactDepth, artifacts)`.
6. Call `verifyProof(proof)`.
7. Apply app checks for root, message, scope/epoch, `messageId`, and duplicate nullifier before accepting the signal.

LeanIMT proof length and circuit artifact depth are separate. A smaller current tree may produce a shorter Merkle proof than the max-depth artifact. Keep both values explicit and pad missing siblings only according to the helper/circuit expectations.

Avoid magic artifact fallback in app code. Pass explicit V3 `.wasm`, `.zkey`, and verification-key sources, and describe whether they are upstream benchmark artifacts, locally generated eval artifacts, or production-provenance artifacts. Checked-in benchmark artifacts are acceptable for local eval; they are not production trusted setup provenance.

For Noir work:

- locate the Noir circuit implementation in the repository before writing integration code;
- keep Noir package/toolchain versions pinned;
- generate proof and verifier artifacts from the same circuit revision;
- test against known valid and invalid witnesses;
- avoid mixing Circom artifact assumptions into Noir verification code.

Use the Noir path when the user specifically asks for Noir or accepts Dockerized CLI proving. A tested local eval path used:

- `nargo 1.0.0-beta.3`;
- `bb 0.82.2`;
- pinned `Rate-Limiting-Nullifier/rln-v3` source commit;
- `nargo test`, `nargo compile`, `nargo execute`;
- `bb prove`, `bb write_vk`, and `bb verify`.

Warn that newer Noir tooling may not work with the current upstream dependencies. In local eval, `nargo 1.0.0-beta.10` failed against the upstream Noir path because of dependency/API drift. Until upstream updates, pin the known-compatible toolchain instead of assuming current Noir works.

No stable app-facing Noir JS helper comparable to the Circom browser proof helpers was found in the evaluated path. For app prototypes, a backend service can shell out to `nargo` and `bb` inside Docker, then apply app-level root/scope/message/nullifier policy after `bb verify`.

When testing invalid proofs with Barretenberg, assert nonzero failure rather than graceful error text only. A binary-corrupted proof may crash or exit nonzero instead of producing a clean invalid-proof response.

For browser work:

- check the `browser` folder and live benchmark app for expected APIs and performance assumptions;
- avoid blocking the main thread in a production UI without measuring proof generation time;
- show proof generation progress and handle cancellation or retries.

For Node benchmarks:

- use the `node` folder as a benchmark reference, not automatically as production server code;
- keep benchmark scripts separate from app verifier logic;
- record hardware and toolchain versions if comparing v3 against audited RLN.

## App Design Checklist

Before writing code, record:

- why RLN V3 is the chosen version;
- v3 circuit audit caveat if security posture matters;
- target path: Circom, Noir, Node benchmark, browser benchmark, or app prototype;
- pinned repository commit;
- Semaphore V4 identity and group handling;
- tree depth assumptions and maximum depth;
- epoch and rate-limit semantics;
- proof payload fields and serialization;
- verifier location and artifact source;
- fallback plan if v3 APIs or artifacts are incomplete for the app.

## Verification

For RLN V3, test:

- valid proof generation for a registered member;
- invalid proof rejection;
- wrong root rejection;
- wrong epoch or external nullifier rejection;
- wrong message or message hash rejection;
- `messageId >= userMessageLimit` rejection;
- duplicate/repeated rate-slot detection;
- circuit artifact and verifier compatibility;
- Noir-specific witness and verifier behavior if using Noir;
- browser performance if proof generation runs client-side.

Passing tests shows the integration behaves as expected for the tested cases. It does not change the separate audit status of the v3 circuits.

## Output Expectations

When using this route, produce:

- a clear statement that RLN V3 was selected;
- why v3 is appropriate for the task;
- audit caveat for v3 circuits when relevant;
- selected path: Circom, Noir, Node, browser, or app prototype;
- pinned commit or version source;
- Semaphore V4 identity/group assumptions;
- proof artifact and verifier path;
- tests run and remaining risks.
