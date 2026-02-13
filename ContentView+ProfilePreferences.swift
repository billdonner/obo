import Foundation
import AVFoundation
import SwiftUI

extension ContentView {
    var currentProfile: FamilyProfile? {
        familyStore.currentProfile
    }

    var userNameText: String {
        currentProfile?.name ?? ""
    }

    var showRecommendedRow: Bool {
        currentProfile?.showRecommendedRow ?? true
    }

    var showProgressBar: Bool {
        currentProfile?.showProgressBar ?? true
    }

    var showVoiceBadge: Bool {
        currentProfile?.showVoiceBadge ?? true
    }

    var recommendedDecks: [Deck] {
        guard showRecommendedRow else { return [] }
        let decks = visibleGroups.flatMap { $0.decks }
        return Array(decks.prefix(3))
    }

    var voiceBadgeText: String {
        guard isSpeechEnabled, currentProfile?.showVoiceBadge ?? true else { return "" }
        return selectedVoice?.name ?? ""
    }

    func showLaunchIfNeeded() {
        guard isShowingLaunch else { return }
        guard currentProfile?.showSplash ?? true else {
            isShowingLaunch = false
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 1.2)) {
                isShowingLaunch = false
            }
        }
    }

    func persistSelectionToProfile() {
        guard let profileID = currentProfile?.id else { return }
        let groupID = visibleGroups.indices.contains(selectedGroupIndex) ? visibleGroups[selectedGroupIndex].id : nil
        let deckID: String?
        if visibleGroups.indices.contains(selectedGroupIndex) {
            let decks = visibleGroups[selectedGroupIndex].decks
            deckID = decks.indices.contains(selectedDeckIndex) ? decks[selectedDeckIndex].id : nil
        } else {
            deckID = nil
        }
        familyStore.updateProfileSelection(groupID: groupID, deckID: deckID, for: profileID)
    }

    func syncSelectionFromProfile() {
        guard let profile = currentProfile else { return }
        guard !visibleGroups.isEmpty else { return }

        if let deckID = profile.selectedDeckID {
            for (groupIndex, group) in visibleGroups.enumerated() {
                if let deckIndex = group.decks.firstIndex(where: { $0.id == deckID }) {
                    selectedGroupIndex = groupIndex
                    selectedDeckIndex = deckIndex
                    return
                }
            }
        }

        if let groupID = profile.selectedGroupID,
           let groupIndex = visibleGroups.firstIndex(where: { $0.id == groupID }) {
            selectedGroupIndex = groupIndex
            selectedDeckIndex = 0
            return
        }
    }

    func selectDeck(by deckID: String) {
        for (groupIndex, group) in visibleGroups.enumerated() {
            if let deckIndex = group.decks.firstIndex(where: { $0.id == deckID }) {
                selectedGroupIndex = groupIndex
                selectedDeckIndex = deckIndex
                handleDeckChange()
                return
            }
        }
    }
}
