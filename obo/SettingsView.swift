import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let groups: [TopicGroup]
    @Binding var selectedGroupIndex: Int
    @Binding var selectedVoiceIdentifier: String
    let availableVoices: [AVSpeechSynthesisVoice]
    @Binding var isSpeechEnabled: Bool
    @Binding var userName: String
    let sourceDescription: String
    let onGroupChanged: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Source") {
                    Text(sourceDescription)
                        .foregroundStyle(.secondary)
                }

                Section("Category") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(groups.indices, id: \.self) { index in
                            Button {
                                selectedGroupIndex = index
                                onGroupChanged()
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: selectedGroupIndex == index ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedGroupIndex == index ? Color.accentColor : .secondary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(groups[index].title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Text(categoryDescription(for: groups[index].title))
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Profile") {
                    TextField("Your name", text: $userName)
                        .textInputAutocapitalization(.words)
                }

                Section("Speech") {
                    Toggle("Enable Speech", isOn: $isSpeechEnabled)

                    Picker("Voice", selection: $selectedVoiceIdentifier) {
                        ForEach(availableVoices, id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))")
                                .tag(voice.identifier)
                        }
                    }
                    .disabled(availableVoices.isEmpty)
                }

                Section("More") {
                    Text("More options coming soon.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func categoryDescription(for title: String) -> String {
        switch title {
        case "STEM":
            return "Math, coding, and problem-solving."
        case "Life & Earth Science":
            return "Animals, weather, and the human body."
        case "Humanities & Arts":
            return "Reading, history, geography, and arts."
        default:
            return "More topics to explore."
        }
    }
}

#Preview("Settings") {
    SettingsView(
        groups: [],
        selectedGroupIndex: .constant(0),
        selectedVoiceIdentifier: .constant(""),
        availableVoices: AVSpeechSynthesisVoice.speechVoices(),
        isSpeechEnabled: .constant(true),
        userName: .constant(""),
        sourceDescription: "Bundled sample decks",
        onGroupChanged: {}
    )
}
