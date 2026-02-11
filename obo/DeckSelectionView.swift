import SwiftUI
import AVFoundation

struct DeckSelectionView: View {
    let groups: [TopicGroup]
    @Binding var selectedGroupIndex: Int
    @Binding var selectedDeckIndex: Int
    @Binding var selectedVoiceIdentifier: String
    let availableVoices: [AVSpeechSynthesisVoice]
    let currentIndexDisplay: Int
    let currentDeckCount: Int
    let sourceDescription: String
    let onGroupChanged: () -> Void
    let onDeckChanged: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Flashcards")
                .font(.title.bold())

            Text("Source: \(sourceDescription)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Category", selection: $selectedGroupIndex) {
                ForEach(groups.indices, id: \.self) { index in
                    Text(groups[index].title)
                        .tag(index)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedGroupIndex) { _, _ in
                onGroupChanged()
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

            Picker("Voice", selection: $selectedVoiceIdentifier) {
                ForEach(availableVoices, id: \.identifier) { voice in
                    Text("\(voice.name) (\(voice.language))")
                        .tag(voice.identifier)
                }
            }
            .pickerStyle(.menu)
            .disabled(availableVoices.isEmpty)

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
}
