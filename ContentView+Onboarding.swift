import Foundation
import SwiftUI

extension ContentView {
    var shouldShowOnboarding: Bool {
        !hasSeenOnboarding || forceOnboarding || familyStore.profiles.isEmpty
    }

    func updateOnboardingVisibility() {
        isShowingOnboarding = shouldShowOnboarding
    }
}
