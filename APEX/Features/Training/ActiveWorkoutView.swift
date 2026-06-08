import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: WorkoutSession

    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var showSummary = false

    private var sortedExercises: [Exercise] {
        session.exercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        // Timer card
                        timerCard

                        // Exercises
                        ForEach(sortedExercises) { exercise in
                            ExerciseCard(exercise: exercise)
                                .apexPadding()
                        }

                        // Finish button
                        APEXButton(title: "Workout beenden", icon: "checkmark") {
                            finishWorkout()
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { startTimer() }
            .onDisappear { stopTimer() }
            .sheet(isPresented: $showSummary) {
                WorkoutSummaryView(session: session)
            }
        }
    }

    private var timerCard: some View {
        AccentGlassCard {
            HStack {
                VStack(alignment: .leading) {
                    Text("Dauer")
                        .font(.apexCaption)
                        .foregroundStyle(.apexTextSecondary)
                    Text(elapsedSeconds.durationFormatted)
                        .font(.apexNumber)
                        .foregroundStyle(.apexCyan)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Volumen")
                        .font(.apexCaption)
                        .foregroundStyle(.apexTextSecondary)
                    Text(String(format: "%.0f kg", session.totalVolume))
                        .font(.apexNumber)
                        .foregroundStyle(.apexCyan)
                }
            }
        }
        .apexPadding()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func finishWorkout() {
        stopTimer()
        session.completedAt   = Date()
        session.durationSeconds = elapsedSeconds
        try? context.save()
        showSummary = true
    }
}

struct ExerciseCard: View {
    @Bindable var exercise: Exercise

    private var sortedSets: [ExerciseSet] {
        exercise.sets.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: exercise.muscleGroup.icon)
                        .foregroundStyle(.apexCyan)
                    Text(exercise.name)
                        .font(.apexHeadline)
                        .foregroundStyle(.apexTextPrimary)
                    Spacer()
                    Text("\(exercise.completedSetsCount)/\(exercise.totalSetsCount)")
                        .font(.apexCallout)
                        .foregroundStyle(.apexTextSecondary)
                }
                .padding(Spacing.md)

                Divider().background(.white.opacity(0.06))

                // Set headers
                HStack {
                    Text("Satz").frame(width: 40, alignment: .leading)
                    Spacer()
                    Text("Wdh.").frame(width: 50, alignment: .center)
                    Text("kg").frame(width: 60, alignment: .center)
                    Text("✓").frame(width: 36, alignment: .center)
                }
                .font(.apexCaption)
                .foregroundStyle(.apexTextTertiary)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, set in
                    SetRow(set: set, setNumber: index + 1)
                        .padding(.horizontal, Spacing.md)
                }
                .padding(.bottom, Spacing.sm)
            }
        }
    }
}

struct SetRow: View {
    @Bindable var set: ExerciseSet
    var setNumber: Int

    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.apexCallout)
                .foregroundStyle(.apexTextTertiary)
                .frame(width: 40, alignment: .leading)

            Spacer()

            // Reps stepper
            HStack(spacing: 4) {
                Button { if set.reps > 1 { set.reps -= 1 } } label: {
                    Image(systemName: "minus").font(.caption)
                }
                Text("\(set.reps)").font(.apexCallout).frame(width: 30, alignment: .center)
                Button { set.reps += 1 } label: {
                    Image(systemName: "plus").font(.caption)
                }
            }
            .foregroundStyle(.apexTextPrimary)
            .frame(width: 80)

            // Weight stepper
            HStack(spacing: 4) {
                Button { if set.weightKg >= 2.5 { set.weightKg -= 2.5 } } label: {
                    Image(systemName: "minus").font(.caption)
                }
                Text("\(Int(set.weightKg))").font(.apexCallout).frame(width: 36, alignment: .center)
                Button { set.weightKg += 2.5 } label: {
                    Image(systemName: "plus").font(.caption)
                }
            }
            .foregroundStyle(.apexTextPrimary)
            .frame(width: 80)

            // Complete toggle
            Button {
                withAnimation(.spring(response: 0.3)) {
                    set.isCompleted.toggle()
                }
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? .apexGreen : .apexTextTertiary)
            }
            .frame(width: 36)
        }
        .padding(.vertical, 6)
        .buttonStyle(.plain)
    }
}

struct WorkoutSummaryView: View {
    var session: WorkoutSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Trophy
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.apexYellow)
                                .glowEffect(color: .apexYellow)
                            Text("Workout abgeschlossen!")
                                .font(.apexTitle)
                                .foregroundStyle(.apexTextPrimary)
                        }
                        .padding(.top, Spacing.xl)

                        // Stats
                        HStack(spacing: Spacing.md) {
                            summaryStatCard(value: session.durationSeconds?.durationFormatted ?? "–", label: "Dauer")
                            summaryStatCard(value: String(format: "%.0f kg", session.totalVolume), label: "Volumen")
                            summaryStatCard(value: "\(session.exercises.count)", label: "Übungen")
                        }
                        .apexPadding()

                        // Exercise breakdown
                        ForEach(session.exercises.sorted { $0.sortOrder < $1.sortOrder }) { exercise in
                            GlassCard {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text(exercise.name).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                                    ForEach(Array(exercise.sets.sorted { $0.sortOrder < $1.sortOrder }.enumerated()), id: \.element.id) { i, s in
                                        HStack {
                                            Text("Satz \(i+1)").font(.apexCaption).foregroundStyle(.apexTextTertiary)
                                            Spacer()
                                            Text("\(s.reps) × \(Int(s.weightKg)) kg")
                                                .font(.apexCallout)
                                                .foregroundStyle(s.isCompleted ? .apexTextPrimary : .apexTextTertiary)
                                        }
                                    }
                                }
                            }
                            .apexPadding()
                        }

                        APEXButton(title: "Fertig", icon: "checkmark") { dismiss() }
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Zusammenfassung")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func summaryStatCard(value: String, label: String) -> some View {
        GlassCard {
            VStack(spacing: 4) {
                Text(value).font(.apexTitle2).foregroundStyle(.apexCyan)
                Text(label).font(.apexCaption).foregroundStyle(.apexTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
