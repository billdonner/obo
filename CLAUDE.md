# OBO Hub — Central Entry Point

OBO is a flashcard learning app powered by AI-generated decks.

## Ecosystem Layout

| Repo | Path | Purpose |
|------|------|---------|
| **obo** | `~/obo` | Specs, documentation, orchestration hub |
| **obo-server** | `~/obo-server` | Python/FastAPI deck API server (port 9810) |
| **obo-gen** | `~/obo-gen` | Swift CLI generator (writes decks to Postgres) |
| **obo-ios** | `~/obo-ios` | SwiftUI iOS flashcard app |

There is NO runnable code in this repo. All executable work happens in the satellite repos.

## Cross-Project Sync

After any schema change in obo-gen (decks/cards tables):
1. Update obo-server endpoints if response shape is affected
2. Update obo-ios models in `Models.swift` if fields change

After any API change in obo-server:
1. Update obo-ios `FlashcardStore.swift` and `Models.swift` if affected
