//
//  ContentView.swift
//  obo
//
//  Created by bill donner on 2/8/26.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State var store = FlashcardStore()
    @State var familyStore = FamilyStore()
    @State var selectedGroupIndex: Int = 0
    @State var selectedDeckIndex: Int = 0
    @State var currentIndex: Int = 0
    @State var isShowingAnswer: Bool = false
    @AppStorage("selectedVoiceIdentifier") var selectedVoiceIdentifier: String = ""
    @AppStorage("isSpeechEnabled") var isSpeechEnabled: Bool = false
    @State var isShowingSettings: Bool = false
    @State var isAwaitingStart: Bool = true
    @State var isShowingLaunch: Bool = true
    @State var isShowingOnboarding: Bool = false
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("forceOnboarding") var forceOnboarding: Bool = false

    let speechSynthesizer = AVSpeechSynthesizer()
    let kidSpeechRate: Float = 0.45
    let kidPitch: Float = 0.95
    let kidPreDelay: Double = 0
    let kidPostDelay: Double = 0

    var body: some View {
        ZStack {
            mainContent
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
            syncSpeechSettingsFromProfile()
            syncSelectionFromProfile()
            clampSelection()
            isAwaitingStart = true
            showLaunchIfNeeded()
            updateOnboardingVisibility()
        }
        .onChange(of: store.groups.map(\.id)) { _, _ in
            clampSelection()
            isAwaitingStart = true
        }
        .onChange(of: familyStore.changeToken) { _, _ in
            clampSelection()
            isAwaitingStart = true
            syncSpeechSettingsFromProfile()
            syncSelectionFromProfile()
            updateOnboardingVisibility()
        }
        .onChange(of: hasSeenOnboarding) { _, _ in
            updateOnboardingVisibility()
        }
        .onChange(of: forceOnboarding) { _, _ in
            if forceOnboarding {
                isShowingSettings = false
            }
            updateOnboardingVisibility()
        }
        .onChange(of: selectedGroupIndex) { _, _ in
            handleGroupChange()
            persistSelectionToProfile()
        }
        .onChange(of: selectedDeckIndex) { _, _ in
            handleDeckChange()
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
                selectedDeckIndex: $selectedDeckIndex,
                selectedVoiceIdentifier: $selectedVoiceIdentifier,
                availableVoices: availableVoices,
                isSpeechEnabled: $isSpeechEnabled,
                sourceDescription: store.sourceDescription,
                familyStore: familyStore
            )
        }
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            OnboardingFlowView(
                familyStore: familyStore,
                groups: store.groups,
                availableVoices: availableVoices,
                hasSeenOnboarding: $hasSeenOnboarding,
                forceOnboarding: $forceOnboarding
            )
        }
    }

    var currentIndexDisplay: Int {
        currentDeck.cards.isEmpty ? 0 : (currentIndex + 1)
    }

    var isDeckActive: Bool {
        currentCard != nil && !isAwaitingStart
    }

    var availableVoices: [AVSpeechSynthesisVoice] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.name < $1.name }
        return voices
    }

    var visibleGroups: [TopicGroup] {
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

    var preferredVoice: AVSpeechSynthesisVoice? {
        let ralph = availableVoices.first { $0.name.localizedCaseInsensitiveContains("ralph") }
        return ralph ?? availableVoices.first { $0.language == "en-US" } ?? availableVoices.first
    }

    var selectedVoice: AVSpeechSynthesisVoice? {
        availableVoices.first { $0.identifier == selectedVoiceIdentifier } ?? preferredVoice
    }

    var currentGroup: TopicGroup {
        guard !visibleGroups.isEmpty,
              selectedGroupIndex >= 0,
              selectedGroupIndex < visibleGroups.count else {
            return TopicGroup(title: "Empty", decks: [])
        }
        return visibleGroups[selectedGroupIndex]
    }

    var currentDeck: Deck {
        let decks = currentGroup.decks
        guard !decks.isEmpty,
              selectedDeckIndex >= 0,
              selectedDeckIndex < decks.count else {
            return Deck(title: "Empty", cards: [])
        }
        return decks[selectedDeckIndex]
    }

    var currentCard: Flashcard? {
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
