import SwiftUI

struct FlashcardView: View {
    let card: Flashcard
    let isShowingAnswer: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(radius: 6, y: 3)

            VStack(spacing: 16) {
                Text(isShowingAnswer ? "Answer" : "Question")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(isShowingAnswer ? card.answer : card.question)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("Tap to flip")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
        }
        .frame(maxWidth: 420, maxHeight: 320)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isShowingAnswer ? "Answer" : "Question")
        .accessibilityValue(isShowingAnswer ? card.answer : card.question)
        .accessibilityHint("Double tap to flip the card")
    }
}
