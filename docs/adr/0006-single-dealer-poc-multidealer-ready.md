# ADR-0006: Single-Dealer POC, Multi-Dealer Ready Data Model

**Status:** Accepted

## Context

The real Service Delivery system is intended to serve multiple dealers of a corporation — each dealer manages their own fleet of service vehicles and their own territory. The POC, however, demonstrates the system for a single dealer operating across Iowa.

The question is whether the data model should be designed for one dealer or many.

## Decision

The POC operates with a **single dealer**, but the data model includes `dealerId` on all relevant entities from day one.

All entities that are scoped to a dealer — Users, Vehicles, ServiceRequests — carry a `dealerId` foreign key. The single POC dealer is seeded at startup. All API queries filter by the authenticated user's `dealerId`, which comes from their JWT claims.

Users have their dealer and region assigned as part of their seeded account. No dealer-selection UI is needed for the POC.

## Consequences

- Expanding from one dealer to many is a **data and configuration change**, not a schema migration — no columns to add, no query patterns to change
- The matching algorithm already operates within a dealer's fleet boundary (filtering by `dealerId`) — multi-dealer is already the model, just with one tenant
- The POC demo is unaffected — a single dealer behaves identically to a multi-dealer system with one tenant configured
- Engineers should never write queries that assume a single dealer exists — always filter by `dealerId`
