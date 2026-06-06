# ADR-0002: SignalR for Real-Time Communication

**Status:** Accepted

## Context

The system requires real-time updates across multiple clients simultaneously: vehicle positions must stream to dispatcher maps every 3 seconds, job offers must be pushed to specific service reps, and requesters must receive live ETA updates and redirect notifications. A push mechanism is required — polling is not viable at this frequency and this scale.

Options considered:
- **Raw WebSockets** — low-level, full control, but requires building connection management, reconnection logic, and message routing from scratch
- **SignalR** — Microsoft's real-time library built on WebSockets (with SSE/long-polling fallbacks)
- **Server-Sent Events (SSE)** — lightweight, but server-to-client only; cannot handle client-to-server messaging
- **gRPC streaming** — efficient and strongly typed, but poor browser support without grpc-web

## Decision

Use **SignalR** with WebSocket transport.

SignalR is WebSockets under the hood. It adds:
- **Hub groups** — broadcast to all connected dispatchers; push to exactly one service rep's connection
- **Connection management** — handles reconnects and dropped connections automatically
- **Typed hubs** — strongly typed message contracts, consistent with Clean Architecture
- **Blazor first-class support** — no friction integrating with the MAUI Blazor Hybrid frontend

The hub-group capability is particularly important: when a dispatcher redirects a rep, the backend must push the new assignment to that one rep's device while simultaneously broadcasting the updated fleet state to all dispatchers.

## Consequences

- The simulator connects to the backend's SignalR hub the same way a real Telematics feed would — the backend does not distinguish between simulated and live position data
- The backend owns all business logic triggered by position updates (15-mile threshold checks, ETA recalculation) — the frontend and simulator are pure consumers/publishers
- Fallback transports (SSE, long-polling) are available automatically if WebSocket connections are not supported in a given environment
