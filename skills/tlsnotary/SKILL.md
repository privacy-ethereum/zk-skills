---
name: tlsnotary
description: Build, adapt, and debug TLSNotary agent workflows and TLSNotary Extension plugins. Use when a user wants to prove data from a web service with TLSNotary, create or review a TLSNotary extension plugin, find a JSON API endpoint to notarize, design selective disclosure handlers, intercept browser auth headers, size maxRecvData/maxSentData, or troubleshoot TLSNotary proof generation.
---

# TLSNotary

## Overview

Use this skill to help an agent turn a user goal such as "prove my Spotify top artist" or "prove account data from a bank dashboard" into a practical TLSNotary proof workflow.

The main current workflow is TLSNotary Extension plugin development: find an authenticated JSON endpoint, capture the required auth headers from the browser session, create a plugin that calls `prove(...)`, reveal only the minimum useful fields, build it, and review it for leaked personal data.

## Workflow

1. Clarify what the user wants to prove and who should verify it.
2. Identify whether TLSNotary is appropriate: the data should be returned by a HTTPS endpoint, preferably JSON, and the proof should reveal only selected fields.
3. Research the target service API before writing code.
4. Plan the proof request: endpoint, method, auth headers, request body, response fields, reveal handlers, and data limits.
5. Build or modify the TLSNotary Extension plugin.
6. Verify the plugin locally and inspect the proof output.
7. Review every changed file for secrets or personal data before committing or sharing.

For detailed TLSNotary Extension plugin implementation patterns, read `references/plugin-development.md`.

## API Research

Prefer a JSON endpoint over HTML. Look for a small authenticated GET or POST response that contains the exact user data to prove.

Try automatic discovery first:

- search official docs, known API endpoints, and reverse-engineered API notes;
- inspect the website's JavaScript, `__NEXT_DATA__`, and inline `window.*` variables;
- try common paths such as `/api/`, `/api/v1/`, `/graphql`, `/proxy/`, or service-specific API prefixes;
- inspect existing TLSNotary demo plugins for similar auth or endpoint patterns.

If discovery fails, ask the user for a browser DevTools Network capture. Have them filter XHR/Fetch, choose the relevant request, and copy it as cURL. From that request, identify the URL, method, auth headers, request body, and response shape.

Never hardcode real cookies, bearer tokens, CSRF tokens, email addresses, account IDs, or usernames into a skill, plugin, test fixture, or committed file.

## Proof Planning Checklist

Before editing code, write down:

- endpoint host, path, method, and request body if any;
- auth strategy: Cookie, Authorization, CSRF token, or a combination;
- `useHeaders()` filter strategy for each auth credential;
- window URL to open, usually a dashboard or home page that continues making authenticated requests;
- `maxRecvData` based on response size plus buffer;
- `maxSentData` based on request size, especially cookie size;
- JSON fields to reveal and why each field is necessary;
- theme/name/UI text only if building an extension plugin.

Use broad header filters for cookies on the service domain. Use specific filters for API-only headers such as CSRF tokens. Remember that `useHeaders()` only captures requests after the listener is active; avoid pages where the needed API call fires once during initial page load.

## Required TLSNotary Request Rules

Always include these headers in `prove(...)` requests unless upstream SDK guidance changes:

```typescript
'Accept-Encoding': 'identity',
Connection: 'close',
```

`Accept-Encoding: identity` avoids compressed responses that are harder to handle. `Connection: close` gives clean TLS session termination.

Reveal the minimum useful data. Usually reveal the sent start line, received start line, response date header, and selected JSON response paths. Reveal request bodies only when needed to make a POST or GraphQL proof understandable.

## Verification

For TLSNotary Extension plugins, build with `esbuild` using the verifier and proxy defines expected by the extension development flow. Then test the built JavaScript in the extension Developer Console.

After verification, inspect all created or modified files for:

- cookies,
- bearer tokens,
- CSRF tokens,
- emails,
- usernames,
- account IDs,
- copied personal API responses.

If any live secret or personal identifier appears in code, remove it before continuing.

## Output Expectations

When building a plugin, produce:

- the plugin file or patch,
- the build command used,
- the endpoint and auth strategy,
- the fields revealed in the proof,
- sizing choices for `maxRecvData` and `maxSentData`,
- verification notes and known limitations.

When only planning, produce the same information without code edits and clearly mark unknowns that require a Network capture or user-provided cURL.
