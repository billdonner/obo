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
                .shadow(radius: 6, y: 3)

            VStack(spacing: 20) {
                Text(isShowingAnswer ? "Answer" : "Question")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(isShowingAnswer ? card.answer : card.question)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Text(isShowingAnswer ? "Tap to show question" : "Tap to show answer")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
                            Image(systemName: "speaker.wave.2")
                                .imageScale(.large)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
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
                            Image(systemName: "speaker.wave.2")
                                .imageScale(.large)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
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
}

struct BeginCardView: View {
    let deckTitle: String

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
                .shadow(radius: 10, y: 6)

            VStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)

                Text(deckTitle)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Tap to begin")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text("The first question will play automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
        }
        .frame(maxWidth: 420, maxHeight: 320)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tap to begin")
        .accessibilityHint("Double tap to start the first question")
    }
}
