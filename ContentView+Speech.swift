import AVFoundation
import Foundation
import SwiftUI

extension ContentView {
    func speakCurrentAnswer(force: Bool) {
        guard (isSpeechEnabled || force), let card = currentCard else { return }
        speak(text: card.answer)
    }

    func speakCurrentQuestion(force: Bool) {
        guard (isSpeechEnabled || force), !isAwaitingStart, let card = currentCard else { return }
        speak(text: card.question)
    }

    func speakCurrentQuestionIfEnabled() {
        guard isSpeechEnabled, !isShowingAnswer, !isAwaitingStart else { return }
        speakCurrentQuestion(force: false)
    }

    func speakCurrentAnswerOneShot() {
        speakCurrentAnswer(force: true)
    }

    func speakCurrentQuestionOneShot() {
        speakCurrentQuestion(force: true)
    }

    func speak(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
        try? session.setActive(true)
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                speakNow(text: trimmed)
            }
        } else {
            speakNow(text: trimmed)
        }
    }

    func speakNow(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = kidSpeechRate
        utterance.pitchMultiplier = kidPitch
        utterance.preUtteranceDelay = kidPreDelay
        utterance.postUtteranceDelay = kidPostDelay
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }

    func speakVoiceSelection() {
        let voiceName = selectedVoice?.name ?? "Voice"
        speak(text: "\(voiceName), at your service.")
    }

    func syncSpeechSettingsFromProfile() {
        guard let profile = familyStore.currentProfile else { return }
        if !profile.preferredVoiceIdentifier.isEmpty {
            selectedVoiceIdentifier = profile.preferredVoiceIdentifier
        }
        isSpeechEnabled = profile.speechEnabled
    }
}
