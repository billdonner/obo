# OBO

OBO is a flashcard learning app powered by AI-generated decks stored in PostgreSQL and served via a FastAPI backend.

## Ecosystem

| Repo | Stack | Purpose |
|------|-------|---------|
| [obo](https://github.com/billdonner/obo) | Docs | Specs, documentation, orchestration hub |
| [obo-server](https://github.com/billdonner/obo-server) | Python / FastAPI | Deck API server (reads from Postgres, port 9810) |
| [obo-gen](https://github.com/billdonner/obo-gen) | Swift / SPM | CLI generator (writes decks to Postgres via Claude API) |
| [obo-ios](https://github.com/billdonner/obo-ios) | SwiftUI / iOS | Mobile flashcard app |

## Documentation

See [Docs/](Docs/) for specs and architecture docs.

## Architecture

```
obo-gen → Postgres → obo-server → obo-ios
  (CLI)    (storage)    (API)      (consumer)
```

- **obo-gen** calls the Claude API to generate flashcard content, writes decks to Postgres
- **obo-server** reads from Postgres, serves decks via REST API on port 9810
- **obo-ios** fetches decks from obo-server, displays as interactive flashcards
