# Service Delivery Central

Central repository for the Service Delivery system. Owns local dev orchestration, AI skill and agent definitions, and system-level documentation.

## Repositories

| Repo | Purpose |
|------|---------|
| [service-delivery-central](https://github.com/rene-rios-lt/service-delivery-central) | This repo — scripts, AI skills/agents, architecture docs |
| [service-delivery-frontend](https://github.com/rene-rios-lt/service-delivery-frontend) | .NET MAUI Blazor Hybrid — Desktop, Mobile, Web |
| [service-delivery-backend](https://github.com/rene-rios-lt/service-delivery-backend) | .NET 10 Clean Architecture API + Azure (Terraform) |
| [service-delivery-simulator](https://github.com/rene-rios-lt/service-delivery-simulator) | .NET 10 Worker Service — POC vehicle data simulator |

## Local Development

### Launch the web client

From the repo root:

```bash
./scripts/local/launchWebPage.sh
```

This will kill any existing instance on port 5023, start the Blazor WASM web app, and open it in your browser at `http://localhost:5023`.
