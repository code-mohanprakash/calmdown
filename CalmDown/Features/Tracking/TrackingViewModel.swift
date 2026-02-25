import Foundation
import SwiftData

@MainActor
final class TrackingViewModel: ObservableObject {
    @Published var todayWaterMl:   Int = 1000
    @Published var todayCaffeineMg: Int = 20
    @Published var selectedEmotions: Set<String> = []
    @Published var todayMoods: [MoodEntry] = []

    let waterGoalMl    = 2000
    let caffeineGoalMg = 400

    var waterProgress: Double { Double(todayWaterMl) / Double(waterGoalMl) }

    // MARK: - Water
    func addWater(_ ml: Int) {
        todayWaterMl = min(todayWaterMl + ml, waterGoalMl * 2)
    }

    // MARK: - Caffeine
    func addCaffeine(_ mg: Int) {
        todayCaffeineMg += mg
    }

    // MARK: - Mood
    func toggleEmotion(_ name: String) {
        if selectedEmotions.contains(name) {
            selectedEmotions.remove(name)
        } else {
            selectedEmotions.insert(name)
        }
    }

    func saveMood(context: ModelContext) {
        for name in selectedEmotions {
            if let emotion = Emotion.catalog.first(where: { $0.name == name }) {
                let entry = MoodEntry(emotion: emotion.name, emoji: emotion.emoji)
                context.insert(entry)
            }
        }
        try? context.save()
        selectedEmotions.removeAll()
    }
}
