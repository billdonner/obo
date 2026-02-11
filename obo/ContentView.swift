//
//  ContentView.swift
//  obo
//
//  Created by bill donner on 2/8/26.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var store = FlashcardStore()
    @State private var selectedGroupIndex: Int = 0
    @State private var selectedDeckIndex: Int = 0
    @State private var currentIndex: Int = 0
    @State private var isShowingAnswer: Bool = false
    @AppStorage("selectedVoiceIdentifier") private var selectedVoiceIdentifier: String = ""
    @AppStorage("isSpeechEnabled") private var isSpeechEnabled: Bool = true
    @AppStorage("userName") private var userName: String = ""
    @State private var isShowingSettings: Bool = false
    @State private var isAwaitingStart: Bool = true

    private let speechSynthesizer = AVSpeechSynthesizer()
    private let kidSpeechRate: Float = 0.45
    private let kidPitch: Float = 0.95
    private let kidPreDelay: Double = 0.05
    private let kidPostDelay: Double = 0.12

    var body: some View {
        VStack(spacing: 24) {
            DeckSelectionView(
                groups: store.groups,
                selectedGroupIndex: $selectedGroupIndex,
                selectedDeckIndex: $selectedDeckIndex,
                userName: userName,
                currentIndexDisplay: currentIndexDisplay,
                currentDeckCount: currentDeck.cards.count,
                onOpenSettings: { isShowingSettings = true },
                onDeckChanged: handleDeckChange
            )

            Spacer(minLength: 0)

            if let card = currentCard {
                if isAwaitingStart {
                    BeginCardView(deckTitle: currentDeck.title)
                        .onTapGesture {
                            isAwaitingStart = false
                            speakCurrentQuestionIfEnabled()
                        }
                } else {
                    FlashcardView(
                        card: card,
                        isShowingAnswer: isShowingAnswer,
                        canSpeakAnswer: currentCard != nil,
                        isSpeechEnabled: isSpeechEnabled,
                        onSpeakAnswer: speakCurrentAnswerOneShot,
                        canSpeakQuestion: currentCard != nil,
                        onSpeakQuestion: speakCurrentQuestionOneShot
                    )
                        .onTapGesture {
                            toggleCardFace()
                        }
                }
            } else {
                Text("No cards available.")
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            FlashcardControlsView(
                canNavigate: !currentDeck.cards.isEmpty,
                onPrevious: moveToPrevious,
                onNext: moveToNext
            )
        }
        .padding(24)
        .onAppear {
            store.load()
            if selectedVoiceIdentifier.isEmpty {
                selectedVoiceIdentifier = preferredVoice?.identifier ?? ""
            }
            clampSelection()
            isAwaitingStart = true
        }
        .onChange(of: store.groups.map(\.id)) { _, _ in
            clampSelection()
            isAwaitingStart = true
        }
        .onChange(of: currentIndex) { _, _ in
            speakCurrentQuestionIfEnabled()
        }
        .onChange(of: selectedVoiceIdentifier) { _, _ in
            speakVoiceSelection()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(
                groups: store.groups,
                selectedGroupIndex: $selectedGroupIndex,
                selectedVoiceIdentifier: $selectedVoiceIdentifier,
                availableVoices: availableVoices,
                isSpeechEnabled: $isSpeechEnabled,
                userName: $userName,
                sourceDescription: store.sourceDescription,
                onGroupChanged: handleGroupChange
            )
        }
    }

    private var currentIndexDisplay: Int {
        currentDeck.cards.isEmpty ? 0 : (currentIndex + 1)
    }

    private var availableVoices: [AVSpeechSynthesisVoice] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.name < $1.name }
        return voices
    }

    private var preferredVoice: AVSpeechSynthesisVoice? {
        availableVoices.first { $0.language == "en-US" } ?? availableVoices.first
    }

    private var selectedVoice: AVSpeechSynthesisVoice? {
        availableVoices.first { $0.identifier == selectedVoiceIdentifier } ?? preferredVoice
    }

    private var currentGroup: TopicGroup {
        guard !store.groups.isEmpty,
              selectedGroupIndex >= 0,
              selectedGroupIndex < store.groups.count else {
            return TopicGroup(title: "Empty", decks: [])
        }
        return store.groups[selectedGroupIndex]
    }

    private var currentDeck: Deck {
        let decks = currentGroup.decks
        guard !decks.isEmpty,
              selectedDeckIndex >= 0,
              selectedDeckIndex < decks.count else {
            return Deck(title: "Empty", cards: [])
        }
        return decks[selectedDeckIndex]
    }

    private var currentCard: Flashcard? {
        let cards = currentDeck.cards
        guard !cards.isEmpty,
              currentIndex >= 0,
              currentIndex < cards.count else {
            return nil
        }
        return cards[currentIndex]
    }

    private func clampSelection() {
        if store.groups.isEmpty {
            selectedGroupIndex = 0
            selectedDeckIndex = 0
            currentIndex = 0
            isShowingAnswer = false
            return
        }

        selectedGroupIndex = min(max(selectedGroupIndex, 0), store.groups.count - 1)
        let decks = store.groups[selectedGroupIndex].decks
        if decks.isEmpty {
            selectedDeckIndex = 0
            currentIndex = 0
            isShowingAnswer = false
            return
        }

        selectedDeckIndex = min(max(selectedDeckIndex, 0), decks.count - 1)
        currentIndex = min(max(currentIndex, 0), max(decks[selectedDeckIndex].cards.count - 1, 0))
        isShowingAnswer = false
    }

    private func handleGroupChange() {
        selectedDeckIndex = 0
        currentIndex = 0
        isShowingAnswer = false
        isAwaitingStart = true
    }

    private func handleDeckChange() {
        currentIndex = 0
        isShowingAnswer = false
        isAwaitingStart = true
    }

    private func moveToPrevious() {
        let cards = currentDeck.cards
        guard !cards.isEmpty else { return }
        isShowingAnswer = false
        currentIndex = (currentIndex - 1 + cards.count) % cards.count
    }

    private func moveToNext() {
        let cards = currentDeck.cards
        guard !cards.isEmpty else { return }
        isShowingAnswer = false
        currentIndex = (currentIndex + 1) % cards.count
    }

    private func toggleCardFace() {
        let willShowAnswer = !isShowingAnswer
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isShowingAnswer = willShowAnswer
        }
        if willShowAnswer {
            speakCurrentAnswer(force: false)
        } else {
            speakCurrentQuestionIfEnabled()
        }
    }

    private func speakCurrentAnswer(force: Bool) {
        guard (isSpeechEnabled || force), let card = currentCard else { return }
        speak(text: card.answer)
    }

    private func speakCurrentQuestion(force: Bool) {
        guard (isSpeechEnabled || force), !isAwaitingStart, let card = currentCard else { return }
        speak(text: card.question)
    }

    private func speakCurrentQuestionIfEnabled() {
        guard isSpeechEnabled, !isShowingAnswer, !isAwaitingStart else { return }
        speakCurrentQuestion(force: false)
    }

    private func speakCurrentAnswerOneShot() {
        speakCurrentAnswer(force: true)
    }

    private func speakCurrentQuestionOneShot() {
        speakCurrentQuestion(force: true)
    }

    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = kidSpeechRate
        utterance.pitchMultiplier = kidPitch
        utterance.preUtteranceDelay = kidPreDelay
        utterance.postUtteranceDelay = kidPostDelay
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer.speak(utterance)
    }

    private func speakVoiceSelection() {
        let voiceName = selectedVoice?.name ?? "Voice"
        speak(text: "\(voiceName), at your service.")
    }
}

#Preview("Flashcards") {
    ContentView()
}
