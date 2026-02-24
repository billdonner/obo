# OBO Hub — Central Entry Point

OBO is a flashcard learning app powered by AI-generated decks. The backend is **card-engine**, which also serves Alities trivia and runs the ingestion pipeline.

## Ecosystem Layout

| Repo | Path | Purpose |
|------|------|---------|
| **obo** | `~/obo` | Specs, documentation, orchestration hub |
| **card-engine** | `~/card-engine` | Unified FastAPI backend (flashcards + trivia + ingestion) |
| **obo-gen** | `~/obo-gen` | Swift CLI generator (writes decks to Postgres) |
| **obo-ios** | `~/obo-ios` | SwiftUI iOS flashcard app |
| ~~obo-server~~ | `~/obo-server` | Retired — replaced by card-engine |
| ~~alities-engine~~ | `~/alities-engine` | Retired — ingestion pipeline ported to card-engine |

There is NO runnable code in this repo. All executable work happens in the satellite repos.

## card-engine Server

Port **9810** — FastAPI + asyncpg, serves both flashcard and trivia content.

| Endpoint | Description |
|----------|-------------|
| `GET /health` | DB connectivity check |
| `GET /metrics` | Deck/card/source counts for server-monitor |
| `GET /api/v1/decks` | List decks (filters: `kind`, `age`, `limit`, `offset`) |
| `GET /api/v1/decks/{id}` | Single deck with all cards |
| `GET /api/v1/flashcards` | Bulk flashcard decks — obo-ios compatible |
| `GET /api/v1/flashcards/{id}` | Single flashcard deck — obo-ios compatible |
| `GET /api/v1/trivia/gamedata` | Bulk trivia — alities-mobile compatible |
| `GET /api/v1/trivia/categories` | Trivia categories with counts |
| `GET /api/v1/ingestion/status` | Daemon state, stats, and config |
| `POST /api/v1/ingestion/start` | Start the ingestion daemon |
| `POST /api/v1/ingestion/stop` | Stop the ingestion daemon |
| `POST /api/v1/ingestion/pause` | Pause (finish current batch, then sleep) |
| `POST /api/v1/ingestion/resume` | Resume from paused state |
| `GET /api/v1/ingestion/runs` | Recent source_run audit log |

```bash
# Run card-engine
cd ~/card-engine && python3.11 -m uvicorn server.app:app --port 9810 --reload
```

## Ingestion Pipeline

The ingestion daemon generates trivia questions via OpenAI and writes them to Postgres, replacing alities-engine.

| Env Var | Default | Purpose |
|---------|---------|---------|
| `CE_OPENAI_API_KEY` | (required) | OpenAI API key for question generation |
| `CE_INGEST_CYCLE_SECONDS` | 60 | Sleep between ingestion cycles |
| `CE_INGEST_BATCH_SIZE` | 10 | Questions per category per batch |
| `CE_INGEST_AUTO_START` | false | Auto-start daemon on server boot |
| `CE_INGEST_CONCURRENT_BATCHES` | 5 | Parallel OpenAI requests per cycle |

The daemon cycles through 20 canonical trivia categories, generates questions via GPT-4o-mini, deduplicates (signature + Jaccard), and inserts into the `cards` table with `deck.kind='trivia'`. Each cycle is logged as a `source_runs` row.

## Cross-Project Sync

After any schema change in card-engine (`schema/001_initial.sql`) or obo-gen:
1. Update card-engine adapter endpoints if response shape is affected
2. Update obo-ios models in `Models.swift` if fields change

After any API change in card-engine:
1. Update obo-ios `FlashcardStore.swift` and `Models.swift` if affected
2. Update alities-mobile if trivia response shape changes
