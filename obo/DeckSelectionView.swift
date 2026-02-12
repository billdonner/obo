import SwiftUI

struct DeckSelectionView: View {
    let groups: [TopicGroup]
    @Binding var selectedGroupIndex: Int
    @Binding var selectedDeckIndex: Int
    let userName: String
    let currentIndexDisplay: Int
    let currentDeckCount: Int
    let onOpenSettings: () -> Void
    let onDeckChanged: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(titleText)
                    .font(.title.bold())

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
                .foregroundStyle(.secondary)
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
