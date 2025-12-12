# Building Redirectly SDK for React Native / Expo

This guide explains how to recreate the Flutter Redirectly plugin as a pure TypeScript library for React Native (managed or bare / Expo). It outlines the architecture, dependencies, and step-by-step tasks so you can stand up an equivalent SDK even though the React package starts out empty.

## Target Experience

- `Redirectly` singleton that developers initialize once with their API key.
- Class methods for link CRUD, temp links, link resolution, and deletion.
- Event streams for link clicks and deferred app-install attribution.
- Automatic deep-link ingestion using `Linking`.
- Automatic click logging and one-time install tracking with device/app metadata.
- No custom native modules—everything powered by existing React Native / Expo APIs.

## High-Level Architecture

| Concern | React Native Component |
| --- | --- |
| Configuration & lifecycle | `Redirectly.ts` singleton exposing `initialize`, `dispose`, `createLink`, etc. |
| HTTP layer | Fetch-based client with Redirectly-specific serializers and error helpers. |
| Data models | TypeScript interfaces mirroring the backend responses (links, clicks, install payloads). |
| Deep-link handling | Wrapper around `Linking` or `expo-linking` plus a reducer that extracts username + slug. |
| Events | Lightweight event bus (Node `EventEmitter`, `mitt`, or RxJS Subject) to deliver link clicks + install events. |
| Device info | Helpers using `expo-device`, `expo-application`, `react-native-device-info`, or similar. |
| App-install sentinel | `expo-file-system` or `AsyncStorage` file/flag to ensure install tracking only fires once. |

## Step-by-Step Implementation (build order)

### 1. Scaffold the Package

```bash
npx create-react-native-library react-native-redirectly --namespace redirectly
# or start from an Expo library template if targeting managed apps
```

Inside the new library:

- Enable TypeScript (`tsconfig.json` + `.ts` file extensions).
- Add dependencies:
  ```bash
  yarn add cross-fetch mitt
  expo install expo-linking expo-device expo-application expo-file-system expo-localization
  yarn add -D jest @testing-library/react-native @types/node
  ```
  (Replace Expo packages with bare equivalents like `react-native-device-info` if you are not in the Expo ecosystem.)

### 2. Define Config + Error Types

Create `src/config.ts`:

```ts
export interface RedirectlyConfig {
  apiKey: string;
  baseUrl?: string;
  enableDebugLogging?: boolean;
}

export const DEFAULT_BASE_URL = 'https://redirectly.app';

export class RedirectlyError extends Error {
  constructor(
    message: string,
    readonly type: 'api' | 'network' | 'config' | 'link',
    readonly statusCode?: number,
    readonly details?: unknown,
  ) {
    super(message);
  }
}
```

Add a guard utility (`src/utils/assertInitialized.ts`) that throws `RedirectlyError` when methods run before `initialize`.

### 3. Mirror Backend Models

Create `src/models/index.ts` with interfaces:

- `RedirectlyLink` (slug, target, url, clickCount, createdAt, updatedAt?, metadata?).
- `RedirectlyTempLink` (slug, target, url, expiresAt, createdAt, ttlSeconds?).
- `RedirectlyLinkResolution` (id, slug, target, url, type, createdAt, clickCount?, expiresAt?, ttlSeconds?, metadata?, isExpired boolean computed client-side).
- `RedirectlyLinkClick` (originalUrl, slug, username, receivedAt, error?, linkResolution?).
- `RedirectlyAppInstallRequest` + `RedirectlyAppInstallResponse`.

Export helper functions that convert API JSON to these interfaces (`serializers.ts`). Keep date strings as ISO strings to avoid timezone surprises in JS land.

### 4. Build the HTTP Client

Create `src/api/client.ts`:

```ts
import fetch from 'cross-fetch';
import { DEFAULT_BASE_URL, RedirectlyConfig, RedirectlyError } from '../config';

export class RedirectlyHttpClient {
  constructor(private config: RedirectlyConfig) {}

  private url(path: string) {
    return `${this.config.baseUrl ?? DEFAULT_BASE_URL}${path}`;
  }

  private async request<T>(path: string, init?: RequestInit): Promise<T> {
    const res = await fetch(this.url(path), {
      ...init,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.config.apiKey}`,
        ...(init?.headers ?? {}),
      },
    });

    const body = await res.text();
    const json = body ? JSON.parse(body) : undefined;
    if (!res.ok) {
      throw new RedirectlyError(
        json?.error ?? 'Redirectly API error',
        'api',
        res.status,
        json,
      );
    }
    return json as T;
  }

  // expose createLink, createTempLink, getLinks, getLink, getTempLink,
  // resolveLink, updateLink, deleteLink, deleteTempLink, logClick, logAppInstall
}
```

Each method mirrors the REST endpoints used by the Flutter SDK (`/api/v1/links`, `/api/v1/temp-links`, `/api/v1/resolve/:username/:slug`, `/api/v1/clicks`, `/api/v1/app-installs`).

### 5. Event Bus

In `src/utils/EventBus.ts`, export a tiny wrapper around `mitt`:

```ts
type Events = {
  linkClick: RedirectlyLinkClick;
  appInstall: RedirectlyAppInstallResponse;
};

