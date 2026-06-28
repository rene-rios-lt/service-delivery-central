# UI Mockups — Service Delivery

Generated UI design images for **all three personas across every platform they support**, built
directly from [`../ui-design-brief.md`](../ui-design-brief.md) and honoring the persona→platform
matrix in [ADR-0008](../adr/0008-persona-platform-support.md).

## How these were made (and why they share a look)

Every screen is composed from **one shared component library** — [`design-system.css`](design-system.css) —
not drawn per image. The stylesheet defines the design tokens and reusable components once
(app bar with leading hamburger + iOS safe-area chrome — status bar / Dynamic Island and home
indicator, cards, chips, tier badges, buttons, map markers, dialogs, countdown, bottom sheet, …),
mirroring the MudBlazor theme-token strategy from [ADR-0007](../adr/0007-mudblazor-component-library.md).
The domain colors are defined a single time and referenced everywhere:

- **Rep-state marker colors** — Available 🟢 · En Route 🔵 · Within 15 mi 🟡 · On Site 🔴 · Offline ⚪
- **Tier badges** — Bronze · Silver · Gold

Change a token in `design-system.css` and every screen updates consistently — that is the shared
look-and-feel, enforced structurally rather than by hand.

Screens live in [`screens/`](screens/) as HTML composed from those classes. They are rendered to PNG by
[`render.mjs`](render.mjs), which drives headless Chrome over the DevTools Protocol at each platform's
exact viewport (2× for crispness).

> **Maps** are stylized placeholders — the real app uses Google Maps (per the brief). The mockups show
> marker color semantics, routes, and ETA overlays, not real tiles.

### Regenerate

```bash
node docs/ui-mockups/render.mjs    # requires Node + Google Chrome; overwrites images/
```

---

## The shared component library

<img src="images/components__reference-1280x980.png" alt="Shared component library" width="900">

---

## Shared — Authentication (FE-001)

The login screen is identical for every persona; routing to the persona view happens by JWT role.

| Web / Desktop | Mobile |
|:---:|:---:|
| <img src="images/login__web-1280x800.png" alt="Login — web" width="480"> | <img src="images/login__mobile-390x844.png" alt="Login — mobile" width="230"> |

---

## Dispatcher — Desktop + Web

Dense command-center dashboard: live fleet map (color-coded markers, popover, legend), the priority-ordered
request queue, the offline alert banner (FE-006), the redirect confirmation dialog (FE-005), and the
force-release confirmation dialog (FE-022). **Not built for mobile** (ADR-0008).

### Fleet dashboard — FE-003 / FE-004 / FE-006

**Desktop (1440)**

<img src="images/dispatcher-dashboard__desktop-1440x900.png" alt="Dispatcher dashboard — desktop" width="900">

**Web (1280)**

<img src="images/dispatcher-dashboard__web-1280x800.png" alt="Dispatcher dashboard — web" width="900">

### Redirect confirmation — FE-005

<img src="images/dispatcher-redirect__desktop-1440x900.png" alt="Dispatcher redirect dialog" width="900">

### Force-release confirmation — FE-022

<img src="images/dispatcher-force-release__desktop-1440x900.png" alt="Dispatcher force-release dialog" width="900">

### Account menu & logout — FE-021

<img src="images/dispatcher-nav__desktop-1440x900.png" alt="Dispatcher account menu" width="900">

---

## Service Rep — Mobile only

Single-task, touch-first field experience. **Not built for desktop/web** (ADR-0008). The rep signs in as one of `rep1…rep8` and **takes over an idle vehicle** from the simulator (FE-007); from then on the human makes the decisions while the simulator drives the truck's position (see [ADR-0009](../adr/0009-simulator-operates-rep-identities-and-human-takeover.md)). The app bar carries the **hamburger on the left** (leading), and both the bar and the left-anchored navigation drawer respect the **iOS safe area** — content sits below the Dynamic Island and clears the home indicator, never clipped (FE-029).

