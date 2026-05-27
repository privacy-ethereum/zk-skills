# TLSNotary Extension Plugin Development

Use this reference when creating or modifying a TLSNotary Extension plugin that proves data from a web service.

## Target Endpoint Requirements

Prefer endpoints with these properties:

- GET or POST over HTTPS.
- JSON response, not HTML.
- Small response size where possible; under 16 KB is ideal.
- Contains the exact data to prove, such as username, score, balance, badge, streak, or status.
- Uses browser-interceptable auth, usually cookies, bearer tokens, CSRF tokens, or a combination.

Known example endpoint patterns:

| Service | Endpoint | Method | Auth |
| --- | --- | --- | --- |
| Twitter/X | `api.x.com/1.1/account/settings.json` | GET | Cookie + Authorization + x-csrf-token |
| Spotify | `api.spotify.com/v1/me/top/artists?time_range=medium_term&limit=1` | GET | Authorization bearer token |
| Uber | `riders.uber.com/graphql` | POST | Cookie + x-csrf-token |
| Discord | `discord.com/api/v9/users/@me` | GET | Authorization |
| Duolingo | `www.duolingo.com/2023-05-23/users/{id}?fields=longestStreak,username` | GET | Authorization |
| Garmin | `connect.garmin.com/gc-api/badge-service/badge/earned` | GET | Cookie + connect-csrf-token |
| Swiss Bank demo | `swissbank.tlsnotary.org/balances` | GET | Cookie |

## Discovery Process

1. Search for official docs, known API endpoints, reverse-engineered APIs, or existing client libraries.
2. Fetch or inspect the target website and look for API URLs in JavaScript, `__NEXT_DATA__`, or inline globals.
3. Try common endpoint patterns: `/api/`, `/api/v1/`, `/graphql`, `/gc-api/`, `/proxy/`.
4. Check existing TLSNotary example plugins for matching service patterns.
5. If automatic discovery fails, ask the user to capture the request in Chrome DevTools Network tab, filter XHR/Fetch, and copy the relevant request as cURL.

When the user provides cURL:

- run it only if it is safe and necessary;
- verify the response is JSON;
- check response size with `wc -c`;
- inspect the response structure;
- identify the minimal JSON fields to reveal.

## Planning Fields

Write these down before coding:

- Endpoint: full URL and HTTP method.
- Auth strategy: cookie, bearer token, CSRF token, custom headers.
- Header interception filter: broad for cookies, specific for API-only headers.
- Window URL: usually a home or dashboard page, not a one-shot data page.
- `maxRecvData`: response size plus roughly 15% buffer.
- `maxSentData`: request size; large cookies often need 8192 or more.
- Handlers: selected JSON fields to reveal.
- Theme color and display name if the plugin has UI.

## Auth Interception Patterns

| Auth type | Headers to intercept | Filter pattern |
| --- | --- | --- |
| Cookie only | `Cookie` | Broad: any request to the service domain |
| Bearer token | `Authorization` | API requests to the relevant domain |
| Cookie + CSRF | `Cookie` plus CSRF header | Broad for cookie, specific for CSRF API calls |
| Cookie + Bearer + CSRF | `Cookie`, `authorization`, `x-csrf-token` | Specific API endpoint or API prefix |

Important race condition: `useHeaders()` captures only requests that happen after the plugin listener is active. If a SPA fires the needed API call once during initial load, the plugin may miss it. Open a page that triggers ongoing authenticated requests or use broader domain-level interception for cookies.

Example with separate filters:

```typescript
if (!cachedCookie) {
  const headers = useHeaders((h) =>
    h.filter((x) => x.url.startsWith(`https://${api}/`)),
  );
  const cookie = headers
    .flatMap((h) => h.requestHeaders)
    .find((h) => h.name === 'Cookie')?.value;
  if (cookie) setState('cookie', cookie);
}

if (!cachedCsrfToken) {
  const apiHeaders = useHeaders((h) =>
    h.filter((x) => x.url.startsWith(`https://${api}/gc-api/`)),
  );
  const csrfToken = apiHeaders
    .flatMap((h) => h.requestHeaders)
    .find((h) => h.name === 'connect-csrf-token')?.value;
  if (csrfToken) setState('csrf-token', csrfToken);
}
```

## Minimal Plugin Skeleton

Adapt this skeleton rather than copying it blindly.

```typescript
import type {
  PluginConfig,
  RequestPermission,
  Handler,
  DomJson,
  InterceptedRequestHeader,
} from '@tlsn/plugin-sdk';

declare const __VERIFIER_URL__: string;
declare const __PROXY_URL__: string;

const api = 'example.com';
const apiPath = '/api/path';

const config: PluginConfig = {
  name: 'Example Proof',
  description: 'Proves selected data from Example',
  requests: [
    {
      method: 'GET',
      host: api,
      pathname: apiPath,
      verifierUrl: __VERIFIER_URL__,
    } satisfies RequestPermission,
  ],
  urls: ['https://example.com/*'],
};

