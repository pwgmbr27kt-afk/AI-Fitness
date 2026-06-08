import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var currentStep = 0
    @State private var profile = OnboardingData()
    @State private var isAnimating = false

    private let totalSteps = 5

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#050510"), Color(hex: "#0A0A1F"), Color(hex: "#050510")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient orbs
            ambientOrbs

            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.top, 60)
                    .padding(.horizontal, Spacing.lg)

                // Step content
                TabView(selection: $currentStep) {
                    WelcomeStep(onNext: nextStep)
                        .tag(0)
                    NameAgeStep(name: $profile.name, birthDate: $profile.birthDate, onNext: nextStep)
                        .tag(1)
                    BodyStep(heightCm: $profile.heightCm, weightKg: $profile.weightKg, onNext: nextStep)
                        .tag(2)
                    GoalStep(goalType: $profile.goalType, activityLevel: $profile.activityLevel, onNext: nextStep)
                        .tag(3)
                    SummaryStep(profile: profile, onComplete: completeOnboarding)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.apexCyan : Color.white.opacity(0.15))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Ambient Orbs
    private var ambientOrbs: some View {
        ZStack {
            Circle()
                .fill(Color.apexCyan.opacity(0.06))
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -200)
                .blur(radius: 60)

            Circle()
                .fill(Color.apexBlue.opacity(0.08))
                .frame(width: 300, height: 300)
                .offset(x: 150, y: 300)
                .blur(radius: 50)
        }
    }

    private func nextStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }

    private func completeOnboarding() {
        // Create UserProfile in SwiftData
        let userProfile = UserProfile(
            name: profile.name,
            birthDate: profile.birthDate,
            heightCm: profile.heightCm,
            weightKg: profile.weightKg,
            goalType: profile.goalType,
            activityLevel: profile.activityLevel,
            onboardingCompleted: true
        )

        // Apply suggested goals
        let goals = userProfile.suggestedGoals()
        userProfile.calorieGoal = goals.calories
        userProfile.proteinGoal = goals.protein
        userProfile.carbGoal    = goals.carbs
        userProfile.fatGoal     = goals.fat
        userProfile.waterGoalMl = goals.water

        context.insert(userProfile)

        // Create default day sections
        for sectionData in AppConfiguration.defaultSections {
            let section = DaySection(
                name: sectionData.name,
                icon: sectionData.icon,
                sortOrder: sectionData.sortOrder,
                colorHex: sectionData.colorHex
            )
            context.insert(section)
        }

        // Initial body entry
        let bodyEntry = BodyEntry(date: Date(), weightKg: profile.weightKg)
        context.insert(bodyEntry)

        try? context.save()
    }
}

// MARK: - Onboarding Data
struct OnboardingData {
    var name: String = ""
    var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var heightCm: Double = 175
    var weightKg: Double = 75
    var goalType: GoalType = .maintain
    var activityLevel: ActivityLevel = .moderate
}
