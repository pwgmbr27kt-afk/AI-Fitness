import Foundation
import UIKit

// MARK: - Anthropic API Models
struct AnthropicRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String?
    let messages: [AnthropicMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

struct AnthropicMessage: Codable {
    let role: String
    let content: [AnthropicContent]
}

struct AnthropicContent: Codable {
    let type: String
    let text: String?
    let source: AnthropicImageSource?

    static func text(_ text: String) -> AnthropicContent {
        AnthropicContent(type: "text", text: text, source: nil)
    }

    static func image(base64: String, mediaType: String = "image/jpeg") -> AnthropicContent {
        AnthropicContent(type: "image", text: nil, source: AnthropicImageSource(type: "base64", mediaType: mediaType, data: base64))
    }
}

struct AnthropicImageSource: Codable {
    let type: String
    let mediaType: String
    let data: String

    enum CodingKeys: String, CodingKey {
        case type
        case mediaType = "media_type"
        case data
    }
}

struct AnthropicResponse: Decodable {
    let content: [AnthropicResponseContent]

    var firstText: String? {
        content.first(where: { $0.type == "text" })?.text
    }
}

struct AnthropicResponseContent: Decodable {
    let type: String
    let text: String?
}

// MARK: - AI Service Errors
enum AIServiceError: LocalizedError {
    case noAPIKey
    case networkError(Error)
    case invalidResponse
    case rateLimited
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:              return "Kein API-Key hinterlegt. Bitte in Einstellungen eingeben."
        case .networkError(let e):   return "Netzwerkfehler: \(e.localizedDescription)"
        case .invalidResponse:       return "Ungültige Antwort vom Server."
        case .rateLimited:           return "Rate Limit erreicht. Bitte kurz warten."
        case .apiError(let msg):     return "API-Fehler: \(msg)"
        }
    }
}

// MARK: - AI Service
@MainActor
final class AIService: ObservableObject {
    static let shared = AIService()

    private let keychain = KeychainService.shared

    private func apiKey() throws -> String {
        guard let key = keychain.get(account: AppConfiguration.keychainAPIKeyAccount),
              !key.isEmpty else {
            throw AIServiceError.noAPIKey
        }
        return key
    }

    // MARK: - Core send
    func send(
        systemPrompt: String,
        messages: [AnthropicMessage],
        maxTokens: Int = 1024
    ) async throws -> String {
        let key = try apiKey()

        let request = AnthropicRequest(
            model: AppConfiguration.anthropicModel,
            maxTokens: maxTokens,
            system: systemPrompt,
            messages: messages
        )

        var urlRequest = URLRequest(url: URL(string: AppConfiguration.anthropicAPIEndpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(key, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(AppConfiguration.anthropicAPIVersion, forHTTPHeaderField: "anthropic-version")

        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw AIServiceError.networkError(error)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200: break
            case 429: throw AIServiceError.rateLimited
            default:
                let body = String(data: data, encoding: .utf8) ?? "Unknown"
                throw AIServiceError.apiError("HTTP \(http.statusCode): \(body)")
            }
        }

        let decoded = try? JSONDecoder().decode(AnthropicResponse.self, from: data)
        guard let text = decoded?.firstText else {
            throw AIServiceError.invalidResponse
        }
        return text
    }

    // MARK: - Chat
    func chat(
        profile: UserProfile,
        history: [ChatMessage],
        userMessage: String
    ) async throws -> String {
        let systemPrompt = buildCoachSystemPrompt(profile: profile)

        var messages: [AnthropicMessage] = history.suffix(20).map { msg in
            AnthropicMessage(
                role: msg.isUser ? "user" : "assistant",
                content: [.text(msg.content)]
            )
        }
        messages.append(AnthropicMessage(role: "user", content: [.text(userMessage)]))

        return try await send(systemPrompt: systemPrompt, messages: messages, maxTokens: 1024)
    }

    // MARK: - Meal Estimation
    func estimateMeal(image: UIImage) async throws -> MealEstimate {
        guard let jpeg = image.jpegData(compressionQuality: 0.7) else {
            throw AIServiceError.invalidResponse
        }
        let base64 = jpeg.base64EncodedString()

        let prompt = """
        Analysiere dieses Essensfoto und schätze die Nährwerte.
        Antworte NUR mit folgendem JSON (keine weiteren Texte):
        {
          "name": "Name des Gerichts",
          "calories": 500,
          "protein": 30,
          "carbs": 45,
          "fat": 15,
          "confidence": "low|medium|high"
        }
        Alle Werte als Ganzzahl (kcal/g). Dies ist eine KI-Schätzung.
        """

        let messages = [AnthropicMessage(role: "user", content: [
            .image(base64: base64),
            .text(prompt)
        ])]

        let response = try await send(systemPrompt: "", messages: messages, maxTokens: 256)

        // Parse JSON from response
        if let jsonData = extractJSON(from: response),
           let estimate = try? JSONDecoder().decode(MealEstimate.self, from: jsonData) {
            return estimate
        }
        throw AIServiceError.invalidResponse
    }

    // MARK: - Body Analysis
    func analyzeBody(frontPhoto: UIImage) async throws -> String {
        guard let jpeg = frontPhoto.jpegData(compressionQuality: 0.7) else {
            throw AIServiceError.invalidResponse
        }
        let base64 = jpeg.base64EncodedString()

        let prompt = """
        Analysiere diese Körperfoto für Fitness-Fortschritte.
        Gib Feedback zu: Haltung, Symmetrie, sichtbarer Muskelentwicklung und allgemeiner Körperzusammensetzung.

        WICHTIG: Dies ist KEINE medizinische Diagnose. Alle Aussagen sind KI-Schätzungen.
        Bei Schmerzen Arzt oder Physiotherapeuten aufsuchen.

        Antworte auf Deutsch, freundlich und motivierend, maximal 200 Wörter.
        """

        let messages = [AnthropicMessage(role: "user", content: [
            .image(base64: base64),
            .text(prompt)
        ])]

        return try await send(systemPrompt: "", messages: messages, maxTokens: 512)
    }

    // MARK: - Helpers
    private func buildCoachSystemPrompt(profile: UserProfile) -> String {
        """
        Du bist APEX Coach, ein persönlicher KI-Fitness- und Lifestyle-Assistent.
        Antworte auf Deutsch, kurz und präzise.

        Nutzerprofil:
        - Name: \(profile.name)
        - Alter: \(profile.age) Jahre
        - Größe: \(Int(profile.heightCm)) cm
        - Gewicht: \(String(format: "%.1f", profile.weightKg)) kg
        - Ziel: \(profile.goalType.displayName)
        - Aktivitätslevel: \(profile.activityLevel.displayName)
        - Kalorienziel: \(profile.calorieGoal) kcal
        - Proteinziel: \(profile.proteinGoal)g

        Regeln:
        1. Keine medizinischen Diagnosen. Bei Schmerzen immer Arzt empfehlen.
        2. Alle Kalorienschätzungen als "KI-Schätzung" markieren.
        3. Motivierend, aber realistisch bleiben.
        4. Kurze, klare Antworten bevorzugen.
        """
    }

    private func extractJSON(from text: String) -> Data? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        let json = String(text[start...end])
        return json.data(using: .utf8)
    }
}

// MARK: - Meal Estimate DTO
struct MealEstimate: Decodable {
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let confidence: String
}
