import Foundation
import Observation

@Observable
final class FlashcardStore {
    private(set) var groups: [TopicGroup] = []

    private let fileName = "decks.txt"

    func load() {
        if let loaded = loadFromDocuments(), !loaded.isEmpty {
            groups = loaded
            return
        }

        let bundledSamples = loadFromBundleSamples()
        if !bundledSamples.isEmpty {
            groups = bundledSamples
            return
        }

        groups = TopicGroup.sample
    }

    private func loadFromDocuments() -> [TopicGroup]? {
        guard let url = documentsDirectory()?.appendingPathComponent(fileName) else { return nil }
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return parse(text: text)
    }

    private func loadFromBundleSamples() -> [TopicGroup] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: nil) else {
            return []
        }

        let sampleUrls = urls.filter { $0.lastPathComponent.range(of: #"^\d{2}_.+\.txt$"#, options: .regularExpression) != nil }
        let sortedUrls = sampleUrls.sorted { $0.lastPathComponent < $1.lastPathComponent }
        var results: [TopicGroup] = []
        for url in sortedUrls {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let fallbackTitle = url.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "_", with: " ")
            if let group = parseSampleFile(text: text, fallbackTitle: fallbackTitle) {
                results.append(group)
            }
        }
        return results
    }

    private func documentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private func parse(text: String) -> [TopicGroup] {
        var groups: [TopicGroup] = []
        var currentGroupTitle: String?
        var currentDeckTitle: String?
        var currentDecks: [Deck] = []
        var currentCards: [Flashcard] = []
        var pendingQuestion: String?

        func flushDeck() {
            guard let deckTitle = currentDeckTitle else { return }
            let trimmedTitle = deckTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty, !currentCards.isEmpty else {
                currentCards = []
                return
            }
            currentDecks.append(Deck(title: trimmedTitle, cards: currentCards))
            currentCards = []
        }

        func flushGroup() {
            guard let groupTitle = currentGroupTitle else { return }
            let trimmedTitle = groupTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty, !currentDecks.isEmpty else {
                currentDecks = []
                return
            }
            groups.append(TopicGroup(title: trimmedTitle, decks: currentDecks))
            currentDecks = []
        }

        let lines = text.split(whereSeparator: \.isNewline).map { String($0) }
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            if line.lowercased().hasPrefix("group:") {
                flushDeck()
                flushGroup()
                currentGroupTitle = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                currentDeckTitle = nil
                continue
            }

            if line.lowercased().hasPrefix("deck:") {
                flushDeck()
                currentDeckTitle = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                pendingQuestion = nil
                continue
            }

            if line.lowercased().hasPrefix("q:") {
                pendingQuestion = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                continue
            }

            if line.lowercased().hasPrefix("a:") {
                let answer = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if let question = pendingQuestion, !question.isEmpty, !answer.isEmpty {
                    currentCards.append(Flashcard(question: question, answer: answer))
                }
                pendingQuestion = nil
                continue
            }
        }

        flushDeck()
        flushGroup()
        return groups
    }

    private func parseSampleFile(text: String, fallbackTitle: String) -> TopicGroup? {
        var title: String = fallbackTitle
        var cards: [Flashcard] = []

        let lines = text.split(whereSeparator: \.isNewline).map { String($0) }
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            if line.lowercased().hasPrefix("title:") {
                let parsedTitle = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                if !parsedTitle.isEmpty {
                    title = parsedTitle
                }
                continue
            }

            let parts = line.split(separator: "|", maxSplits: 1).map { String($0) }
            guard parts.count == 2 else { continue }

            let left = parts[0].trimmingCharacters(in: .whitespaces)
            let right = parts[1].trimmingCharacters(in: .whitespaces)
            guard left.lowercased().hasPrefix("q:") else { continue }
            guard let answerRange = right.lowercased().range(of: "a:") else { continue }

            let question = left.dropFirst(2).trimmingCharacters(in: .whitespaces)
            let answer = right[answerRange.upperBound...].trimmingCharacters(in: .whitespaces)
            if !question.isEmpty, !answer.isEmpty {
                cards.append(Flashcard(question: question, answer: answer))
            }
        }

        guard !cards.isEmpty else { return nil }
        let deck = Deck(title: title, cards: cards)
        return TopicGroup(title: title, decks: [deck])
    }
}
