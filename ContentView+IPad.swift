import SwiftUI

extension ContentView {
    var mainContent: some View {
        Group {
            if isRegularWidth {
                iPadLayout
            } else {
                phoneLayout
            }
        }
    }

    var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    var phoneLayout: some View {
        VStack(spacing: isDeckActive ? 18 : 24) {
            DeckSelectionView(
                groups: visibleGroups,
                selectedGroupIndex: $selectedGroupIndex,
                selectedDeckIndex: $selectedDeckIndex,
                userName: userNameText,
                currentIndexDisplay: currentIndexDisplay,
                currentDeckCount: currentDeck.cards.count,
                isDeckActive: isDeckActive,
                showRecommendedRow: showRecommendedRow,
                recommendedDecks: recommendedDecks,
                showProgressBar: showProgressBar,
                showVoiceBadge: showVoiceBadge,
                voiceBadgeText: voiceBadgeText,
                onSelectDeckID: selectDeck(by:),
                onOpenSettings: { isShowingSettings = true },
                onDeckChanged: handleDeckChange
            )

            Spacer(minLength: 0)

            cardBody

            Spacer(minLength: 0)

            FlashcardControlsView(
                canNavigate: !currentDeck.cards.isEmpty,
                onPrevious: moveToPrevious,
                onNext: moveToNext
            )
        }
    }

    var iPadLayout: some View {
        NavigationSplitView {
            List {
                Section("Profile") {
                    if familyStore.profiles.isEmpty {
                        Text("Create a profile to begin.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Profile", selection: selectedProfileBinding) {
                            ForEach(familyStore.profiles) { profile in
                                Text(profile.name)
                                    .tag(profile.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Categories") {
                    ForEach(visibleGroups.indices, id: \.self) { index in
                        Button {
                            selectedGroupIndex = index
                        } label: {
                            HStack {
                                Image(systemName: selectedGroupIndex == index ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedGroupIndex == index ? Color.accentColor : .secondary)
                                Text(visibleGroups[index].title)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Decks") {
                    if visibleGroups.indices.contains(selectedGroupIndex) {
                        ForEach(visibleGroups[selectedGroupIndex].decks) { deck in
                            Button {
                                if let deckIndex = visibleGroups[selectedGroupIndex].decks.firstIndex(where: { $0.id == deck.id }) {
                                    selectedDeckIndex = deckIndex
                                }
                            } label: {
                                HStack {
                                    Image(systemName: currentDeck.id == deck.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(currentDeck.id == deck.id ? Color.accentColor : .secondary)
                                    Text(deck.title)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Text("Pick a category to see decks.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Obo")
        } detail: {
            VStack(spacing: 20) {
                IPadHeaderView(
                    title: userNameText.isEmpty ? "Flashcards" : "Flashcards for \(userNameText)",
                    voiceBadgeText: voiceBadgeText,
                    showVoiceBadge: showVoiceBadge,
                    currentIndexDisplay: currentIndexDisplay,
                    currentDeckCount: currentDeck.cards.count,
                    showProgressBar: showProgressBar,
                    onOpenSettings: { isShowingSettings = true }
                )

                Spacer(minLength: 0)

                cardBody

                Spacer(minLength: 0)

                FlashcardControlsView(
                    canNavigate: !currentDeck.cards.isEmpty,
                    onPrevious: moveToPrevious,
                    onNext: moveToNext
                )
            }
            .padding(.horizontal, 8)
        }
    }

    var cardBody: some View {
        Group {
            if visibleGroups.isEmpty {
                EmptyStateView(profileName: familyStore.currentProfile?.name ?? "")
            } else if let card = currentCard {
                if isAwaitingStart {
                    BeginCardView(deckTitle: currentDeck.title) {
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
                        handleCardTap()
                    }
                }
            } else {
                Text("No cards in this deck yet.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    var selectedProfileBinding: Binding<UUID?> {
        Binding(
            get: { familyStore.selectedProfileID ?? familyStore.currentProfile?.id },
            set: { newValue in
                familyStore.setSelectedProfileID(newValue)
                syncSelectionFromProfile()
                syncSpeechSettingsFromProfile()
            }
        )
    }
}

private struct IPadHeaderView: View {
    let title: String
    let voiceBadgeText: String
    let showVoiceBadge: Bool
    let currentIndexDisplay: Int
    let currentDeckCount: Int
    let showProgressBar: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.title.weight(.semibold))

                Spacer()

                Button {
                    onOpenSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .imageScale(.large)
                        .accessibilityLabel("Settings")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }

            if showVoiceBadge && !voiceBadgeText.isEmpty {
                HStack {
                    Text("Voice: \(voiceBadgeText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            HStack {
                Text("\(currentIndexDisplay) of \(currentDeckCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if showProgressBar && currentDeckCount > 0 {
                ProgressView(value: Double(currentIndexDisplay), total: Double(currentDeckCount))
                    .tint(Color.accentColor)
            }
        }
    }
}
