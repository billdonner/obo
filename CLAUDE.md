# OBO Hub — Central Entry Point

OBO is a flashcard learning app powered by AI-generated decks. The backend is **cardzerver**, which also serves Alities trivia and runs the ingestion pipeline.

## Ecosystem Layout

| Repo | Path | Purpose |
|------|------|---------|
| **obo** | `~/obo` | Specs, documentation, orchestration hub |
| **cardzerver** | `~/cardzerver` | Unified FastAPI backend (flashcards + trivia + ingestion) |
| **obo-gen** | `~/obo-gen` | Swift CLI generator (writes decks to Postgres) |
| **obo-ios** | `~/obo-ios` | SwiftUI iOS flashcard app |
| **cardz-studio** | `~/cardz-studio` | React content management studio (port 9850) |
| **cardz-studio-ios** | `~/cardz-studio-ios` | SwiftUI iOS content management app |
| **qross** | `~/qross` | SwiftUI iOS grid trivia game |
| **qross-web** | `~/qross-web` | React marketing website for Qross (port 9870) |
| **family-ios** | `~/family-ios` | SwiftUI iOS family tree app (v2: GRDB, Canvas, GEDCOM) |
| **family-kids** | `~/family-kids` | SwiftUI iOS kids flashcard app (cardzerver client) |
| ~~obo-server~~ | `~/obo-server` | Retired — replaced by cardzerver |
| ~~alities-engine~~ | `~/alities-engine` | Retired — ingestion pipeline ported to cardzerver |
| ~~alities-studio~~ | `~/alities-studio` | Retired — replaced by cardz-studio |

There is NO runnable code in this repo. All executable work happens in the satellite repos.

## cardzerver Server

Port **9810** — FastAPI + asyncpg, serves both flashcard and trivia content.

| Endpoint | Description |
|----------|-------------|
| `GET /health` | DB connectivity check |
| `GET /metrics` | 24+ metrics: system, content, ingestion, trivia/Qross, DB health |
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

### Family Tree API — device-based access control

All family endpoints require `?player_id=<uuid>`. Families are private — only members can see or edit them.

| Endpoint | Access | Description |
|----------|--------|-------------|
| `POST /api/v1/family` | open | Create family (`{name, player_id}`) — creator becomes owner |
| `GET /api/v1/family?player_id=` | open | List player's families |
| `GET /api/v1/family/{id}?player_id=` | member | Full tree |
| `DELETE /api/v1/family/{id}?player_id=` | owner | Delete family |
| `POST /api/v1/family/{id}/people?player_id=` | member | Add person |
| `PATCH /api/v1/family/{id}/people/{pid}?player_id=` | member | Update person |
| `DELETE /api/v1/family/{id}/people/{pid}?player_id=` | member | Delete person |
| `POST /api/v1/family/{id}/relationships?player_id=` | member | Add relationship |
| `DELETE /api/v1/family/{id}/relationships/{rid}?player_id=` | member | Delete relationship |
| `POST /api/v1/family/join` | open | Join via invite code (`{player_id, invite_code}`) |
| `POST /api/v1/family/{id}/invite?player_id=` | owner | Create 6-char invite code |
| `GET /api/v1/family/{id}/invite?player_id=` | owner | List invite codes |
| `DELETE /api/v1/family/{id}/invite/{iid}?player_id=` | owner | Revoke invite |
| `GET /api/v1/family/{id}/members?player_id=` | member | List members + roles |
| `DELETE /api/v1/family/{id}/members/{pid}?player_id=` | owner | Remove member |
| `GET /api/v1/family/{id}/open_items?player_id=` | member | Missing field report |
| `POST /api/v1/family/{id}/chat?player_id=` | member | Chat builder (LLM applies patches) |
| `GET /api/v1/family/{id}/chat/history?player_id=` | member | Chat history |
| `POST /api/v1/family/{id}/generate/{player_id}?player_id=` | member | Generate decks for a player |
| `GET /api/v1/family/{id}/deck/{player_id}?player_id=` | member | List generated decks |
| `GET /api/v1/family/{id}/decks/{deck_id}?player_id=` | member | List cards in a generated deck |
| `DELETE /api/v1/family/{id}/decks/{deck_id}/cards/{cid}?player_id=` | member | Remove card + add to exclusion list |
| `GET /api/v1/family/{id}/exclusions?player_id=` | member | List excluded questions |
| `DELETE /api/v1/family/{id}/exclusions/{eid}?player_id=` | member | Restore excluded question |

```bash
# Run cardzerver
cd ~/cardzerver && python3.11 -m uvicorn server.app:app --port 9810 --reload
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

Embedded React SPA served at `/studio` from cardzerver. In production: `https://bd-cardzerver.fly.dev/studio`.

```bash
# Run locally (requires cardzerver running on 9810)
cd ~/cardz-studio && npm run dev
# Build (embedded in deploy)
cd ~/cardz-studio && npm run build
```

**Player identity:** On first load, the studio generates a `device_id` UUID, stores it in localStorage, calls `POST /api/v1/players` to get a `player_id`, and stores that too. All family API calls include `?player_id=` automatically.

