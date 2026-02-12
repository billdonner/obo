import SwiftUI

struct FlashcardControlsView: View {
    let canNavigate: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            Button {
                onPrevious()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 56))
            }
            .accessibilityLabel("Previous")
            .buttonStyle(.plain)
            .foregroundStyle(canNavigate ? .primary : .secondary)
            .disabled(!canNavigate)

            Button {
                onNext()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 56))
            }
            .accessibilityLabel("Next")
            .buttonStyle(.plain)
            .foregroundStyle(canNavigate ? .primary : .secondary)
            .disabled(!canNavigate)
        }
    }
}