const bus = mitt<Events>();

export const onLinkClick = (fn: (c: RedirectlyLinkClick) => void) =>
  bus.on('linkClick', fn); // return unsubscribe fn
export const emitLinkClick = (payload: RedirectlyLinkClick) =>
  bus.emit('linkClick', payload);
export const onAppInstall = (fn: (a: RedirectlyAppInstallResponse) => void) =>
  bus.on('appInstall', fn);
export const emitAppInstall = (payload: RedirectlyAppInstallResponse) =>
  bus.emit('appInstall', payload);
```

Store the latest app-install response in memory so late subscribers can read `getCurrentAppInstall()`.

### 6. Deep-Link Listener

Create `src/deepLinks/LinkListener.ts`:

```ts
import * as Linking from 'expo-linking';
import { AppState, AppStateStatus } from 'react-native';

type Handler = (url: string) => Promise<void>;

export class LinkListener {
  private subscription?: { remove(): void };
  private appStateListener?: (state: AppStateStatus) => void;

  constructor(private handler: Handler) {}

  async start() {
    this.subscription = Linking.addEventListener('url', event =>
      this.handler(event.url),
    );
    const initial = await Linking.getInitialURL();
    if (initial) await this.handler(initial);
    this.appStateListener = state => {
      if (state === 'active') {
        Linking.getInitialURL().then(url => url && this.handler(url));
      }
    };
    AppState.addEventListener('change', this.appStateListener);
  }

  stop() {
    this.subscription?.remove();
    if (this.appStateListener) {
      AppState.removeEventListener('change', this.appStateListener);
    }
  }
}
```

Pair it with `parser.ts` that inspects the URL and extracts `{ username, slug }` from either `username.redirectly.app/slug` or a localhost dev URL (`https://localhost:3000?user=username/slug`). If parsing fails, emit a `RedirectlyLinkClick` with an embedded error so apps can log or ignore it.

Example `parser.ts`:

```ts
export const parseRedirectlyUrl = (url: string) => {
  const uri = new URL(url);
  const hostParts = uri.host.split('.');

  // Production: username.redirectly.app/slug
  if (hostParts.length >= 3 && hostParts.slice(1).join('.') === 'redirectly.app') {
    const slug = uri.pathname.replace(/^\\//, '').split('/')[0];
    if (slug) return { username: hostParts[0], slug };
  }

  // Dev: https://localhost:3000?user=username/slug
  const userParam = uri.searchParams.get('user');
  if (uri.host.startsWith('localhost') && userParam?.includes('/')) {
    const [username, slug] = userParam.split('/');
    if (username && slug) return { username, slug };
  }

  return null;
};
```

### 7. Link Resolution & Click Logging

Within your main singleton (`Redirectly.ts`):

1. When a link event arrives, parse username/slug.
2. Call `httpClient.resolveLink(username, slug)` to enrich the click.
3. Emit the `RedirectlyLinkClick` event regardless of success.
4. Fire-and-forget a call to `httpClient.logClick` with metadata:
   - Original URL
   - Username + slug
   - `app_platform: 'react_native'`
   - Session ID (`Date.now()` + random)
   - `utm_*` parameters from `URLSearchParams`
   - Device info (see next step)

Reference handler skeleton:

```ts
private async handleIncomingUrl(url: string) {
  const parsed = parseRedirectlyUrl(url);
  if (!parsed) {
    emitLinkClick({
      originalUrl: url,
      slug: 'unknown',
      username: 'unknown',
      receivedAt: new Date().toISOString(),
      error: { message: 'Invalid Redirectly URL' },
    } as RedirectlyLinkClick);
    return;
  }

  let resolution;
  try {
    resolution = await this.http!.resolveLink(parsed.username, parsed.slug);
  } catch (err) {
    if (this.config?.enableDebugLogging) console.warn('Resolve failed', err);
  }

  emitLinkClick({
    originalUrl: url,
    slug: parsed.slug,
    username: parsed.username,
    receivedAt: new Date().toISOString(),
    linkResolution: resolution,
  });

  this.http!.logClick(parsed.username, parsed.slug, { url, resolution }).catch(() => {});
}
```

### 8. Device Metadata Helpers

In `src/telemetry/deviceInfo.ts`:

```ts
import * as Device from 'expo-device';
import * as Application from 'expo-application';
import * as Localization from 'expo-localization';

export const collectDeviceInfo = () => ({
  platform: Device.osName ?? 'unknown',
  osVersion: Device.osVersion ?? 'unknown',
  deviceModel: Device.modelName ?? 'unknown',
  language: Localization.locale,
  timezone: Localization.timezone,
  appVersion: Application.nativeApplicationVersion ?? 'unknown',
  buildNumber: Application.nativeBuildVersion ?? 'unknown',
});
```

