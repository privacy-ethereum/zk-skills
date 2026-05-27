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

## Implementation Guidance

For an app:

1. Decide whether the app needs Node, browser, Circom, or Noir.
2. Pin the `rln-v3` commit being used.
3. Record the exact circuit backend and proof artifacts.
4. Use Semaphore V4-style identity and group assumptions: EdDSA identities and LeanIMT groups.
5. Keep the verifier payload shape close to the repository examples.
6. Note that the v3 circuits have not been separately audited when security posture matters.

For Noir work:

- locate the Noir circuit implementation in the repository before writing integration code;
- keep Noir package/toolchain versions pinned;
- generate proof and verifier artifacts from the same circuit revision;
- test against known valid and invalid witnesses;
- avoid mixing Circom artifact assumptions into Noir verification code.

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
