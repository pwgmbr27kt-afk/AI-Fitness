import Foundation

enum AppConfiguration {
    static let appName = "APEX"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // Anthropic
    static let anthropicAPIEndpoint = "https://api.anthropic.com/v1/messages"
    static let anthropicModel = "claude-sonnet-4-20250514"
    static let anthropicAPIVersion = "2023-06-01"

    // App Groups
    static let appGroupIdentifier = "group.com.apex.fitness"

    // CloudKit
    static let cloudKitContainer = "iCloud.com.apex.fitness"

    // Keychain
    static let keychainServiceName = "com.apex.fitness"
    static let keychainAPIKeyAccount = "anthropic_api_key"

    // Default Goals
    static let defaultCalorieGoal = 2500
    static let defaultProteinGoal = 180
    static let defaultCarbGoal = 280
    static let defaultFatGoal = 80
    static let defaultWaterGoalMl = 3000

    // Default Day Sections
    static let defaultSections: [(name: String, icon: String, sortOrder: Int, colorHex: String)] = [
        ("Morgen",            "sunrise.fill",   0, "#FFB347"),
        ("Mittag",            "sun.max.fill",   1, "#00D4FF"),
        ("Abend",             "sunset.fill",    2, "#FF6B6B"),
        ("Vor dem Schlafen",  "moon.stars.fill", 3, "#9B59B6")
    ]
}