The click logger and install tracker both consume this helper so payloads stay consistent.

### 9. App-Install Tracking

Create `src/telemetry/installTracker.ts`:

```ts
import * as FileSystem from 'expo-file-system';
const SENTINEL = `${FileSystem.documentDirectory}.redirectly_install_tracked`;

export const hasTrackedInstall = async () => {
  try {
    await FileSystem.getInfoAsync(SENTINEL);
    return true;
  } catch {
    return false;
  }
};

export const markInstallTracked = () =>
  FileSystem.writeAsStringAsync(
    SENTINEL,
    JSON.stringify({ trackedAt: new Date().toISOString() }),
  );
```

During `initialize`:

1. Check sentinel; if absent, build `RedirectlyAppInstallRequest` (device info + metadata such as `app_platform: 'react_native'`, plugin version, timestamp).
2. POST to `/api/v1/app-installs`.
3. Emit the response to the event bus so subscribers immediately learn whether the install matched a deferred click.
4. Write the sentinel even if the request fails to avoid hammering the endpoint (optional: retry logic with exponential backoff).

Bare RN alternative: replace `expo-file-system` with `@react-native-async-storage/async-storage` and use a key like `redirectly_install_tracked`.

### 10. Public Facade

`src/Redirectly.ts` ties everything together:

```ts
export class Redirectly {
  private static instance: Redirectly;
  static getInstance() {
    if (!Redirectly.instance) Redirectly.instance = new Redirectly();
    return Redirectly.instance;
  }

  private config?: RedirectlyConfig;
  private http?: RedirectlyHttpClient;
  private linkListener?: LinkListener;

  async initialize(config: RedirectlyConfig) {
    if (this.config) throw new RedirectlyError('Already initialized', 'config');
    this.config = config;
    this.http = new RedirectlyHttpClient(config);
    this.linkListener = new LinkListener(url => this.handleIncomingUrl(url));
    await this.linkListener.start();
    await this.trackInstallIfNeeded();
  }

  dispose() {
    this.linkListener?.stop();
    this.config = undefined;
    this.http = undefined;
  }

  // createLink, createTempLink, getLinks, etc call methods on this.http
  // onLinkClick/onAppInstalled simply proxy to EventBus helpers
}
```

### 11. Usage Walkthrough

```ts
import Redirectly from 'react-native-redirectly';
import { useEffect } from 'react';

export function App() {
  useEffect(() => {
    const redirectly = Redirectly.getInstance();
    redirectly.initialize({
      apiKey: process.env.EXPO_PUBLIC_REDIRECTLY_API_KEY!,
      enableDebugLogging: __DEV__,
    });

    const sub = redirectly.onLinkClick(link => {
      if (link.linkResolution) {
        navigateTo(link.linkResolution.target);
      }
    });

    const installSub = redirectly.onAppInstalled(event => {
      if (event.matched) {
        showAttributedWelcome(event);
      }
    });

    redirectly.getInitialLink().then(link => link && handleLink(link));

    return () => {
      sub.remove();
      installSub.remove();
      redirectly.dispose();
    };
  }, []);

  return <NavigationContainer>{/* ... */}</NavigationContainer>;
}
```

### 12. Build & Release Tasks

- Add npm scripts: `lint`, `test`, `typecheck`, `prepublishOnly` (runs lint + test + build).
- Configure `package.json` `main`, `module`, and `types` to point at built artifacts in `dist/`.
- Add `babel.config.js` for Metro friendliness and `tsconfig.build.json` for emitting declaration files.
- Publish workflow: `yarn lint && yarn test && yarn build && npm publish --access public`.

## Integration Checklist for App Teams

1. **Configure universal links / app links** in `app.json` (Expo) or `AndroidManifest.xml` + `apple-app-site-association`, matching `https://YOUR_SUBDOMAIN.redirectly.app`.
2. **Initialize the SDK** before showing your main navigation so you can react to the very first link.
3. **Subscribe to events** right after initialization and unsubscribe on unmount.
4. **Handle cold-start links** by calling `getInitialLink()` immediately—if it returns a click, process it with the same handler as live events.
5. **Respect install attribution** by checking `getCurrentAppInstall()` during onboarding to decide whether to show personalized content.
6. **Surface errors** by catching Promise rejections from CRUD methods and showing actionable logs (status code, message).

## Testing Strategy

- **Unit tests:** Mock `fetch`, `Linking`, and telemetry helpers to verify serialization, error mapping, and link parsing edge cases.
- **Integration tests:** Use Jest or Detox to simulate receiving deep links and ensure the proper events fire.
- **Manual validation:** Run the sample Expo app, open `https://username.redirectly.app/slug` from Safari/Chrome, and confirm the `onLinkClick` handler fires and the install event appears on the dashboard.

Following these steps yields a React Native package that mirrors the Flutter experience but relies only on standard Expo/React Native capabilities. Add release scripts (build, lint, test, `npm publish`) once functionality is complete.
