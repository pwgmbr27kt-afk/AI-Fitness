import Foundation
import SwiftData

@Model
final class BodyEntry {
    var id: UUID
    var date: Date
    var weightKg: Double
    var bodyFatPercent: Double?
    var notes: String

    // Photos stored as Data (JPEG compressed)
    var photoFront: Data?
    var photoSide: Data?
    var photoBack: Data?

    // AI analysis result
    var aiAnalysis: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double,
        bodyFatPercent: Double? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.bodyFatPercent = bodyFatPercent
        self.notes = notes
    }

    var hasAnyPhoto: Bool {
        photoFront != nil || photoSide != nil || photoBack != nil
    }
}
