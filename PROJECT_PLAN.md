# ZK Agent Skills

## Goal

The goal of this project is to make it easier for developers, builders, and AI agents to use privacy-focused projects developed by PSE / Ethereum Foundation.

Many of these projects are powerful, but they can take significant time to understand, set up, debug, and integrate. Their documentation can also be difficult to navigate, especially for people who are new to the ecosystem or do not want to go deep into protocol-level details.

This project will create AI-friendly skills for selected EF / PSE projects so that coding agents can help users move faster from an idea to a working prototype.

The skills should help AI systems perform better across the practical development workflow:

- understanding the user's task,
- finding the right project references,
- choosing the right tools, libraries, and examples,
- planning a clean implementation approach,
- setting up and integrating the project correctly,
- testing and debugging the result,
- identifying missing context or likely failure cases.

The broader goal is to lower the barrier to entry for privacy-preserving application development and help more people build practical products using PSE tools.

## Current Focus

The current phase is focused on project-specific skills for selected EF / PSE projects.

The active scope is based on the PSE project skills plan, rather than the earlier broader zkdev plan. The earlier plan remains useful as background and future direction, but standalone Circom, Noir, general zkdev workflows, zk security, zkVMs, FHE, MPC, and broad ecosystem coverage are not the main deliverables of this phase.

## User Persona

The target users are developers, builders, and technically curious non-engineers who are interested in privacy, zk systems, cryptography, and related applications, but do not necessarily have deep knowledge of each specific protocol.

One example is a builder who wants to create an application that uses TLSNotary to generate attestations from a bank account. They understand the high-level concept and the product they want to build, but they want to rely on AI agents or coding assistants to handle the setup, integration, and protocol-specific details.

Another example is an experienced engineer who is already comfortable with development, but does not want to spend unnecessary time dealing with environment setup, documentation gaps, edge cases, or protocol-specific bugs. They want to outsource as much of that work as possible to AI, so they can focus on product logic and user experience.

In general, these users want to move faster from idea to working prototype. They are not trying to become experts in every PSE protocol; they want reliable AI assistance that helps them build with these tools correctly and efficiently.

## Team

The project is a joint effort between PSE and the Builder Growth team at EF:

- Rasul / PSE
- Rahul / EF DevTooling & Builder Growth
- Philip / Builder Growth

## Active Scope

The selected projects do not represent the final full list of projects. They are the initial set to start with and use to evaluate progress.

Initial project list:

- [ ] [Semaphore](https://semaphore.pse.dev/)
- [ ] [TLSNotary](https://tlsnotary.org/)
- [ ] [ZK Email](https://zk.email/)
- [ ] [ZK JWT](https://github.com/zkemail/noir-jwt)
- [ ] [zkPassport](https://github.com/zkpassport)
- [ ] [vOPRF-ID](https://pse.dev/projects/voprf)
- [ ] [RLN](https://pse.dev/projects/rln)

Each skill file should be evaluated and tested on real-world application tasks manually, with optional auto-research where useful.

## Timeline and Deliverables

### 29.05.2026

Focus:

- TLSNotary skill
- RLN skill
- Semaphore skill

Ownership:

- Rasul / PSE

Deliverables:

- first usable skill files for TLSNotary, RLN, and Semaphore,
- initial real-world test prompts and app examples for each project,
- notes on setup, integration issues, missing documentation, and common AI failure modes.

### 07.06.2026

Focus:

- vOPRF-ID skill
- zkPassport skill
- ZK Email skill
- ZK JWT skill

Ownership:

- Rasul / PSE: vOPRF-ID
- Rahul / EF DevTooling & Builder Growth: expected / proposed ownership for zkPassport, ZK Email, and ZK JWT
- Philip / Builder Growth: expected / proposed ownership for zkPassport, ZK Email, and ZK JWT

Deliverables:

- first usable skill files for vOPRF-ID, zkPassport, ZK Email, and ZK JWT,
- integration notes for each project,
- example prompts and test tasks,
- initial notes on how these skills may combine with Semaphore, RLN, and TLSNotary.

### 14.06.2026

Focus:

- completing unfinished project skills,
- cleanup and consistency across all skill files,
- preparing combined-use testing,
- defining routing behavior for the future super SKILL.

Deliverables:

- consistent project skill structure,
- updated skill files based on early testing,
- list of cross-skill application scenarios,
- first draft of super SKILL routing logic.

### 21.06.2026

Focus:

- manual testing on real-world application tasks,
- testing combinations of skills,
- identifying weak points and missing references,
- improving the skills based on test results.

Example combined tests:

- anonymous voting app: Semaphore + zkPassport + vOPRF-ID + Noir,
- Web2 data attestation app: TLSNotary + application integration flow,
- anonymous rate-limited action or messaging app: RLN + Semaphore or related identity flow,
- email or JWT identity proof flow: ZK Email / ZK JWT + application integration.

Deliverables:

- manual test results,
- list of failures and improvement areas,
- updated skills,
- recommendation for the next phase.

## Evaluation and Testing

The main way to evaluate the quality of the skills is to test whether an AI can use them to help build real applications with limited manual intervention.

Evaluation should not only check whether code was produced. It should check whether the result is actually useful.

The main things to verify are:

- whether the AI can understand the task correctly,
- whether it can choose relevant projects, tools, protocols, and references,
- whether it can produce a clean implementation approach,
- whether the code can be built, tested, and iterated on,
- whether the skill helps avoid common setup and integration mistakes,
- how much manual correction is still needed before the result becomes usable.

A good first result is not that the AI can build everything. A good first result is that AI agents become meaningfully better at selected EF / PSE development tasks, and that the remaining gaps become much clearer and easier to improve.

## Super SKILL and Skill Combinations

Once the project-specific skills have been created and tested, the next planned step is to create a super SKILL that can route users to the relevant project-specific skill automatically, without requiring them to choose the right one themselves.

This super SKILL can become part of [ethskills.com](https://ethskills.com/).

It should also support combinations of project skills. For example, a prompt such as "I want to create an anonymous voting app for citizens of X country" may require combining:

- Semaphore for anonymous signaling and Merkle tree handling,
- zkPassport for passport proofs,
- vOPRF-ID for secure identity-derived identifiers or nullifiers,
- Noir skills for circuit implementation where relevant.

The purpose of the super SKILL is not only routing. It should also help AI agents understand which projects should be combined for a user goal, what each project contributes, and where integration risks are likely to appear.

## Out of Scope for Current Phase

The following areas are not primary deliverables for the current phase:

- standalone Circom skill,
- standalone Noir skill,
- broad general zkdev workflow pack,
- cross-harness testing across many agent runtimes,
- zk security review skills,
- zkVM, FHE, MPC, and broad ecosystem expansion.

Some of these may still appear as supporting references when needed for a project-specific skill, but they are not the main focus right now.

## Future Directions

After the initial EF / PSE project skills are stable and tested, the project can expand step by step.

Natural follow-up areas include:

- broader AI-assisted zk development workflows,
- stronger structured knowledge bases for zk and applied cryptography development,
- standalone Circom and Noir skills where they directly support application development,
- benchmark tasks for comparing skill performance across different agents,
- cross-harness testing with tools such as Codex, Claude Code, Droid, OpenClaw, HermesAgent, and others,
- zk security skills based on audits, bug patterns, and common implementation mistakes,
- broader coverage of zkVMs, FHE, MPC, and other privacy-preserving technologies.

These should be treated as follow-up workstreams once the initial EF / PSE project skill set is usable, tested, and has a clear improvement loop.
