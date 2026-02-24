# OBO Hub — Central Entry Point

OBO is a flashcard learning app powered by AI-generated decks. The backend is being unified into **card-engine**, which also serves Alities trivia from the same database.

## Ecosystem Layout

| Repo | Path | Purpose |
|------|------|---------|
| **obo** | `~/obo` | Specs, documentation, orchestration hub |
| **card-engine** | `~/card-engine` | Unified FastAPI backend (replaces obo-server + alities-engine HTTP) |
| **obo-server** | `~/obo-server` | Legacy flashcard API (being replaced by card-engine) |
| **obo-gen** | `~/obo-gen` | Swift CLI generator (writes decks to Postgres) |
| **obo-ios** | `~/obo-ios` | SwiftUI iOS flashcard app |

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

```bash
# Run card-engine
cd ~/card-engine && python3.11 -m uvicorn server.app:app --port 9810 --reload
```

## Cross-Project Sync

After any schema change in card-engine (`schema/001_initial.sql`) or obo-gen:
1. Update card-engine adapter endpoints if response shape is affected
2. Update obo-ios models in `Models.swift` if fields change

After any API change in card-engine:
1. Update obo-ios `FlashcardStore.swift` and `Models.swift` if affected
2. Update alities-mobile if trivia response shape changes
