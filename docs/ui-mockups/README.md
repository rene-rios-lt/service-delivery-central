# UI Mockups — Service Delivery

Generated UI design images for **all three personas across every platform they support**, built
directly from [`../ui-design-brief.md`](../ui-design-brief.md) and honoring the persona→platform
matrix in [ADR-0008](../adr/0008-persona-platform-support.md).

## How these were made (and why they share a look)

Every screen is composed from **one shared component library** — [`design-system.css`](design-system.css) —
not drawn per image. The stylesheet defines the design tokens and reusable components once
(app bar, cards, chips, tier badges, buttons, map markers, dialogs, countdown, bottom sheet, …),
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
request queue, the offline alert banner (FE-006), and the redirect confirmation dialog (FE-005).
**Not built for mobile** (ADR-0008).

### Fleet dashboard — FE-003 / FE-004 / FE-006

**Desktop (1440)**

<img src="images/dispatcher-dashboard__desktop-1440x900.png" alt="Dispatcher dashboard — desktop" width="900">

**Web (1280)**

<img src="images/dispatcher-dashboard__web-1280x800.png" alt="Dispatcher dashboard — web" width="900">

### Redirect confirmation — FE-005

<img src="images/dispatcher-redirect__desktop-1440x900.png" alt="Dispatcher redirect dialog" width="900">

---

## Service Rep — Mobile only

Single-task, touch-first field experience. **Not built for desktop/web** (ADR-0008).

| Claim a vehicle (FE-007) | Job offer + countdown (FE-008) | Active job navigation (FE-011/012) |
|:---:|:---:|:---:|
| <img src="images/rep-vehicle-select__mobile-390x844.png" alt="Rep — claim a vehicle" width="250"> | <img src="images/rep-job-offer__mobile-390x844.png" alt="Rep — job offer with countdown" width="250"> | <img src="images/rep-active-job__mobile-390x844.png" alt="Rep — active job navigation" width="250"> |

---

## Requester — Desktop + Web + Mobile

Consumer-grade, responsive from phone to desktop. Submit → finding → tracking → complete.

### Submit a request — FE-015

| Web / Desktop | Mobile |
|:---:|:---:|
| <img src="images/requester-submit__web-1280x800.png" alt="Requester submit — web" width="480"> | <img src="images/requester-submit__mobile-390x844.png" alt="Requester submit — mobile" width="230"> |

### Live rep tracking — FE-017

| Web / Desktop | Mobile |
|:---:|:---:|
| <img src="images/requester-tracking__web-1280x800.png" alt="Requester tracking — web" width="480"> | <img src="images/requester-tracking__mobile-390x844.png" alt="Requester tracking — mobile" width="230"> |

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
