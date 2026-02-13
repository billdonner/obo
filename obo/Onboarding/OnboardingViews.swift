import AVFoundation
import SwiftUI

struct OnboardingHeroView: View {
    let step: OnboardingStep

    var body: some View {
        ZStack {
            Color(.systemBackground)

            OnboardingHeroImage(name: step.heroAssetName, fallbackSymbol: step.fallbackSymbol)
                .frame(maxWidth: .infinity)
                .frame(height: 260)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
    }
}

struct OnboardingHeroImage: View {
    let name: String
    let fallbackSymbol: String

    var body: some View {
        if let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 24)
        } else {
            Image(systemName: fallbackSymbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 64)
                .padding(.vertical, 24)
        }
    }
}

struct OnboardingDots: View {
    let currentIndex: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalCount, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct OnboardingControlsView: View {
    let canSkip: Bool
    let primaryTitle: String
    let onSkip: () -> Void
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button("Back") {
                onBack()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            if canSkip {
                Button("Skip") {
                    onSkip()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Button(primaryTitle) {
                onNext()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct OnboardingWelcomeStep: View {
    var body: some View {
        Text("Ready to learn something new today?")
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}

struct OnboardingProfileStep: View {
    let profiles: [FamilyProfile]
    @Binding var selectedProfileID: UUID?
    let onAddProfile: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if profiles.isEmpty {
                Text("Let’s create a profile for your child.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Picker("Profile", selection: $selectedProfileID) {
                    ForEach(profiles) { profile in
                        Text(profile.name)
                            .tag(profile.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            }

            Button("Add Profile") {
                onAddProfile()
            }
            .buttonStyle(.bordered)
        }
    }
}

struct OnboardingDeckStep: View {
    let decks: [Deck]
    @Binding var selectedDeckID: String?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(decks.prefix(5)) { deck in
                Button {
                    selectedDeckID = deck.id
                } label: {
                    HStack {
                        Image(systemName: selectedDeckID == deck.id ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedDeckID == deck.id ? Color.accentColor : .secondary)
                        Text(deck.title)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct OnboardingVoiceStep: View {
    let availableVoices: [AVSpeechSynthesisVoice]
    @Binding var selectedVoiceID: String
    @Binding var speechEnabled: Bool

    var body: some View {
        VStack(spacing: 12) {
            Toggle("Enable Speech", isOn: $speechEnabled)

            Picker("Voice", selection: $selectedVoiceID) {
                ForEach(availableVoices, id: \.identifier) { voice in
                    Text("\(voice.name) (\(voice.language))")
                        .tag(voice.identifier)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

struct OnboardingHowToStep: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                OnboardingHowToTile(symbol: "play", title: "Start")
                OnboardingHowToTile(symbol: "arrow.2.circlepath", title: "Flip")
                OnboardingHowToTile(symbol: "arrow.right.circle", title: "Next")
            }
        }
    }
}

struct OnboardingHowToTile: View {
    let symbol: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 72, height: 72)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
