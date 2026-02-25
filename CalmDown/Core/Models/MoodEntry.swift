import Foundation
import SwiftData

@Model
final class MoodEntry {
    var id: UUID
    var timestamp: Date
    var emotion: String
    var emoji: String
    var note: String

    init(id: UUID = UUID(), timestamp: Date = Date(), emotion: String, emoji: String, note: String = "") {
        self.id        = id
        self.timestamp = timestamp
        self.emotion   = emotion
        self.emoji     = emoji
        self.note      = note
    }
}

// MARK: - Emotion catalog
struct Emotion: Identifiable, Hashable {
    let id: UUID
    let name: String
    let emoji: String
    let category: EmotionCategory

    init(id: UUID = UUID(), name: String, emoji: String, category: EmotionCategory = .neutral) {
        self.id       = id
        self.name     = name
        self.emoji    = emoji
        self.category = category
    }

    static let catalog: [Emotion] = [
        Emotion(name: "Amazed",     emoji: "🤩", category: .positive),
        Emotion(name: "Excited",    emoji: "😄", category: .positive),
        Emotion(name: "Grateful",   emoji: "🙏", category: .positive),
        Emotion(name: "Joyful",     emoji: "😊", category: .positive),
        Emotion(name: "Satisfied",  emoji: "😌", category: .positive),
        Emotion(name: "Hopeful",    emoji: "🌟", category: .positive),
        Emotion(name: "Amused",     emoji: "😏", category: .neutral),
        Emotion(name: "Passionate", emoji: "❤️", category: .positive),
        Emotion(name: "Calm",       emoji: "🧘", category: .positive),
        Emotion(name: "Anxious",    emoji: "😰", category: .negative),
        Emotion(name: "Stressed",   emoji: "😤", category: .negative),
        Emotion(name: "Tired",      emoji: "😴", category: .negative),
    ]
}

enum EmotionCategory: String, Codable {
    case positive, neutral, negative
}