| Take over an idle vehicle (FE-007) | Idle / waiting (FE-020) | Job offer + countdown (FE-008) |
|:---:|:---:|:---:|
| <img src="images/rep-takeover__mobile-390x844.png" alt="Rep — take over an idle vehicle" width="250"> | <img src="images/rep-idle__mobile-390x844.png" alt="Rep — idle waiting for offers" width="250"> | <img src="images/rep-job-offer__mobile-390x844.png" alt="Rep — job offer with countdown" width="250"> |

| Active job — En Route (FE-011) | On site (FE-012/013) | Nav drawer · Release vehicle (FE-014/021) |
|:---:|:---:|:---:|
| <img src="images/rep-active-job__mobile-390x844.png" alt="Rep — active job navigation" width="250"> | <img src="images/rep-on-site__mobile-390x844.png" alt="Rep — on site" width="250"> | <img src="images/rep-nav-drawer__mobile-390x844.png" alt="Rep — nav drawer" width="250"> |

| Release vehicle confirm (FE-014) | | |
|:---:|:---:|:---:|
| <img src="images/rep-release-vehicle__mobile-390x844.png" alt="Rep — release vehicle confirm" width="250"> | | |

---

## Requester — Desktop + Web + Mobile

Consumer-grade, responsive from phone to desktop. Submit → finding → tracking → complete. On the **mobile** renders the app bar respects the iOS safe area (status bar / Dynamic Island and home indicator); the **web/desktop** renders of the same screens show no such chrome — the safe-area chrome is gated to a phone-width viewport (FE-029).

### Submit a request — FE-015

| Web / Desktop | Mobile |
|:---:|:---:|
| <img src="images/requester-submit__web-1280x800.png" alt="Requester submit — web" width="480"> | <img src="images/requester-submit__mobile-390x844.png" alt="Requester submit — mobile" width="230"> |

### Live rep tracking — FE-017

| Web / Desktop | Mobile |
|:---:|:---:|
| <img src="images/requester-tracking__web-1280x800.png" alt="Requester tracking — web" width="480"> | <img src="images/requester-tracking__mobile-390x844.png" alt="Requester tracking — mobile" width="230"> |

### Redirect notification — FE-018

| Web / Desktop | Mobile |
|:---:|:---:|
| <img src="images/requester-redirect__web-1280x800.png" alt="Requester redirect notification — web" width="480"> | <img src="images/requester-redirect__mobile-390x844.png" alt="Requester redirect notification — mobile" width="230"> |

### Finding a technician (FE-016) · Service complete (FE-019)

| Finding — Mobile | Complete — Mobile |
|:---:|:---:|
| <img src="images/requester-finding__mobile-390x844.png" alt="Requester — finding a technician" width="250"> | <img src="images/requester-complete__mobile-390x844.png" alt="Requester — service complete" width="250"> |

---

## File map

```
docs/ui-mockups/
├── README.md            ← this index
├── design-system.css    ← the shared component library (single source of truth)
├── render.mjs           ← CDP renderer: screens/*.html → images/*.png
├── screens/             ← one HTML file per screen, composed from design-system.css
└── images/              ← generated PNGs (persona__platform-WxH.png)
```

## Coverage vs. the persona platform matrix

| Persona | Desktop | Web | Mobile |
|---------|:-------:|:---:|:------:|
| Dispatcher | ✅ | ✅ | — (n/a) |
| Service Rep | — (n/a) | — (n/a) | ✅ |
| Requester | ✅ | ✅ | ✅ |

Login is shown on Web + Mobile as representative of all hosts. Requester Desktop and Web share the same
responsive layout (shown once as "Web / Desktop").

## Mapping to user stories

Every screen here maps to one or more frontend user stories. The authoritative
**[Story ↔ Screen Traceability](../stories/frontend.md#story--screen-traceability)** table lives in the
frontend stories, where each story also embeds its mockup. New screens added beyond the original brief:
`rep-takeover` (FE-007 — take over an idle vehicle, supersedes the old `rep-vehicle-select`),
`rep-idle` (FE-020), `rep-on-site` (FE-012/013), `rep-nav-drawer` + `rep-release-vehicle` (FE-014/021),
`dispatcher-nav` (FE-021), `dispatcher-force-release` (FE-022), and `requester-redirect` (FE-018).
