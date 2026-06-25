# ADR-0010: Google Maps (JavaScript API) for map visualization across all hosts

**Status:** Accepted

## Context

Several stories specify a **live Google Map** as the core of their screen — `FE-003` (dispatcher fleet map: "all fleet vehicles on a live Google Map with colour-coded markers"), `FE-011` (rep active-job: "my active job on a live Google Map with my position and the requester's pin"), `FE-015` (requester submit: location confirmation map), and `FE-017` (requester live rep tracking). The map is not a nice-to-have; it is the primary surface for three of the four personas.

Despite that, **no real map was ever integrated.** The two built map screens (`ActiveJob.razor`, `JobOffer.razor`) render a **CSS/SVG placeholder** — a gradient `div.sd-map`, an SVG "road grid", and markers absolutely-positioned at hardcoded percentages (`data-lat`/`data-lng` attributes are carried but never used to place anything). The dispatcher and requester map screens are still stubs. No ADR records which provider to use or how to integrate it across hosts.

This system is a **MAUI Blazor Hybrid** app (ADR-0008): the **Web** host is Blazor WASM in a real browser; the **Mobile** and **Desktop** hosts are MAUI `BlazorWebView`. A single mapping approach must serve all three. `ADR-0004` already evaluated the Google Directions API but only for *distance/matching* (it chose Haversine); it did not decide a *visualization* provider.

Options considered:
- **Google Maps JavaScript API** in the WebView, wrapped as one Blazor component (browser + BlazorWebView both run JS).
- **Native map SDKs** (Apple MapKit / Android Maps) via per-platform MAUI bindings — diverges from the shared `Core`/`UI` architecture and needs a separate web implementation anyway.
- **Mapbox / Leaflet + OpenStreetMap** — viable, but the backlog already names Google Maps, and the team wants Google Maps.

## Decision

Use the **Google Maps JavaScript API**, wrapped in a **single reusable Blazor map component** in `ServiceDelivery.Client.UI`, driven from .NET via `IJSRuntime` interop. The same component serves every host: the Web browser and the MAUI `BlazorWebView` (a full WebView that runs the Maps JS API). Markers, pins, and polylines are added/updated/removed from C# through the interop layer; map screens (`FE-003`, `FE-011`/`FE-012`, `FE-015`, `FE-017`, and the job-offer map) consume this one component rather than each loading the SDK.

The Maps JS SDK is loaded per host from each `wwwroot/index.html`, with the **API key supplied as host configuration** (never committed). ETA and matching distance remain **Haversine** per `ADR-0004`; the on-map route is drawn as a `Polyline` (a straight line between rep and requester) — real driving routes via the Directions API are an explicit, optional future enhancement, not part of this decision.

## Consequences

- **One component, all hosts** — consistent with the `Core`/`UI`-shared, thin-host architecture (ADR-0008). A map bug is fixed once.
- **Requires a Google Cloud project** with the *Maps JavaScript API* enabled and **billing active**, plus an **API key per environment**. The key is host config: `appsettings.Local.json` / env var locally (both gitignored), Azure Key Vault or pipeline secrets in the cloud. It is never committed.
- **BlazorWebView origin caveat** — the MAUI WebView serves from a non-HTTP origin (e.g. `app://`, `https://0.0.0.0/`), so a standard *HTTP-referrer* key restriction may not match. Use platform/app key restrictions (iOS bundle id, Android package + SHA, Windows) or a separate dev key; this must be validated when the loader is built (`FE-025`).
- **Testing** — bUnit cannot render the JS map, so the map component is unit-tested by asserting the interop calls it makes (markers/polylines passed) and by `data-testid` overlays; the real render is verified by Playwright (`QUAL-003`) and Appium (`QUAL-004`) and by the AI-review render-and-screenshot check. Maps assertions target overlay/test-id elements, never the tile layer.
- **Supersedes the CSS/SVG placeholder map** in `ActiveJob.razor` / `JobOffer.razor`; the `sd-map`/`sd-roadgrid`/`sd-routeline` placeholder styles are removed as each screen adopts the real component.
- **Real routing deferred** — turn-by-turn or road-accurate routes/ETA would need the Directions API (added cost and a server-side proxy or client call). Captured as an optional story; ETA stays Haversine until then.
