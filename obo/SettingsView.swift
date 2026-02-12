import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let groups: [TopicGroup]
    let visibleGroups: [TopicGroup]
    @Binding var selectedGroupIndex: Int
    @Binding var selectedVoiceIdentifier: String
    let availableVoices: [AVSpeechSynthesisVoice]
    @Binding var isSpeechEnabled: Bool
    let sourceDescription: String
    @Bindable var familyStore: FamilyStore

    @State private var isParentUnlocked: Bool = false
    @State private var isShowingParentGate: Bool = false
    @State private var showParentControls: Bool = false
    @AppStorage("caregiverUnlockTimestamp") private var caregiverUnlockTimestamp: Double = 0

    var body: some View {
        NavigationStack {
            List {
                Section("Active Profile") {
                    Picker("Profile", selection: selectedProfileBinding) {
                        ForEach(familyStore.profiles) { profile in
                            Text("\(profile.name) (\(profile.ageBand.displayName))")
                                .tag(profile.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Caregiver Controls") {
                    if isParentUnlocked {
                        Button("Open Caregiver Controls") {
                            showParentControls = true
                        }
                    } else {
                        Button("Open Caregiver Controls") {
                            if requiresGate {
                                isShowingParentGate = true
                            } else {
                                isParentUnlocked = true
                                showParentControls = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingParentGate) {
                ParentGateView {
                    handleCaregiverUnlock()
                }
            }
            .navigationDestination(isPresented: $showParentControls) {
                ParentControlsView(
                    groups: groups,
                    visibleGroups: visibleGroups,
                    selectedGroupIndex: $selectedGroupIndex,
                    selectedVoiceIdentifier: $selectedVoiceIdentifier,
                    availableVoices: availableVoices,
                    isSpeechEnabled: $isSpeechEnabled,
                    sourceDescription: sourceDescription,
                    familyStore: familyStore
                )
            }
        }
    }

    private var selectedProfileBinding: Binding<UUID> {
        Binding(
            get: { familyStore.selectedProfileID ?? familyStore.currentProfile?.id ?? UUID() },
            set: { newValue in
                familyStore.setSelectedProfileID(newValue)
            }
        )
    }

    private var requiresGate: Bool {
        let now = Date().timeIntervalSince1970
        return now - caregiverUnlockTimestamp > 600
    }

    private func handleCaregiverUnlock() {
        caregiverUnlockTimestamp = Date().timeIntervalSince1970
        isParentUnlocked = true
        showParentControls = true
    }

    private func deckAllowedBinding(deckID: String, profile: FamilyProfile) -> Binding<Bool> {
        Binding(
            get: {
                let allowed = Set(profile.allowedDeckIDs)
                if allowed.isEmpty {
                    return true
                }
                return allowed.contains(deckID)
            },
            set: { isAllowed in
                var updatedProfile = profile
                var allowed = Set(profile.allowedDeckIDs)
                if allowed.isEmpty {
                    allowed = Set(allDeckIDs)
                }
                if isAllowed {
                    allowed.insert(deckID)
                } else {
                    allowed.remove(deckID)
                }
                if allowed.isEmpty {
                    updatedProfile.allowedDeckIDs = []
                } else {
                    updatedProfile.allowedDeckIDs = Array(allowed)
                }
                familyStore.updateProfile(updatedProfile)
            }
        )
    }

    private func deckAgeBinding(deckID: String) -> Binding<AgeBand> {
        Binding(
            get: { familyStore.deckAgeBand(for: deckID) },
            set: { newValue in
                familyStore.setDeckAgeBand(newValue, for: deckID)
            }
        )
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

    private var allDeckIDs: [String] {
        groups.flatMap { $0.decks.map(\.id) }
    }
}

private struct ParentGateView: View {
    @Environment(\.dismiss) private var dismiss
    let onUnlock: () -> Void

    @State private var prompt = ParentGatePrompt.random()
    @State private var answerText: String = ""
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

            Form {
                Section("Caregiver Gate") {
                    Text(prompt.question)
                        .font(.headline)
                            .foregroundStyle(.white)

                        TextField("Answer", text: $answerText)
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .tint(.white)

                        if showError {
                            Text("That answer is not correct.")
                                .foregroundStyle(.red)
                        }
                    }

                    Section {
                        Button("Try") {
                            verify()
                        }

                        Button("New Question") {
                            prompt = ParentGatePrompt.random()
                            answerText = ""
                            showError = false
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
                .foregroundStyle(.white)
                .listRowBackground(Color.black.opacity(0.25))
                .listRowSeparatorTint(.white.opacity(0.2))
                .environment(\.colorScheme, .dark)
            }
            .navigationTitle("Caregiver Gate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func verify() {
        guard let value = Int(answerText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            showError = true
            return
        }

        if value == prompt.answer {
            onUnlock()
            dismiss()
        } else {
            showError = true
        }
    }
}

private struct ParentGatePrompt {
    let left: Int
    let right: Int

    var question: String {
        "Solve to unlock: \(left) + \(right)"
    }

    var answer: Int {
        left + right
    }

    static func random() -> ParentGatePrompt {
        ParentGatePrompt(
            left: Int.random(in: 12...49),
            right: Int.random(in: 12...49)
        )
    }
}

#Preview("Settings") {
    SettingsView(
        groups: [],
        visibleGroups: [],
        selectedGroupIndex: .constant(0),
        selectedVoiceIdentifier: .constant(""),
        availableVoices: AVSpeechSynthesisVoice.speechVoices(),
        isSpeechEnabled: .constant(true),
        sourceDescription: "Bundled sample decks",
        familyStore: FamilyStore()
    )
}
