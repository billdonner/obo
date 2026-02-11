import SwiftUI

struct FlashcardControlsView: View {
    let canNavigate: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button("Previous") {
                onPrevious()
            }
            .buttonStyle(.bordered)
            .disabled(!canNavigate)

            Button("Next") {
                onNext()
            }
            .buttonStyle(.bordered)
            .disabled(!canNavigate)
        }
    }
}
