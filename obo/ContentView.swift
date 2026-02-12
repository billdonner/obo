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
    @State private var familyStore = FamilyStore()
    @State private var selectedGroupIndex: Int = 0
    @State private var selectedDeckIndex: Int = 0
    @State private var currentIndex: Int = 0
    @State private var isShowingAnswer: Bool = false
    @AppStorage("selectedVoiceIdentifier") private var selectedVoiceIdentifier: String = ""
    @AppStorage("isSpeechEnabled") private var isSpeechEnabled: Bool = false
    @State private var isShowingSettings: Bool = false
    @State private var isAwaitingStart: Bool = true
    @State private var isShowingLaunch: Bool = true

    private let speechSynthesizer = AVSpeechSynthesizer()
    private let kidSpeechRate: Float = 0.45
    private let kidPitch: Float = 0.95
    private let kidPreDelay: Double = 0
    private let kidPostDelay: Double = 0

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                DeckSelectionView(
                    groups: visibleGroups,
                    selectedGroupIndex: $selectedGroupIndex,
                    selectedDeckIndex: $selectedDeckIndex,
                    userName: familyStore.currentProfile?.name ?? "",
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
            .opacity(isShowingLaunch ? 0 : 1)
            .animation(.easeOut(duration: 1.1), value: isShowingLaunch)

            if isShowingLaunch {
                LaunchOverlayView()
                    .transition(.opacity)
            }
        }
        .padding(24)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            store.load()
            familyStore.load()
            if selectedVoiceIdentifier.isEmpty {
                selectedVoiceIdentifier = preferredVoice?.identifier ?? ""
            }
            clampSelection()
            isAwaitingStart = true
            showLaunchIfNeeded()
        }
        .onChange(of: store.groups.map(\.id)) { _, _ in
            clampSelection()
            isAwaitingStart = true
        }
        .onChange(of: familyStore.changeToken) { _, _ in
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
                visibleGroups: visibleGroups,
                selectedGroupIndex: $selectedGroupIndex,
                selectedVoiceIdentifier: $selectedVoiceIdentifier,
                availableVoices: availableVoices,
                isSpeechEnabled: $isSpeechEnabled,
                sourceDescription: store.sourceDescription,
                familyStore: familyStore
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

    private var visibleGroups: [TopicGroup] {
        guard let profile = familyStore.currentProfile else {
            return store.groups
        }

        let allowedDecks = Set(profile.allowedDeckIDs)
        let hasAllowList = !allowedDecks.isEmpty

        var filteredGroups: [TopicGroup] = []
        for group in store.groups {
            let decks = group.decks.filter { deck in
                if hasAllowList && !allowedDecks.contains(deck.id) {
                    return false
                }
                return familyStore.matchesAge(deckID: deck.id, for: profile)
            }

            if !decks.isEmpty {
                filteredGroups.append(TopicGroup(title: group.title, decks: decks))
            }
        }

        return filteredGroups
    }

    private var preferredVoice: AVSpeechSynthesisVoice? {
        availableVoices.first { $0.language == "en-US" } ?? availableVoices.first
    }

    private var selectedVoice: AVSpeechSynthesisVoice? {
        availableVoices.first { $0.identifier == selectedVoiceIdentifier } ?? preferredVoice
    }

    private var currentGroup: TopicGroup {
        guard !visibleGroups.isEmpty,
              selectedGroupIndex >= 0,
              selectedGroupIndex < visibleGroups.count else {
            return TopicGroup(title: "Empty", decks: [])
        }
        return visibleGroups[selectedGroupIndex]
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
        if visibleGroups.isEmpty {
            selectedGroupIndex = 0
            selectedDeckIndex = 0
            currentIndex = 0
            isShowingAnswer = false
            return
        }

        selectedGroupIndex = min(max(selectedGroupIndex, 0), visibleGroups.count - 1)
        let decks = visibleGroups[selectedGroupIndex].decks
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
        try? session.setActive(true)
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                speakNow(text: trimmed)
            }
        } else {
            speakNow(text: trimmed)
        }
    }

    private func speakNow(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = kidSpeechRate
        utterance.pitchMultiplier = kidPitch
        utterance.preUtteranceDelay = kidPreDelay
        utterance.postUtteranceDelay = kidPostDelay
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }

    private func speakVoiceSelection() {
        let voiceName = selectedVoice?.name ?? "Voice"
        speak(text: "\(voiceName), at your service.")
    }

    private func showLaunchIfNeeded() {
        guard isShowingLaunch else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 1.2)) {
                isShowingLaunch = false
            }
        }
    }
}

private struct LaunchOverlayView: View {
    var body: some View {
        Image("LaunchIcon")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

#Preview("Flashcards") {
    ContentView()
}
