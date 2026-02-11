import SwiftUI

struct FlashcardControlsView: View {
    let isShowingAnswer: Bool
    let canNavigate: Bool
    let canSpeak: Bool
    let onPrevious: () -> Void
    let onToggle: () -> Void
    let onSpeakQuestion: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button("Previous") {
                onPrevious()
            }
            .buttonStyle(.bordered)
            .disabled(!canNavigate)

            Button(isShowingAnswer ? "Hide Answer" : "Show Answer") {
                onToggle()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSpeak)

            Button("Speak Question") {
                onSpeakQuestion()
            }
            .buttonStyle(.bordered)
            .disabled(!canSpeak)

            Button("Next") {
                onNext()
            }
            .buttonStyle(.bordered)
            .disabled(!canNavigate)
        }
    }
}
