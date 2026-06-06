# ADR-0003: Simulated JWT Auth for POC

**Status:** Accepted

## Context

The system requires authentication and role-based access control (RBAC) to serve different views to Dispatchers, Service Reps, and Requesters. In production, this would use Azure Active Directory. However, this is a POC — the goal is to demonstrate the product's capabilities, not Azure AD integration. Adding Azure AD would introduce unnecessary setup complexity and external dependencies that have nothing to do with proving the core dispatch technology.

The simulator also needs to authenticate with the backend API to push vehicle position updates.

## Decision

Use **local simulated JWT authentication** with pre-seeded users in the database. No Azure AD, no external identity provider.

- All users (Dispatchers, Service Reps, Requesters, and the Simulator service account) are pre-seeded in the database with their role and tier
- Login exchanges credentials for a JWT containing the user's role claim
- The frontend reads the role from the JWT and renders the appropriate persona view
- The simulator authenticates with a dedicated pre-seeded service account — same mechanism as all other users, no special cases
- No user registration flow is needed — all accounts are pre-configured for the demo

### Real Application Path

When the POC graduates to production:
- **Human users** → Azure AD B2C with OAuth 2.0 Authorization Code flow
- **Telematics integration (replaces simulator)** → OAuth 2.0 Client Credentials flow via Azure AD App Registration (machine-to-machine, no human login)

The backend auth middleware must be designed to be **issuer-agnostic** from day one, so swapping the local token issuer for Azure AD is a configuration change, not a code change.

## Consequences

- Zero external auth dependencies for the POC — the system runs entirely locally
- Every actor in the system uses the same JWT auth model — consistent, no special-cased endpoints
- The simulator's authentication pattern directly mirrors what a real Telematics M2M integration would do (issue a token, include it on every request), making the transition path clear
- RBAC is enforced by the backend on every request — the frontend role-based view is a UX concern, not a security boundary
