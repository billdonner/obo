import Foundation

struct TopicGroup: Identifiable {
    let id = UUID()
    let title: String
    let decks: [Deck]

    static let sample: [TopicGroup] = [
        TopicGroup(
            title: "Nature",
            decks: [
                Deck(
                    title: "Animals",
                    cards: [
                        Flashcard(question: "What sound does a cow make?", answer: "Moo"),
                        Flashcard(question: "Which animal says meow?", answer: "Cat"),
                        Flashcard(question: "A baby dog is called a...?", answer: "Puppy")
                    ]
                ),
                Deck(
                    title: "Weather",
                    cards: [
                        Flashcard(question: "What falls from the sky when it rains?", answer: "Raindrops"),
                        Flashcard(question: "What makes thunder after lightning?", answer: "Sound"),
                        Flashcard(question: "What shines in the sky during the day?", answer: "The sun")
                    ]
                ),
                Deck(
                    title: "Seasons",
                    cards: [
                        Flashcard(question: "Which season is the coldest?", answer: "Winter"),
                        Flashcard(question: "Which season has falling leaves?", answer: "Fall"),
                        Flashcard(question: "Which season is warm and sunny?", answer: "Summer")
                    ]
                )
            ]
        ),
        TopicGroup(
            title: "Everyday",
            decks: [
                Deck(
                    title: "Colors",
                    cards: [
                        Flashcard(question: "Mix red and blue to get...?", answer: "Purple"),
                        Flashcard(question: "The color of grass is...?", answer: "Green"),
                        Flashcard(question: "The color of a banana is...?", answer: "Yellow")
                    ]
                ),
                Deck(
                    title: "Shapes",
                    cards: [
                        Flashcard(question: "How many sides does a triangle have?", answer: "3"),
                        Flashcard(question: "A circle has any corners?", answer: "No"),
                        Flashcard(question: "A square has how many sides?", answer: "4")
                    ]
                ),
                Deck(
                    title: "Food",
                    cards: [
                        Flashcard(question: "What do bees make?", answer: "Honey"),
                        Flashcard(question: "What color is an apple?", answer: "Red or green"),
                        Flashcard(question: "What do you eat for breakfast?", answer: "Cereal or eggs")
                    ]
                ),
                Deck(
                    title: "Vehicles",
                    cards: [
                        Flashcard(question: "What flies in the sky with wings?", answer: "Airplane"),
                        Flashcard(question: "What has two wheels and you can pedal?", answer: "Bicycle"),
                        Flashcard(question: "What drives on tracks and goes choo-choo?", answer: "Train")
                    ]
                )
            ]
        ),
        TopicGroup(
            title: "Learning",
            decks: [
                Deck(
                    title: "Numbers",
                    cards: [
                        Flashcard(question: "What number comes after 3?", answer: "4"),
                        Flashcard(question: "How many fingers on one hand?", answer: "5"),
                        Flashcard(question: "What number comes before 10?", answer: "9")
                    ]
                ),
                Deck(
                    title: "Letters",
                    cards: [
                        Flashcard(question: "What letter comes after A?", answer: "B"),
                        Flashcard(question: "What letter starts the word 'ball'?", answer: "B"),
                        Flashcard(question: "What letter starts the word 'cat'?", answer: "C")
                    ]
                ),
                Deck(
                    title: "Feelings",
                    cards: [
                        Flashcard(question: "How do you feel when you smile?", answer: "Happy"),
                        Flashcard(question: "How do you feel when you lose a toy?", answer: "Sad"),
                        Flashcard(question: "How do you feel when you are surprised?", answer: "Surprised")
                    ]
                )
            ]
        )
    ]
}

struct Deck: Identifiable {
    let id = UUID()
    let title: String
    let cards: [Flashcard]
}

struct Flashcard: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}
