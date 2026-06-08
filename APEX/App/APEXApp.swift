import SwiftUI
import SwiftData

@main
struct APEXApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for:
                    UserProfile.self,
                    DaySection.self,
                    APEXTask.self,
                    WorkoutPlan.self,
                    WorkoutSession.self,
                    Exercise.self,
                    ExerciseSet.self,
                    DayNutrition.self,
                    Meal.self,
                    BodyEntry.self,
                    Reminder.self,
                    MobilityRoutine.self,
                    MobilityExercise.self,
                    ChatMessage.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if profiles.isEmpty || !(profiles.first?.onboardingCompleted ?? false) {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}
