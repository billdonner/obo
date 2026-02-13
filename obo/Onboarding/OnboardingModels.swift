import Foundation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case profile
    case decks
    case voice
    case howTo

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Obo"
        case .profile:
            return "Choose a Learner"
        case .decks:
            return "Pick a Starting Deck"
        case .voice:
            return "Meet Your Voice"
        case .howTo:
            return "How It Works"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Flashcards made for curious kids."
        case .profile:
            return "Set up a profile for your child."
        case .decks:
            return "We’ll start with a great deck for their age."
        case .voice:
            return "Friendly voice for every question."
        case .howTo:
            return "Tap, flip, and learn together."
        }
    }

    var heroAssetName: String {
        switch self {
        case .welcome:
            return "OnboardingWelcome"
        case .profile:
            return "OnboardingProfile"
        case .decks:
            return "OnboardingDecks"
        case .voice:
            return "OnboardingVoice"
        case .howTo:
            return "OnboardingHowTo"
        }
    }

    var fallbackSymbol: String {
        switch self {
        case .welcome:
            return "sparkles"
        case .profile:
            return "person.crop.circle"
        case .decks:
            return "rectangle.stack"
        case .voice:
            return "speaker.wave.3"
        case .howTo:
            return "hand.tap"
        }
    }
}
