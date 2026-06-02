# cURL To TLSNotary Plugin

Use this when the user provides a DevTools "Copy as cURL" request or when API discovery finds a candidate request.

## Safety First

- Do not commit or paste real cookies, bearer tokens, CSRF tokens, emails, usernames, or account ids.
- If the cURL contains secrets, extract the structure and replace values with placeholders.
- Only run the cURL when it is necessary and safe. Prefer inspecting method, URL, headers, and body first.

## SDK And Runtime

Checked on 2026-06-02: `@tlsn/plugin-sdk` exists in `tlsnotary/tlsn-extension/packages/plugin-sdk`, but `npm view @tlsn/plugin-sdk` returned 404. Do not assume `npm install @tlsn/plugin-sdk` works unless registry availability has been re-checked.

When building inside `tlsn-extension`, use the monorepo packages:

```text
packages/plugin-sdk
packages/plugins
packages/ts-plugin-sample
```

Plugin code imports SDK types but relies on runtime globals injected by the extension, including `useHeaders`, `useRequests`, `useState`, `setState`, `useEffect`, `openWindow`, `prove`, `done`, and `doneWithOverlay`.

## Convert Request

1. Parse the method, full URL, host, path, query string, headers, and body.
2. Confirm the response is HTTPS and preferably JSON.
3. Estimate response size with a synthetic or user-approved request.
4. Identify which headers are needed: `Cookie`, `Authorization`, CSRF, custom app headers.
5. Choose a `useHeaders()` filter that can capture those headers after the plugin starts.
6. Choose a stable `openWindow()` URL that causes authenticated requests to happen.
7. Create `config.requests` with method, host, pathname, and verifier URL.
8. Build `prove()` with the cURL method/path/body and captured headers.
9. Reveal only the minimum start lines, date/status if needed, and selected JSON fields.

## GET Skeleton

```typescript
const api = "api.example.com"
const apiPath = "/v1/me"

const headers: Record<string, string> = {
  authorization: cachedAuthorization,
  Host: api,
  "Accept-Encoding": "identity",
  Connection: "close"
}

const resp = await prove(
  {
    url: `https://${api}${apiPath}`,
    method: "GET",
    headers
  },
  {
    verifierUrl: __VERIFIER_URL__,
    proxyUrl: __PROXY_URL__ + api,
    maxRecvData: 4000,
    maxSentData: 1200,
    handlers
  }
)
```

## POST Or GraphQL Skeleton

```typescript
const body = JSON.stringify({
  query: "{ currentUser { id status } }"
})

const headers: Record<string, string> = {
  cookie: cachedCookie,
  "x-csrf-token": cachedCsrfToken,
  "content-type": "application/json",
  Host: api,
  "Accept-Encoding": "identity",
  Connection: "close"
}

const resp = await prove(
  {
    url: `https://${api}/graphql`,
    method: "POST",
    headers,
    body
  },
  {
    verifierUrl: __VERIFIER_URL__,
    proxyUrl: __PROXY_URL__ + api,
    maxRecvData: 16384,
    maxSentData: 4096,
    handlers: [
      { type: "SENT", part: "START_LINE", action: "REVEAL" },
      { type: "SENT", part: "BODY", action: "REVEAL" },
      { type: "RECV", part: "START_LINE", action: "REVEAL" },
      { type: "RECV", part: "HEADERS", action: "REVEAL", params: { key: "date" } },
      { type: "RECV", part: "BODY", action: "REVEAL", params: { type: "json", path: "data.currentUser.status" } }
    ]
  }
)
```

## Verifier, Proxy, And Handlers

Existing plugins usually inject:

```typescript
declare const __VERIFIER_URL__: string
declare const __PROXY_URL__: string
```

Use:

```typescript
proxyUrl: __PROXY_URL__ + api
```

Browsers need a WebSocket proxy because extensions cannot open raw TCP connections. Keep verifier/proxy configurable; local examples commonly use `http://localhost:7047` for verifier-style URLs.

Minimal handlers for a JSON GET proof:

```typescript
[
  { type: "SENT", part: "START_LINE", action: "REVEAL" },
  { type: "RECV", part: "START_LINE", action: "REVEAL" },
  { type: "RECV", part: "HEADERS", action: "REVEAL", params: { key: "date" } },
  { type: "RECV", part: "BODY", action: "REVEAL", params: { type: "json", path: "target.field" } }
]
```

For sensitive values, hash instead of reveal when a commitment is enough:

```typescript
{
  type: "RECV",
  part: "BODY",
  action: { kind: "HASH", algorithm: "SHA256" },
  params: { type: "json", path: "target.secretField" }
}
```

## cURL Mapping Checklist

```text
curl method -> prove().method
curl URL host -> Host header and proxy token host
curl URL path/query -> config.requests.pathname and prove().url
curl Cookie -> useHeaders broad domain filter
curl Authorization -> useHeaders API filter
curl CSRF -> useHeaders API filter
curl body -> prove().body and usually SENT BODY reveal
curl response fields -> RECV BODY json handlers
```

## Done Criteria

- no live secrets in plugin source, tests, logs, or examples;
- plugin has a request permission matching the proof request;
- headers are captured after the plugin starts;
- `Accept-Encoding: identity` and `Connection: close` are set;
- `maxRecvData` and `maxSentData` cover response/request sizes;
- handlers reveal only what the verifier needs.

## Troubleshooting Checks

- SDK install fails: use the local `tlsn-extension/packages/plugin-sdk` workspace package.
- Auth headers not captured: ensure matching requests happen after the plugin starts; broaden the filter if needed.
- `prove()` rejected: compare `prove().url`, method, host/path, verifier URL, and `config.requests`.
- Proof stalls: check `Accept-Encoding: identity`, `Connection: close`, `maxRecvData`, and `maxSentData`.
- JSON path empty: inspect sanitized response shape and reveal a smaller parent object if needed.
