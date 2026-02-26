import Foundation
import SwiftUI
import SwiftData

@Model
final class MoodEntry {
    var id: UUID
    var timestamp: Date
    var emotion: String
    var emoji: String
    var note: String
    var energyLevel: Int   // 1-5
    var triggers: String   // comma-separated trigger tags

    init(id: UUID = UUID(), timestamp: Date = Date(),
         emotion: String, emoji: String, note: String = "",
         energyLevel: Int = 3, triggers: String = "") {
        self.id          = id
        self.timestamp   = timestamp
        self.emotion     = emotion
        self.emoji       = emoji
        self.note        = note
        self.energyLevel = energyLevel
        self.triggers    = triggers
    }
}

// MARK: - Emotion catalog
struct Emotion: Identifiable {
    let id: UUID
    let name: String
    let emoji: String          // kept for export compatibility
    let category: EmotionCategory
    let sfSymbol: String       // SF Symbol name
    let color: Color           // display color

    init(id: UUID = UUID(), name: String, emoji: String,
         category: EmotionCategory = .neutral, sfSymbol: String, color: Color) {
        self.id       = id
        self.name     = name
        self.emoji    = emoji
        self.category = category
        self.sfSymbol = sfSymbol
        self.color    = color
    }

    static let catalog: [Emotion] = [
        // Positive
        Emotion(name: "Amazed",      emoji: "🤩", category: .positive, sfSymbol: "sparkles",                      color: Color(hex: "#FFD700")),
        Emotion(name: "Excited",     emoji: "😄", category: .positive, sfSymbol: "bolt.fill",                     color: Color(hex: "#FF8C00")),
        Emotion(name: "Grateful",    emoji: "🙏", category: .positive, sfSymbol: "heart.fill",                    color: Color(hex: "#FF6B9D")),
        Emotion(name: "Joyful",      emoji: "😊", category: .positive, sfSymbol: "sun.max.fill",                  color: Color(hex: "#FFB347")),
        Emotion(name: "Satisfied",   emoji: "😌", category: .positive, sfSymbol: "checkmark.seal.fill",           color: Color(hex: "#4CAF50")),
        Emotion(name: "Hopeful",     emoji: "🌟", category: .positive, sfSymbol: "star.fill",                     color: Color(hex: "#FFC107")),
        Emotion(name: "Energised",   emoji: "⚡", category: .positive, sfSymbol: "bolt.circle.fill",              color: Color(hex: "#FF6B35")),
        Emotion(name: "Focused",     emoji: "🎯", category: .positive, sfSymbol: "scope",                         color: .calmBlue),
        // Neutral
        Emotion(name: "Calm",        emoji: "🧘", category: .positive, sfSymbol: "leaf.fill",                     color: Color(hex: "#4DB6AC")),
        Emotion(name: "Amused",      emoji: "😏", category: .neutral,  sfSymbol: "face.smiling",                  color: Color(hex: "#FF9800")),
        Emotion(name: "Passionate",  emoji: "❤️", category: .positive, sfSymbol: "flame.fill",                    color: Color(hex: "#E53935")),
        Emotion(name: "Content",     emoji: "😊", category: .neutral,  sfSymbol: "cup.and.saucer.fill",           color: Color(hex: "#8D6E63")),
        // Negative
        Emotion(name: "Anxious",     emoji: "😰", category: .negative, sfSymbol: "waveform.path.ecg",             color: Color(hex: "#FF7043")),
        Emotion(name: "Stressed",    emoji: "😤", category: .negative, sfSymbol: "brain.head.profile",            color: Color(hex: "#E91E63")),
        Emotion(name: "Tired",       emoji: "😴", category: .negative, sfSymbol: "moon.zzz.fill",                 color: Color(hex: "#9C27B0")),
        Emotion(name: "Overwhelmed", emoji: "😩", category: .negative, sfSymbol: "cloud.heavyrain.fill",          color: Color(hex: "#5C6BC0")),
        Emotion(name: "Irritable",   emoji: "😠", category: .negative, sfSymbol: "exclamationmark.triangle.fill", color: Color(hex: "#FF5722")),
        Emotion(name: "Sad",         emoji: "😢", category: .negative, sfSymbol: "cloud.rain.fill",               color: Color(hex: "#607D8B")),
    ]
}

extension Emotion: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Emotion, rhs: Emotion) -> Bool { lhs.id == rhs.id }
}

enum EmotionCategory: String, Codable {
    case positive, neutral, negative
}
