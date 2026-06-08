import Foundation
import SwiftData

@Model
final class DaySection {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int
    var colorHex: String

    @Relationship(deleteRule: .cascade, inverse: \APEXTask.section)
    var tasks: [APEXTask] = []

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        sortOrder: Int,
        colorHex: String = "#00D4FF"
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.colorHex = colorHex
    }
}