const onClick = async (): Promise<void> => {
  const isRequestPending = useState<boolean>('isRequestPending', false);
  if (isRequestPending) return;
  setState('isRequestPending', true);

  const cachedCookie = useState<string | null>('cookie', null);
  if (!cachedCookie) {
    setState('isRequestPending', false);
    return;
  }

  const headers: Record<string, string> = {
    Host: api,
    Cookie: cachedCookie,
    'Accept-Encoding': 'identity',
    Connection: 'close',
  };

  const resp = await prove(
    {
      url: `https://${api}${apiPath}`,
      method: 'GET',
      headers,
    },
    {
      verifierUrl: __VERIFIER_URL__,
      proxyUrl: __PROXY_URL__ + api,
      maxRecvData: 4000,
      maxSentData: 2000,
      handlers: [
        { type: 'SENT', part: 'START_LINE', action: 'REVEAL' } satisfies Handler,
        { type: 'RECV', part: 'START_LINE', action: 'REVEAL' } satisfies Handler,
        {
          type: 'RECV',
          part: 'HEADERS',
          action: 'REVEAL',
          params: { key: 'date' },
        } satisfies Handler,
        {
          type: 'RECV',
          part: 'BODY',
          action: 'REVEAL',
          params: { type: 'json', path: 'profile.displayName' },
        } satisfies Handler,
      ],
    },
  );

  done(JSON.stringify(resp));
};

const main = (): DomJson => {
  const cachedCookie = useState<string | null>('cookie', null);

  if (!cachedCookie) {
    const headers = useHeaders((h: InterceptedRequestHeader[]) =>
      h.filter((x) => x.url.startsWith(`https://${api}/`)),
    );
    const cookie = headers
      .flatMap((h) => h.requestHeaders)
      .find((h) => h.name === 'Cookie')?.value;
    if (cookie) setState('cookie', cookie);
  }

  useEffect(() => {
    openWindow('https://example.com/');
  }, []);

  return div({}, [
    button({ onclick: 'onClick' }, ['Generate Proof']),
  ]);
};

export default { main, onClick, config };
```

## POST and GraphQL Requests

For POST requests, include `body` in the request options and usually reveal the sent body so the verifier can see what query was made.

```typescript
const resp = await prove(
  {
    url: 'https://riders.uber.com/graphql',
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      cookie: cachedCookie,
      'x-csrf-token': cachedCsrfToken || 'x',
      Host: 'riders.uber.com',
      'Accept-Encoding': 'identity',
      Connection: 'close',
    },
    body: JSON.stringify({ query: '{ currentUser { firstName signupCountry } }' }),
  },
  {
    handlers: [
      { type: 'SENT', part: 'START_LINE', action: 'REVEAL' },
      { type: 'SENT', part: 'BODY', action: 'REVEAL' },
      { type: 'RECV', part: 'START_LINE', action: 'REVEAL' },
      { type: 'RECV', part: 'HEADERS', action: 'REVEAL', params: { key: 'date' } },
      { type: 'RECV', part: 'BODY', action: 'REVEAL', params: { type: 'json', path: 'data' } },
    ],
  },
);
```

## Data Limit Sizing

| Response size | Suggested `maxRecvData` | Suggested `maxSentData` | Notes |
| --- | --- | --- | --- |
| ~200 B | 460 | 180 | Tiny response, simple cookie |
| ~1-1.5 KB | 2400-2500 | 600-1000 | Small JSON, bearer token |
| ~3 KB | 4000 | 2000 | Medium JSON, multiple auth headers |
| ~5 KB | 10000 | 2000 | Medium JSON, message content |
| ~2 KB POST | 16384 | 4096 | GraphQL POST, cookie auth |
| ~62 KB | 70000 | 8192 | Large array, huge session cookie |

Large session cookies may require significantly higher `maxSentData`.

## Handler JSON Path Syntax

Use one `RECV BODY` handler per field unless revealing a whole object is intentional.

- Top-level field: `screen_name`
- Nested field: `accounts.CHF`
- GraphQL data object: `data`
- Array element: `items.0.name`
- First item field: `0.displayName`

## Required Headers

Always include:

```typescript
'Accept-Encoding': 'identity',
Connection: 'close',
```

Without `Accept-Encoding: identity`, the response may be compressed. Without `Connection: close`, TLS session termination can be unreliable for this workflow.

## Build and Test

Build with `esbuild`:

```bash
npx esbuild example.plugin.ts --bundle --format=esm --outfile=example.js \
  --define:__VERIFIER_URL__='"http://localhost:7047"' \
  --define:__PROXY_URL__='"ws://localhost:7047/proxy?token="'
```

Test the built JavaScript in the TLSNotary extension Developer Console.

## Privacy Review

Before committing or sharing, review all created and modified files. Remove:

- usernames,
- emails,
- account IDs,
- cookies,
- bearer tokens,
- CSRF tokens,
- copied API responses with personal data,
- service-specific identifiers that belong to a real user.

Use placeholders in examples and tests.
