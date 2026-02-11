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
                selectedVoiceIdentifier: $selectedVoiceIdentifier,
                availableVoices: availableVoices,
                currentIndexDisplay: currentIndexDisplay,
                currentDeckCount: currentDeck.cards.count,
                onGroupChanged: handleGroupChange,
                onDeckChanged: handleDeckChange
            )

            Spacer(minLength: 0)

            if let card = currentCard {
                FlashcardView(card: card, isShowingAnswer: isShowingAnswer)
                    .onTapGesture {
                        toggleCardFace()
                    }
            } else {
                Text("No cards available.")
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            FlashcardControlsView(
                isShowingAnswer: isShowingAnswer,
                canNavigate: !currentDeck.cards.isEmpty,
                canSpeak: currentCard != nil,
                onPrevious: moveToPrevious,
                onToggle: toggleCardFace,
                onSpeakQuestion: speakCurrentQuestion,
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
        }
        .onChange(of: store.groups.map(\.id)) { _, _ in
            clampSelection()
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
    }

    private func handleDeckChange() {
        currentIndex = 0
        isShowingAnswer = false
    }

    private func moveToPrevious() {
        let cards = currentDeck.cards
        guard !cards.isEmpty else { return }
        isShowingAnswer = false
        currentIndex = (currentIndex - 1 + cards.count) % cards.count
        speakCurrentQuestion()
    }

    private func moveToNext() {
        let cards = currentDeck.cards
        guard !cards.isEmpty else { return }
        isShowingAnswer = false
        currentIndex = (currentIndex + 1) % cards.count
        speakCurrentQuestion()
    }

    private func toggleCardFace() {
        let willShowAnswer = !isShowingAnswer
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isShowingAnswer = willShowAnswer
        }
        if willShowAnswer {
            speakCurrentAnswer()
        } else {
            speakCurrentQuestion()
        }
    }

    private func speakCurrentAnswer() {
        guard let card = currentCard else { return }
        let utterance = AVSpeechUtterance(string: card.answer)
        utterance.rate = kidSpeechRate
        utterance.pitchMultiplier = kidPitch
        utterance.preUtteranceDelay = kidPreDelay
        utterance.postUtteranceDelay = kidPostDelay
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer.speak(utterance)
    }

    private func speakCurrentQuestion() {
        guard let card = currentCard else { return }
        let utterance = AVSpeechUtterance(string: card.question)
        utterance.rate = kidSpeechRate
        utterance.pitchMultiplier = kidPitch
        utterance.preUtteranceDelay = kidPreDelay
        utterance.postUtteranceDelay = kidPostDelay
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer.speak(utterance)
    }
}

#Preview("Flashcards") {
    ContentView()
}
