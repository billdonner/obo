# OBO Hub — Central Entry Point

OBO is a flashcard learning app powered by AI-generated decks. The backend is **card-engine**, which also serves Alities trivia and runs the ingestion pipeline.

## Ecosystem Layout

| Repo | Path | Purpose |
|------|------|---------|
| **obo** | `~/obo` | Specs, documentation, orchestration hub |
| **card-engine** | `~/card-engine` | Unified FastAPI backend (flashcards + trivia + ingestion) |
| **obo-gen** | `~/obo-gen` | Swift CLI generator (writes decks to Postgres) |
| **obo-ios** | `~/obo-ios` | SwiftUI iOS flashcard app |
| **cardz-studio** | `~/cardz-studio` | React content management studio (port 9850) |
| **cardz-studio-ios** | `~/cardz-studio-ios` | SwiftUI iOS content management app |
| **qross** | `~/qross` | SwiftUI iOS grid trivia game |
| **qross-web** | `~/qross-web` | React marketing website for Qross (port 9870) |
| ~~obo-server~~ | `~/obo-server` | Retired — replaced by card-engine |
| ~~alities-engine~~ | `~/alities-engine` | Retired — ingestion pipeline ported to card-engine |
| ~~alities-studio~~ | `~/alities-studio` | Retired — replaced by cardz-studio |

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
| `POST /api/v1/studio/decks` | Create deck (title, kind, properties) |
| `PATCH /api/v1/studio/decks/{id}` | Update deck metadata |
| `DELETE /api/v1/studio/decks/{id}` | Delete deck + cascade cards |
| `POST /api/v1/studio/decks/{id}/cards` | Create card in deck |
| `PATCH /api/v1/studio/decks/{id}/cards/{cid}` | Update card |
| `DELETE /api/v1/studio/decks/{id}/cards/{cid}` | Delete card |
| `POST /api/v1/studio/decks/{id}/cards/reorder` | Batch reorder cards |
| `GET /api/v1/studio/search?q=` | Full-text search across cards |

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

## cardz-studio

Port **9850** — React 19 + TypeScript + Vite content management frontend.

```bash
# Run cardz-studio (requires card-engine running on 9810)
cd ~/cardz-studio && npm run dev
```

| Route | Page | Purpose |
|-------|------|---------|
| `/` | Dashboard | Deck counts, engine status, recent decks |
| `/decks` | DecksList | Browse/filter/create decks |
| `/decks/:id` | DeckEditor | Edit deck metadata, manage cards |
| `/decks/:id/cards/new` | CardEditor | Create card (kind-specific form) |
| `/decks/:id/cards/:cardId` | CardEditor | Edit card |
| `/ingestion` | Ingestion | Daemon control + run history |
| `/search` | Search | Full-text search across cards |
| `/about` | About | Marketing landing page (no sidebar) |
| `/testflight` | TestFlight | iOS app download page (no sidebar) |
| `/help` | Help | Usage documentation (no sidebar) |

Extensible form registry: add a new card kind by creating one form component in `src/components/forms/` and registering it in `index.ts`.

## cardz-studio-ios

SwiftUI iOS app — full CRUD client for card-engine studio endpoints.

```bash
# Build and run
cd ~/cardz-studio-ios && xcodegen generate
xcodebuild -scheme CardzStudio -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build
```

| Tab | View | Purpose |
|-----|------|---------|
| Dashboard | DashboardView | Stats, recent decks, health status |
| Decks | DecksListView | Browse/filter/create, tap to edit |
| Search | SearchView | Debounced full-text search |
| Ingestion | IngestionView | Daemon control + run history |
| Help | HelpView | Usage instructions, links, reset onboarding |

- API base: `https://bd-card-engine.fly.dev`
- Bundle ID: `com.billdonner.cardz-studio`
- Onboarding: 4-page flow shown on first launch
- Kind-specific card editors: flashcard, trivia, newsquiz

## Cross-Project Sync

After any schema change in card-engine (`schema/001_initial.sql`) or obo-gen:
1. Update card-engine adapter endpoints if response shape is affected
2. Update obo-ios models in `Models.swift` if fields change

After any API change in card-engine:
1. Update obo-ios `FlashcardStore.swift` and `Models.swift` if affected
2. Update alities-mobile if trivia response shape changes
3. Update cardz-studio-ios `Models.swift` and `APIClient.swift` if studio endpoints change
4. Update cardz-studio web `types.ts` and `api.ts` if studio endpoints change

## Live URLs

| Service | URL |
|---------|-----|
| card-engine (Fly.io) | https://bd-card-engine.fly.dev |
| API docs | https://bd-card-engine.fly.dev/docs |
| cardz-studio (local) | http://localhost:9850 |
| cardz-studio About | http://localhost:9850/about |
| cardz-studio Help | http://localhost:9850/help |
| qross-web (local) | http://localhost:9870 |
| qross-web (Fly.io) | https://bd-qross-web.fly.dev |
