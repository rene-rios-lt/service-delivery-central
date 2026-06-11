# ADR-0007: MudBlazor as the Frontend Component Library

**Status:** Accepted

## Context

The frontend is a data-dense, real-time dispatch dashboard serving three personas across Desktop, Web, and Mobile. It requires:

- A live fleet map with colour-coded vehicle markers (Green / Blue / Yellow / Red / Grey by rep state)
- A request queue with tier badges (Bronze / Silver / Gold)
- Status chips and cards for job offers and active jobs
- Consistent theming across all three platform hosts (Desktop, Web, Mobile)

No component library was specified at project inception. Candidates evaluated: MudBlazor, Fluent UI Blazor, Radzen Blazor, and custom CSS.

## Decision

Use **MudBlazor** as the component library for all Razor components in `ServiceDelivery.Client.UI`.

## Consequences

- `MudBlazor` NuGet package is added to `ServiceDelivery.Client.UI` and `ServiceDelivery.Client.Web`; `MauiProgram.cs` in Desktop and Mobile registers MudBlazor services
- All pages and components use MudBlazor primitives (`MudCard`, `MudChip`, `MudBadge`, `MudDataGrid`, etc.) rather than plain HTML elements where a matching component exists
- The semantic colour palette in `MudTheme` is mapped to business domain colours: rep-state marker colours and tier badge colours are defined once in the theme and referenced by name everywhere
- Custom CSS is minimised — styling is expressed through MudBlazor theme tokens and component parameters first, raw CSS only when a gap exists
- Fluent UI and Radzen are not introduced; mixing component libraries in the same project is not permitted
