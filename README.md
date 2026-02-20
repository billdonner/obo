# OBO

OBO is a flashcard learning app powered by AI-generated decks stored in PostgreSQL and served via a FastAPI backend.

## Architecture

```
obo-gen → Postgres → obo-server → obo-ios
  (CLI)    (storage)    (API)      (consumer)
```

- **obo-gen** calls the Claude API to generate flashcard content, writes decks to Postgres
- **obo-server** reads from Postgres, serves decks via REST API on port 9810
- **obo-ios** fetches decks from obo-server, displays as interactive flashcards

## Documentation

See [Docs/](Docs/) for specs and architecture docs.

## All Projects

### OBO — Flashcard learning app

| Repo | Description | Port |
|------|-------------|------|
| [obo](https://github.com/billdonner/obo) | **This repo** — specs, docs, orchestration hub | — |
| [obo-server](https://github.com/billdonner/obo-server) | Python/FastAPI deck API | 9810 |
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
