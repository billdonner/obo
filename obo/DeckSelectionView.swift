import SwiftUI

struct DeckSelectionView: View {
    let groups: [TopicGroup]
    @Binding var selectedGroupIndex: Int
    @Binding var selectedDeckIndex: Int
    let userName: String
    let currentIndexDisplay: Int
    let currentDeckCount: Int
    let isDeckActive: Bool
    let showRecommendedRow: Bool
    let recommendedDecks: [Deck]
    let showProgressBar: Bool
    let showVoiceBadge: Bool
    let voiceBadgeText: String
    let onSelectDeckID: (String) -> Void
    let onOpenSettings: () -> Void
    let onDeckChanged: () -> Void

    var body: some View {
        VStack(spacing: isDeckActive ? 4 : 10) {
            HStack {
                Text(titleText)
                    .font(isDeckActive ? .title3.weight(.semibold) : .largeTitle.bold())
                    .foregroundStyle(isDeckActive ? .secondary : .primary)

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

            if showRecommendedRow && !recommendedDecks.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommended")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recommendedDecks) { deck in
                                Button {
                                    onSelectDeckID(deck.id)
                                } label: {
                                    Text(deck.title)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            Picker("Topic", selection: $selectedDeckIndex) {
                ForEach(currentDeckTitles.indices, id: \.self) { index in
                    Text(currentDeckTitles[index])
                        .tag(index)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedDeckIndex) { _, _ in
                onDeckChanged()
            }

            Text("\(currentIndexDisplay) of \(currentDeckCount)")
                .font(isDeckActive ? .caption : .callout)
                .foregroundStyle(.secondary)

            if showProgressBar && currentDeckCount > 0 {
                ProgressView(value: Double(currentIndexDisplay), total: Double(currentDeckCount))
                    .tint(Color.accentColor)
            }
        }
    }

    private var currentDeckTitles: [String] {
        guard !groups.isEmpty, selectedGroupIndex >= 0, selectedGroupIndex < groups.count else {
            return []
        }
        return groups[selectedGroupIndex].decks.map { $0.title }
    }

    private var titleText: String {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return "Flashcards"
        }
        return "Flashcards for \(trimmedName)"
    }
}
