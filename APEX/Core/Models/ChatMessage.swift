import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var role: String          // "user" or "assistant"
    var content: String
    var timestamp: Date
    var isError: Bool

    init(
        id: UUID = UUID(),
        role: String,
        content: String,
        timestamp: Date = Date(),
        isError: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isError = isError
    }

    var isUser: Bool { role == "user" }
}
