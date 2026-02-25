import Foundation
import SwiftData

@Model
final class HydrationEntry {
    var id: UUID
    var timestamp: Date
    var waterMl: Int
    var caffeineMg: Int

    init(id: UUID = UUID(), timestamp: Date = Date(), waterMl: Int = 0, caffeineMg: Int = 0) {
        self.id         = id
        self.timestamp  = timestamp
        self.waterMl    = waterMl
        self.caffeineMg = caffeineMg
    }
}
