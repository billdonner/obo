import Foundation
import SwiftUI

extension ContentView {
    func handleGroupChange() {
        selectedDeckIndex = 0
        currentIndex = 0
        isShowingAnswer = false
        isAwaitingStart = true
    }

    func handleDeckChange() {
        currentIndex = 0
        isShowingAnswer = false
        isAwaitingStart = true
        persistSelectionToProfile()
    }

    func moveToPrevious() {
        let cards = currentDeck.cards
        guard !cards.isEmpty else { return }
        isShowingAnswer = false
        currentIndex = (currentIndex - 1 + cards.count) % cards.count
    }

    func moveToNext() {
        let cards = currentDeck.cards
        guard !cards.isEmpty else { return }
        isShowingAnswer = false
        currentIndex = (currentIndex + 1) % cards.count
    }

    func toggleCardFace() {
        let willShowAnswer = !isShowingAnswer
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isShowingAnswer = willShowAnswer
        }
        if willShowAnswer {
            speakCurrentAnswer(force: false)
        } else {
            speakCurrentQuestionIfEnabled()
        }
    }

    func handleCardTap() {
        if isShowingAnswer {
            moveToNext()
        } else {
            toggleCardFace()
        }
    }
}
