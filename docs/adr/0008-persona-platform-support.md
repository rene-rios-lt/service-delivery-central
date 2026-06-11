# ADR-0008: Persona Platform Support

**Status:** Accepted

## Context

The frontend (`service-delivery-frontend`) is a single shared Razor UI hosted on three platforms — Desktop and Mobile via .NET MAUI Blazor Hybrid, and Web via Blazor WASM. The system serves three personas: Dispatcher, Service Rep, and Requester. Login routes each user to their persona view based on a JWT role claim.

The original framing left platform support ambiguous — documentation stated the frontend provided "Desktop, Web, and Mobile views for all three personas" and that "any persona can use any platform." Taken literally this implied nine persona×platform combinations must all be designed, built, and tested, including a mobile Dispatcher layout and a desktop/web Service Rep layout.

That is not the intent, and designing for it would waste effort:

- The **Dispatcher** is a command-center operator. The view is a dense, real-time dashboard — a live fleet map and the active request queue side by side, plus redirect controls and an alert banner. This is a desktop/web ergonomic; it does not fit a phone.
- The **Service Rep** is a field technician operating from inside a vehicle. The view is single-task and touch-first (claim vehicle → receive offer with countdown → navigate → arrive → complete). This is inherently a mobile experience.
- The **Requester** is a customer reporting a fault from whatever device they have on hand, so the view must work everywhere.

The ambiguity surfaced while preparing a UI design brief, where "which platforms does each persona need a layout for?" had no authoritative answer.

## Decision

Each persona is supported on a fixed subset of platforms. Only these combinations are designed, built, and tested:

| Persona | Desktop | Web | Mobile |
|---------|:-------:|:---:|:------:|
| **Dispatcher** | ✅ | ✅ | ❌ |
| **Service Rep** | ❌ | ❌ | ✅ |
| **Requester** | ✅ | ✅ | ✅ |

The shared Razor UI still compiles and runs on all three hosts; this decision governs which persona *views* are designed and supported, not which host projects exist. Login continues to route by JWT role on whichever host the user launches.

## Consequences

- No mobile Dispatcher layout and no Desktop/Web Service Rep layout are designed, built, or tested. UI design and stories cover only the ✅ combinations above.
- The Dispatcher view is built to be responsive across Desktop and Web; the Requester view is built to be responsive from Mobile through Desktop; the Service Rep view targets Mobile only.
- A persona signing in on an unsupported platform (e.g. a Dispatcher launching the mobile host) is out of scope for the POC — no specific layout or graceful-degradation behavior is guaranteed.
- The authoritative platform matrix lives in [`system-overview.md` § Persona Platform Support](../architecture/system-overview.md#persona-platform-support); the frontend stories ([`frontend.md`](../stories/frontend.md)) and the [UI design brief](../ui-design-brief.md) reference it. Frontend repo guidance (`CLAUDE.md`) lists the supported platforms per role.
- This narrows scope only; revisiting it (e.g. adding a mobile Dispatcher companion view post-POC) would supersede this ADR.
