import AVFoundation
import SwiftUI

struct OnboardingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var familyStore: FamilyStore
    let groups: [TopicGroup]
    let availableVoices: [AVSpeechSynthesisVoice]
    @Binding var hasSeenOnboarding: Bool
    @Binding var forceOnboarding: Bool

    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedProfileID: UUID? = nil
    @State private var selectedDeckID: String? = nil
    @State private var selectedVoiceID: String = ""
    @State private var speechEnabled: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeroView(step: currentStep)

            VStack(spacing: 12) {
                Text(currentStep.title)
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(currentStep.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer(minLength: 12)

            Group {
                switch currentStep {
                case .welcome:
                    OnboardingWelcomeStep()
                case .profile:
                    OnboardingProfileStep(
                        profiles: familyStore.profiles,
                        selectedProfileID: $selectedProfileID,
                        onAddProfile: addProfile
                    )
                case .decks:
                    OnboardingDeckStep(
                        decks: historyDecks,
                        selectedDeckID: $selectedDeckID
                    )
                case .voice:
                    OnboardingVoiceStep(
                        availableVoices: availableVoices,
                        selectedVoiceID: $selectedVoiceID,
                        speechEnabled: $speechEnabled
                    )
                case .howTo:
                    OnboardingHowToStep()
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 12)

            OnboardingDots(currentIndex: currentStepIndex, totalCount: OnboardingStep.allCases.count)
                .padding(.bottom, 12)

            OnboardingControlsView(
                canSkip: canSkip,
                primaryTitle: currentStep == .howTo ? "Start" : "Next",
                onSkip: handleSkip,
                onBack: handleBack,
                onNext: handleNext
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled(!canDismiss)
        .onAppear {
            selectedProfileID = familyStore.selectedProfileID ?? familyStore.currentProfile?.id
            selectedDeckID = familyStore.currentProfile?.selectedDeckID
            selectedVoiceID = familyStore.currentProfile?.preferredVoiceIdentifier ?? ""
            speechEnabled = familyStore.currentProfile?.speechEnabled ?? true
            if selectedProfileID == nil, let first = familyStore.profiles.first {
                selectedProfileID = first.id
            }
        }
    }

    private var canDismiss: Bool {
        !familyStore.profiles.isEmpty
    }

    private var currentStepIndex: Int {
        currentStep.rawValue
    }

    private var canSkip: Bool {
        if currentStep == .profile {
            return false
        }
        return canDismiss
    }

    private var historyDecks: [Deck] {
        let allDecks = groups.flatMap { $0.decks }
        let history = allDecks.filter { $0.title.localizedCaseInsensitiveContains("history") }
        if !history.isEmpty {
            return history
        }
        return Array(allDecks.prefix(5))
    }

    private func handleBack() {
        guard currentStepIndex > 0 else { return }
        currentStep = OnboardingStep.allCases[currentStepIndex - 1]
    }

    private func handleSkip() {
        if !canDismiss {
            currentStep = .profile
            return
        }
        applyDefaultsIfNeeded()
        finishOnboarding()
    }

    private func handleNext() {
        if currentStep == .profile {
            guard selectedProfileID != nil else { return }
            if selectedDeckID == nil {
                selectedDeckID = historyDecks.first?.id
            }
        }
        if currentStep == .voice {
            if selectedVoiceID.isEmpty {
                selectedVoiceID = defaultVoiceID() ?? ""
                speechEnabled = true
            }
        }
        if currentStep == .howTo {
            applySelections()
            finishOnboarding()
            return
        }

        let nextIndex = min(currentStepIndex + 1, OnboardingStep.allCases.count - 1)
        currentStep = OnboardingStep.allCases[nextIndex]
    }

    private func addProfile() {
        familyStore.addProfile(activate: true)
        selectedProfileID = familyStore.currentProfile?.id
    }

    private func applyDefaultsIfNeeded() {
        guard let profileID = selectedProfileID ?? familyStore.currentProfile?.id else { return }
        let deckID = selectedDeckID ?? historyDecks.first?.id
        if let deckID {
            applyDeckSelection(deckID: deckID, profileID: profileID)
        }

        let voiceID = selectedVoiceID.isEmpty ? (defaultVoiceID() ?? "") : selectedVoiceID
        applyVoiceSelection(voiceID: voiceID, profileID: profileID, speechEnabled: true)
    }

    private func applySelections() {
        guard let profileID = selectedProfileID ?? familyStore.currentProfile?.id else { return }
        if let deckID = selectedDeckID {
            applyDeckSelection(deckID: deckID, profileID: profileID)
        }
        applyVoiceSelection(voiceID: selectedVoiceID, profileID: profileID, speechEnabled: speechEnabled)
    }

    private func applyDeckSelection(deckID: String, profileID: UUID) {
        for group in groups {
            if group.decks.contains(where: { $0.id == deckID }) {
                familyStore.updateProfileSelection(groupID: group.id, deckID: deckID, for: profileID)
                return
            }
        }
    }

    private func applyVoiceSelection(voiceID: String, profileID: UUID, speechEnabled: Bool) {
        familyStore.updateProfileVoice(voiceID, for: profileID)
        familyStore.updateProfileSpeechEnabled(speechEnabled, for: profileID)
    }

    private func defaultVoiceID() -> String? {
        let ralph = availableVoices.first { $0.name.localizedCaseInsensitiveContains("ralph") }
        return ralph?.identifier ?? availableVoices.first(where: { $0.language == "en-US" })?.identifier
    }

    private func finishOnboarding() {
        hasSeenOnboarding = true
        forceOnboarding = false
        dismiss()
    }
}
