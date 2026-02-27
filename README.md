# OBO

OBO is a flashcard learning app powered by AI-generated decks stored in PostgreSQL and served via a FastAPI backend. **cardzerver** is the unified backend serving both OBO flashcards and Alities trivia, with a built-in OpenAI ingestion pipeline.

## Architecture

```
                    ┌──────────────────┐
obo-gen ──────────► │                  │ ──► /api/v1/flashcards ──► obo-ios / flasherz-ios
  (CLI)             │   cardzerver    │
OpenAI ◄──────────► │   (FastAPI)      │ ──► /api/v1/trivia ─────► alities-mobile
  (ingestion)       │   port 9810      │
                    │                  │ ──► /api/v1/ingestion ──► daemon control
                    │                  │
                    │                  │ ──► /api/v1/decks ──────► generic clients
                    └────────┬─────────┘
                             │
                        PostgreSQL
                       (card_engine)
```

- **cardzerver** — unified backend: flashcards, trivia content, and OpenAI ingestion daemon
- **obo-gen** — Swift CLI that calls Claude API to generate flashcard decks, writes to Postgres
- **obo-ios** / **flasherz-ios** — fetch decks from `/api/v1/flashcards`
- **alities-mobile** — fetches trivia from `/api/v1/trivia/gamedata`, monitors ingestion via `/api/v1/ingestion/status`

## cardzerver API

Port **9810** — FastAPI + asyncpg + httpx.

### Core

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | DB connectivity check |
| GET | `/metrics` | Deck/card/source counts for server-monitor |

### Generic (Layer 1)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/decks` | List decks — filters: `kind`, `age`, `limit`, `offset` |
| GET | `/api/v1/decks/{id}` | Single deck with all cards |

### Flashcard Adapter (Layer 2)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/flashcards` | All flashcard decks with cards |
| GET | `/api/v1/flashcards/{id}` | Single flashcard deck with cards |

### Trivia Adapter (Layer 2)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/trivia/gamedata` | Bulk export in alities Challenge format |
| GET | `/api/v1/trivia/categories` | Categories with counts + SF Symbol pics |

### Ingestion Control (Layer 2)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/ingestion/status` | Daemon state, stats, and config |
| POST | `/api/v1/ingestion/start` | Start the ingestion daemon |
| POST | `/api/v1/ingestion/stop` | Stop the ingestion daemon |
| POST | `/api/v1/ingestion/pause` | Pause (finish current batch, then sleep) |
| POST | `/api/v1/ingestion/resume` | Resume from paused state |
| GET | `/api/v1/ingestion/runs` | Recent source_run audit log |

### Ingestion Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `CE_OPENAI_API_KEY` | (required) | OpenAI API key for trivia generation |
| `CE_INGEST_CYCLE_SECONDS` | 60 | Sleep between ingestion cycles |
| `CE_INGEST_BATCH_SIZE` | 10 | Questions per category per batch |
| `CE_INGEST_AUTO_START` | false | Auto-start daemon on server boot |
| `CE_INGEST_CONCURRENT_BATCHES` | 5 | Parallel OpenAI requests per cycle |

### Commands

```bash
# Install dependencies
cd ~/cardzerver && pip install -e ".[dev]"

# Apply schema
psql -d card_engine -f ~/cardzerver/schema/001_initial.sql

# Run server (dev)
cd ~/cardzerver && python3.11 -m uvicorn server.app:app --port 9810 --reload

# Run server with ingestion enabled
cd ~/cardzerver && CE_OPENAI_API_KEY=sk-... python3.11 -m uvicorn server.app:app --port 9810 --reload

# Test endpoints
curl localhost:9810/health
curl localhost:9810/api/v1/flashcards
curl localhost:9810/api/v1/trivia/gamedata
curl localhost:9810/api/v1/trivia/categories
curl localhost:9810/api/v1/ingestion/status
curl -X POST localhost:9810/api/v1/ingestion/start
curl localhost:9810/api/v1/ingestion/runs
```

## Live URLs

| App | URL |
|-----|-----|
| cardzerver (unified API) | https://bd-cardzerver.fly.dev |
| Nagzerver (API + web app) | https://bd-nagzerver.fly.dev |
| Server Monitor | https://bd-server-monitor.fly.dev |

## Documentation

See [Docs/](Docs/) for specs and architecture docs.

## All Projects

### OBO / cardzerver — Flashcard + trivia platform

| Repo | Description | Port |
|------|-------------|------|
| [obo](https://github.com/billdonner/obo) | **This repo** — specs, docs, orchestration hub | — |
| [cardzerver](https://github.com/billdonner/cardzerver) | Unified FastAPI backend (flashcards + trivia + ingestion) | 9810 |
| [obo-gen](https://github.com/billdonner/obo-gen) | Swift CLI deck generator | — |
| [obo-ios](https://github.com/billdonner/obo-ios) | SwiftUI iOS flashcard app | — |

### Alities — Trivia game platform

| Repo | Description | Port |
|------|-------------|------|
| [alities](https://github.com/billdonner/alities) | Hub — specs, docs, orchestration | — |
| [alities-mobile](https://github.com/billdonner/alities-mobile) | SwiftUI iOS game player | — |
| [alities-studio](https://github.com/billdonner/alities-studio) | React/TypeScript game designer | 9850 |

### Nagz — AI-mediated nagging/reminder app

| Repo | Description | Port |
|------|-------------|------|
| [nagz](https://github.com/billdonner/nagz) | Hub — specs, docs, orchestration | — |
| [nagzerver](https://github.com/billdonner/nagzerver) | Python API server | 9800 |
| [nagz-web](https://github.com/billdonner/nagz-web) | TypeScript/React web app | 5173 |
| [nagz-ios](https://github.com/billdonner/nagz-ios) | SwiftUI iOS app + Apple Intelligence | — |

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

### Retired

| Repo | Replaced By |
|------|-------------|
| [obo-server](https://github.com/billdonner/obo-server) | cardzerver |
| [alities-engine](https://github.com/billdonner/alities-engine) | cardzerver ingestion pipeline |
