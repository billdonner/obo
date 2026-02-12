# obo

Flashcard app for kids with bundled sample decks, speech playback, and family profiles.

## Overview
- Browse categories and topics, then review cards one at a time.
- Tap “Start Deck”; the first question is spoken automatically if speech is enabled.
- Tap a card to flip between question and answer; tap answers to move to the next card.
- Replay question/answer audio from the card corner.
- Use Family Hub to manage profiles, deck access, and per‑profile preferences.

## Features
- **Bundled sample decks** included in the app bundle.
- **Family profiles** with per‑profile category/deck selection.
- **Speech playback** with selectable voice per profile.
- **Family Hub** to manage deck access, deck ages, and UI preferences.
- **Recommended decks** row and **progress bar**.
- **User title** personalization ("Flashcards for <Name>").

## Data Sources & Loading Order
1. `Documents/decks.txt` (if present)
2. Bundled sample decks (`obo/SampleDecks/*.txt`)
3. Built‑in fallback samples

The current source is shown in Settings.

## Sample Deck File Format
Each deck file is plain text with a title and 20 Q/A lines:

```
Title: <Deck Title>

Q: <Question> | A: <Answer>
```

## Speech Behavior
- **Auto‑speak**: when a new deck starts, the first question is spoken once you tap “Start Deck”.
- **Replay**: use the speaker icon on the card corner to replay question or answer.
- **One‑shot**: replay works even if speech is disabled, but appears muted.

## Project Structure
- `obo/ContentView.swift` — main screen and speech logic
- `obo/ContentView+ProfilePreferences.swift` — profile selection and UI preference helpers
- `obo/DeckSelectionView.swift` — header + topic picker + recommended row + progress
- `obo/FlashcardView.swift` — card UI + replay buttons + “Start Deck”
- `obo/FlashcardControlsView.swift` — previous/next controls
- `obo/FlashcardStore.swift` — loading + parsing decks
- `obo/SettingsView.swift` — settings UI
- `obo/ParentControlsView.swift` — Family Hub + caregiver tools
- `obo/SampleDecks/` — bundled sample decks

## Architecture (High Level)
```mermaid
flowchart TB
    A[FlashcardStore] --> B[ContentView]
    B --> C[DeckSelectionView]
    B --> D[FlashcardView]
    B --> E[FlashcardControlsView]
    B --> F[SettingsView]
    F --> G[ParentControlsView]
    G --> H[FamilyStore]

    subgraph Data
        G[Documents/decks.txt]
        H[Bundled SampleDecks/*.txt]
        I[Built-in Samples]
    end

    G --> A
    H --> A
    I --> A

    subgraph Speech
        J[AVSpeechSynthesizer]
    end

    B --> J
    F --> B
```

## Build & Run
Open the Xcode project and build the `obo` target.

## Notes
- If you add a new deck file, keep 20 Q/A lines for consistency.
- Category grouping is derived from deck titles in `FlashcardStore`.