| Route | Page | Purpose |
|-------|------|---------|
| `/` | Dashboard | Deck counts, engine status, recent decks |
| `/decks` | DecksList | Browse/filter/create decks |
| `/decks/:id` | DeckEditor | Edit deck metadata, manage cards |
| `/ingestion` | Ingestion | Daemon control + run history |
| `/search` | Search | Full-text search across cards |
| `/family` | FamilyList | List player's families; create or join via invite code |
| `/family/:id` | FamilyTree | Full tree editor + deck editor + access/invite panel |
| `/family/:id/chat` | FamilyChat | LLM chat builder |

**Family tree features in the studio:**
- **Access panel** (sidebar): shows role (Owner/Member), member count, invite codes with Copy/Revoke buttons, "+ New Invite Code"
- **Family Decks section** (main column): inline card editor — expand any deck, click Remove on any card to delete it and add the question to the exclusion list; excluded questions are skipped on regeneration; Restore button to bring them back

Extensible form registry: add a new card kind by creating one form component in `src/components/forms/` and registering it in `index.ts`.

## cardz-studio-ios

SwiftUI iOS app — full CRUD client for cardzerver studio endpoints.

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

- API base: `https://bd-cardzerver.fly.dev`
- Bundle ID: `com.billdonner.cardz-studio`
- Onboarding: 4-page flow shown on first launch
- Kind-specific card editors: flashcard, trivia, newsquiz

## Qross

SwiftUI iOS grid trivia game — consumes trivia content from cardzerver.

```bash
# Build and run
cd ~/qross && xcodegen generate
xcodebuild -scheme Qross -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build
```

- API base: `https://bd-cardzerver.fly.dev` (uses `/api/v1/trivia/gamedata`)
- Bundle ID: `com.qross.app`
- Version: 0.2, Build: 26
- Onboarding: 6-page flow (includes AI Move Advisor page)
- Home screen: minimal cover with presets, topic picker (2+ required), gear icon for Settings sheet
- AI Move Advisor: smart scoring with risk badges (Safe/Caution/Risky), dead-end detection
- Game variants: Face Up, Face Down, Blind
- Board sizes: 4×4 through 8×8

Qross-specific metrics are exposed via cardzerver `/metrics`:
- `trivia_categories` — published trivia topic count
- `trivia_questions` — total published trivia questions
- `trivia_avg_per_cat` — average questions per topic
- `trivia_smallest` — smallest category (warns below 50)

## qross-web

Port **9870** — React 19 + TypeScript + Vite marketing website.

```bash
cd ~/qross-web && npm run dev
```

| Route | Page | Purpose |
|-------|------|---------|
| `/` | Landing | Hero + features grid + App Store CTA |
| `/how-to-play` | HowToPlay | Rules, scoring, hints, variants |
| `/download` | Download | App Store link + TestFlight + QR |

## family-ios (v2)

Visual family tree app — local-first GRDB + Canvas tree + relationship flashcards + GEDCOM export.

```bash
cd ~/family-ios && xcodegen generate
xcodebuild -scheme FamilyTree -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build
xcodebuild -scheme FamilyTreeTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' test
```

- **Data:** GRDB local SQLite + optional cardzerver sync
- **Layout:** iPad 3-panel (Tree+Flashcards / Chat) / iPhone 3-tab
- **Tree:** Interactive Canvas with Reingold-Tilford layout
- **Flashcards:** Auto-generated from relationship graph
- **Export:** GEDCOM 5.5.1 with validation
- Bundle ID: `com.billdonner.family-tree`
- Version: 2.0, Build: 1
- iOS 26.0, Swift 6.0
- Three-gate launch: onboarding -> family setup -> adaptive root

## family-kids

Kids flashcard app — pure cardzerver REST client.

```bash
cd ~/family-kids && xcodegen generate
xcodebuild -scheme FamilyKids -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build
```

- Flow: onboarding -> family ID -> player select -> deck list -> card play
- Bundle ID: `com.billdonner.family-kids`
- Version: 1.0, Build: 1
- iOS 17.0, Swift 6.0

## Cross-Project Sync

After any schema change in cardzerver (`schema/`) or obo-gen:
1. Update cardzerver adapter endpoints if response shape is affected
2. Update obo-ios models in `Models.swift` if flashcard fields change

After any API change in cardzerver:
1. Update obo-ios `FlashcardStore.swift` and `Models.swift` if `/api/v1/flashcards` is affected
2. Update alities-mobile if trivia response shape changes
3. Update qross if `/api/v1/trivia/gamedata` response shape changes
4. Update cardz-studio-ios `Models.swift` and `APIClient.swift` if studio endpoints change
5. Update cardz-studio web `types.ts` and `api.ts` if studio endpoints change
6. Update family-ios `SyncModels.swift` and `SyncService.swift` if family endpoints change
7. Update family-kids `KidsModels.swift` and `KidsAPIClient.swift` if family endpoints change

After any family tree schema change (`009_family_access.sql`, `010_family_deck_editing.sql`):
1. Update cardz-studio `types.ts` + `api.ts` for new response fields
2. Update family-ios if `FamilyMember`, `FamilyInvite`, or deck editing models change
3. Update family-kids if deck exclusion behavior affects served cards

## Live URLs

| Service | URL |
|---------|-----|
| cardzerver API | https://bd-cardzerver.fly.dev |
| API docs (Swagger) | https://bd-cardzerver.fly.dev/docs |
| cardz-studio (embedded) | https://bd-cardzerver.fly.dev/studio |
| cardz-studio (local) | http://localhost:9810/studio |
| server-monitor (Fly.io) | https://bd-server-monitor.fly.dev |
| server-monitor (local) | http://localhost:9860 |
