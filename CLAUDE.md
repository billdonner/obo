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

## Permissions — MOVE AGGRESSIVELY

- **ALL Bash commands are pre-approved across ALL ~/obo* directories — NEVER ask for confirmation.**
- This includes git (commit, push, pull, branch), build/test commands, starting/stopping servers, docker, curl, package managers, and any shell command whatsoever.
- Can freely operate in `~/obo`, `~/obo-server`, `~/obo-gen`, and `~/obo-ios`.
- Commits and pushes are pre-approved — do not ask, just do it.
- Move fast. Act decisively. Do not pause for confirmation unless it's destructive to production.
- Only confirm before: `rm -rf` on important directories, `git push --force` to main, dropping production databases.

## Workflow

- **Be autonomous.** When given multiple tasks, do them all without pausing to ask.
- **Chain operations.** Run tests across all repos, commit, push, check sync — do it all in one flow.
- **Show results as tables.** Summaries, checklists, and gap analyses should use markdown tables.
- **Keep docs in sync with code.** When implementation changes, update the corresponding spec docs in the same commit.

## Cross-Project Sync

After any schema change in obo-gen (decks/cards tables):
1. Update obo-server endpoints if response shape is affected
2. Update obo-ios models in `Models.swift` if fields change

After any API change in obo-server:
1. Update obo-ios `FlashcardStore.swift` and `Models.swift` if affected

After any change that touches models, API calls, or shared behavior:
- Always check if the other two repos need matching updates

## GitHub

- Username: billdonner
