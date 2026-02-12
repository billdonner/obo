import SwiftUI

struct FlashcardView: View {
    let card: Flashcard
    let isShowingAnswer: Bool
    let canSpeakAnswer: Bool
    let isSpeechEnabled: Bool
    let onSpeakAnswer: () -> Void
    let canSpeakQuestion: Bool
    let onSpeakQuestion: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)

            VStack(spacing: 20) {
                Text(isShowingAnswer ? card.answer : card.question)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(36)

            if isShowingAnswer && canSpeakAnswer {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            onSpeakAnswer()
                        } label: {
                            speakerButtonLabel(isEnabled: isSpeechEnabled)
                        }
                        .accessibilityLabel("Replay answer")
                        .foregroundStyle(isSpeechEnabled ? .primary : .secondary)
                        .padding(16)
                    }
                }
            }

            if !isShowingAnswer && canSpeakQuestion {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            onSpeakQuestion()
                        } label: {
                            speakerButtonLabel(isEnabled: isSpeechEnabled)
                        }
                        .accessibilityLabel("Replay question")
                        .foregroundStyle(isSpeechEnabled ? .primary : .secondary)
                        .padding(16)
                    }
                }
            }
        }
        .frame(maxWidth: 520, maxHeight: 380)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isShowingAnswer ? "Answer" : "Question")
        .accessibilityValue(isShowingAnswer ? card.answer : card.question)
        .accessibilityHint("Double tap to flip the card")
    }

    private func speakerButtonLabel(isEnabled: Bool) -> some View {
        Image(systemName: "speaker.wave.3.fill")
            .font(.system(size: 20, weight: .semibold))
            .frame(width: 52, height: 52)
            .background(
                Circle()
                    .fill(Color.primary.opacity(isEnabled ? 0.16 : 0.1))
            )
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(isEnabled ? 0.3 : 0.22), lineWidth: 1)
            )
            .contentShape(Circle())
    }
}

struct BeginCardView: View {
    let deckTitle: String
    let onStart: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.35), lineWidth: 3)
                )
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.accentColor.opacity(0.08))
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, y: 6)

            Image("LaunchIcon")
                .resizable()
                .scaledToFill()
                .opacity(0.06)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 16) {
                Image(systemName: "play")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(deckTitle)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button {
                    onStart()
                } label: {
                    Text("Start Deck")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.accentColor.opacity(0.2), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(32)
        }
        .frame(maxWidth: 420, maxHeight: 320)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tap to begin")
        .accessibilityHint("Double tap to start the first question")
    }
}

struct EmptyStateView: View {
    let profileName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)

            VStack(spacing: 12) {
                Image(systemName: "tray.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)

                Text(titleText)
                    .font(.headline.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text("Ask a caregiver to choose categories or check age settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(32)
        }
        .frame(maxWidth: 460, maxHeight: 320)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(titleText)
    }

    private var titleText: String {
        let trimmedName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return "No decks selected yet"
        }
        return "No decks selected for \(trimmedName)"
    }
}
