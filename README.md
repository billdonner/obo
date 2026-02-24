# OBO

OBO is a flashcard learning app powered by AI-generated decks stored in PostgreSQL and served via a FastAPI backend. The backend is being unified into **card-engine**, which also serves the Alities trivia platform from the same database.

## Architecture

```
                    ┌─────────────┐
obo-gen ──────────► │             │ ──► /api/v1/flashcards ──► obo-ios / flasherz-ios
  (CLI)             │  card-engine│
ingestion ────────► │  (FastAPI)  │ ──► /api/v1/trivia ─────► alities-mobile
  (providers)       │  port 9810  │
                    │             │ ──► /api/v1/decks ──────► generic clients
                    └──────┬──────┘
                           │
                      PostgreSQL
                     (card_engine)
```

- **card-engine** unified backend serving both flashcard and trivia content
- **obo-gen** calls the Claude API to generate flashcard content, writes decks to Postgres
- **obo-ios** / **flasherz-ios** fetch decks from `/api/v1/flashcards`
- **alities-mobile** fetches trivia from `/api/v1/trivia/gamedata`

## card-engine API

Port **9810** — inherits from obo-server.

### Core Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | DB connectivity check |
| GET | `/metrics` | Deck/card/source counts for server-monitor |

### Generic (Layer 1)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/decks` | List decks — filters: `kind`, `age`, `limit`, `offset` |
| GET | `/api/v1/decks/{id}` | Single deck with all cards |

### Flashcard Adapter (Layer 2) — backward-compatible with obo-ios

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/flashcards` | All flashcard decks with cards in one bulk call |
| GET | `/api/v1/flashcards/{id}` | Single flashcard deck with cards |

### Trivia Adapter (Layer 2) — backward-compatible with alities-mobile

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/trivia/gamedata` | Bulk export in alities Challenge format |
| GET | `/api/v1/trivia/categories` | Categories with counts + SF Symbol pics |

### Commands

```bash
# Install dependencies
cd ~/card-engine && pip install -e ".[dev]"

# Apply schema
psql -d card_engine -f ~/card-engine/schema/001_initial.sql

# Run server (dev)
cd ~/card-engine && python3.11 -m uvicorn server.app:app --port 9810 --reload

# Test endpoints
curl localhost:9810/health
curl localhost:9810/api/v1/decks
curl localhost:9810/api/v1/flashcards
curl localhost:9810/api/v1/trivia/gamedata
curl localhost:9810/api/v1/trivia/categories
curl localhost:9810/metrics
```

## Live URLs

| App | URL |
|-----|-----|
| OBO Server (API + web UI) | https://bd-obo-server.fly.dev |
| Nagzerver (API + web app) | https://bd-nagzerver.fly.dev |
| Alities Engine | https://bd-alities-engine.fly.dev |
| Server Monitor | https://bd-server-monitor.fly.dev |

## Documentation

See [Docs/](Docs/) for specs and architecture docs.

## All Projects

### OBO / card-engine — Flashcard + trivia platform

| Repo | Description | Port |
|------|-------------|------|
| [obo](https://github.com/billdonner/obo) | **This repo** — specs, docs, orchestration hub | — |
| [card-engine](https://github.com/billdonner/card-engine) | Unified FastAPI backend (replaces obo-server + alities-engine HTTP) | 9810 |
| [obo-server](https://github.com/billdonner/obo-server) | Legacy flashcard API (being replaced by card-engine) | 9810 |
| [obo-gen](https://github.com/billdonner/obo-gen) | Swift CLI deck generator | — |
| [obo-ios](https://github.com/billdonner/obo-ios) | SwiftUI iOS flashcard app | — |

### Nagz — AI-mediated nagging/reminder app

| Repo | Description | Port |
|------|-------------|------|
| [nagz](https://github.com/billdonner/nagz) | Hub — specs, docs, orchestration | — |
| [nagzerver](https://github.com/billdonner/nagzerver) | Python API server | 9800 |
| [nagz-web](https://github.com/billdonner/nagz-web) | TypeScript/React web app | 5173 |
| [nagz-ios](https://github.com/billdonner/nagz-ios) | SwiftUI iOS app + Apple Intelligence | — |

### Alities — Trivia game platform

| Repo | Description | Port |
|------|-------------|------|
| [alities](https://github.com/billdonner/alities) | Hub — specs, docs, orchestration | — |
| [alities-engine](https://github.com/billdonner/alities-engine) | Swift trivia engine daemon | 9847 |
| [alities-studio](https://github.com/billdonner/alities-studio) | React/TypeScript game designer | 9850 |
| [alities-mobile](https://github.com/billdonner/alities-mobile) | SwiftUI iOS game player | — |
| [alities-trivwalk](https://github.com/billdonner/alities-trivwalk) | Python TrivWalk trivia game | — |

### Server Monitor — Multi-frontend server dashboard

| Repo | Description | Port |
|------|-------------|------|
| [monitor](https://github.com/billdonner/monitor) | Hub — specs, docs, orchestration | — |
| [server-monitor](https://github.com/billdonner/server-monitor) | Python web dashboard + Terminal TUI | 9860 |
| [server-monitor-ios](https://github.com/billdonner/server-monitor-ios) | SwiftUI iOS + WidgetKit companion | — |

### Standalone Tools

| Repo | Description |
|------|-------------|
| [claude-cli](https://github.com/billdonner/claude-cli) | Swift CLI for the Claude API |
| [Flyz](https://github.com/billdonner/Flyz) | Fly.io deployment configs for all servers |
