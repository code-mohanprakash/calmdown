import Foundation
import SwiftData

@MainActor
final class TrackingViewModel: ObservableObject {
    @Published var todayWaterMl:    Int = 0
    @Published var todayCaffeineMg: Int = 0
    @Published var selectedEmotions: Set<String> = []

    let waterGoalMl    = 2000
    let caffeineGoalMg = 400

    var waterProgress: Double { Double(todayWaterMl) / Double(waterGoalMl) }

    // MARK: - Load today's totals
    func loadTodayTotals(context: ModelContext) {
        let today      = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<HydrationEntry>(
            predicate: #Predicate { $0.timestamp >= today }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        todayWaterMl    = entries.reduce(0) { $0 + $1.waterMl }
        todayCaffeineMg = entries.reduce(0) { $0 + $1.caffeineMg }
    }

    // MARK: - Water
    func addWater(_ ml: Int, context: ModelContext) {
        let entry = HydrationEntry(waterMl: ml, caffeineMg: 0)
        context.insert(entry)
        try? context.save()
        todayWaterMl += ml
    }

    // MARK: - Caffeine
    func addCaffeine(_ mg: Int, context: ModelContext) {
        let entry = HydrationEntry(waterMl: 0, caffeineMg: mg)
        context.insert(entry)
        try? context.save()
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
