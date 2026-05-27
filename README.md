<h1 align="center">ZK Skills</h1>

<p align="center">
  AI-friendly skills for building practical applications with privacy and zero-knowledge tools.
</p>

## Overview

This repository contains project-specific Codex skills for PSE / Ethereum Foundation privacy tooling. The goal is to help coding agents move from a product idea to a working prototype with clearer setup, integration, testing, and debugging guidance.

## Current Skills

- `tlsnotary`: build and debug TLSNotary proof workflows and extension plugins.
- `semaphore`: build anonymous group membership, voting, feedback, and nullifier-based apps with Semaphore.
- `rln`: build anonymous rate-limited apps with RLN, including routing between audited RLN and RLN V3.

## Structure

```text
skills/
  <project>/
    SKILL.md
    agents/openai.yaml
    references/
```

Each `SKILL.md` is written for immediate agent use: when to apply the tool, what to check before coding, how to implement common app patterns, and what to verify before shipping.
