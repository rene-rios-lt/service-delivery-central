# ADR-0004: Haversine Straight-Line Distance for Proximity Calculations

**Status:** Accepted

## Context

The system requires distance calculations in two places:
1. **Matching algorithm** — find the nearest qualified service rep for an incoming request
2. **15-mile protection threshold** — detect when a rep is within 15 miles of their destination and trigger the state change from En Route to Within 15 Miles

Options considered:
- **Haversine formula** — calculates straight-line (as-the-crow-flies) distance between two lat/lng coordinates
- **Google Maps Directions API (road distance)** — calculates actual driving distance along roads

## Decision

Use the **Haversine formula** for all proximity calculations in the POC.

Road distance is more accurate but requires a Google Maps Directions API call for every comparison — adding latency, API cost, and an external dependency on every position update (every 3 seconds, 8 vehicles = 160 calls/minute). For a POC operating across Iowa, straight-line distance is a reasonable approximation.

### ETA Calculation

ETA uses the same Haversine distance divided by an assumed average speed of **60 mph**, consistent with typical Iowa highway and rural road conditions for service vehicles.

```
ETA (minutes) = (Haversine distance in miles / 60) × 60
```

## Consequences

- All distance-based logic is self-contained in the backend — no external API calls required for matching or threshold detection
- The 15-mile threshold check runs on every position update in the backend, using the same formula as the matching algorithm — consistent behavior, no surprises
- ETA will be approximate, not turn-by-turn accurate — acceptable for a POC
- When the real application requires road-accurate ETAs, the backend can swap Haversine for a routing API call in the ETA service without changing the matching algorithm or the 15-mile threshold logic
