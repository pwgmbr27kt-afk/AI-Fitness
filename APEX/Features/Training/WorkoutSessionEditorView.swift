import SwiftUI
import SwiftData

struct WorkoutSessionEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var existingSession: WorkoutSession? = nil

    @State private var sessionName = ""
    @State private var sessionDate = Date()
    @State private var exercises: [ExerciseDraft] = []
    @State private var showAddExercise = false

    struct ExerciseDraft: Identifiable {
        let id = UUID()
        var name: String
        var muscleGroup: MuscleGroup
        var sets: Int
        var reps: Int
        var weightKg: Double
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Session Name")
                                    .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("z.B. Push Day", text: $sessionName)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                                Divider().background(.white.opacity(0.1))
                                DatePicker("Datum", selection: $sessionDate, displayedComponents: .date)
                                    .colorScheme(.dark)
                            }
                        }

                        // Exercises
                        if !exercises.isEmpty {
                            GlassCard(padding: 0) {
                                VStack(spacing: 0) {
                                    ForEach(exercises) { draft in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(draft.name).font(.apexBody).foregroundStyle(.apexTextPrimary)
                                                Text("\(draft.sets) × \(draft.reps) @ \(Int(draft.weightKg))kg")
                                                    .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                                            }
                                            Spacer()
                                            Text(draft.muscleGroup.displayName)
                                                .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                                        }
                                        .padding(Spacing.md)
                                        if draft.id != exercises.last?.id {
                                            Divider().background(.white.opacity(0.06))
                                        }
                                    }
                                }
                            }
                        }

                        Button {
                            showAddExercise = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Übung hinzufügen")
                            }
                            .font(.apexBody).foregroundStyle(.apexCyan)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .background {
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .stroke(Color.apexCyan.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .apexPadding()
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(existingSession == nil ? "Neue Session" : "Session bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .foregroundStyle(sessionName.isNotEmpty ? .apexCyan : .apexTextTertiary)
                        .disabled(sessionName.isEmpty)
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseDraftSheet { draft in exercises.append(draft) }
            }
        }
    }

    private func save() {
        let session = existingSession ?? {
            let s = WorkoutSession(date: sessionDate, name: sessionName)
            context.insert(s)
            return s
        }()
        session.name = sessionName
        session.date = sessionDate

        for draft in exercises {
            let exercise = Exercise(name: draft.name, muscleGroup: draft.muscleGroup, sortOrder: session.exercises.count)
            context.insert(exercise)
            exercise.session = session
            for i in 0..<draft.sets {
                let set = ExerciseSet(reps: draft.reps, weightKg: draft.weightKg, sortOrder: i)
                context.insert(set)
                set.exercise = exercise
            }
        }
        try? context.save()
        dismiss()
    }
}

struct AddExerciseDraftSheet: View {
    var onAdd: (WorkoutSessionEditorView.ExerciseDraft) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var muscleGroup: MuscleGroup = .chest
    @State private var sets = 3
    @State private var reps = 8
    @State private var weightKg = 60.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Übungsname").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("z.B. Bankdrücken", text: $name)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Muskelgruppe").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                Picker("", selection: $muscleGroup) {
                                    ForEach(MuscleGroup.allCases, id: \.self) { g in
                                        Text(g.displayName).tag(g)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.apexCyan)
                            }
                        }
                        GlassCard {
                            VStack(spacing: Spacing.md) {
                                Stepper("Sätze: \(sets)", value: $sets, in: 1...10)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                                Stepper("Wiederholungen: \(reps)", value: $reps, in: 1...30)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                                HStack {
                                    Text("Gewicht: \(Int(weightKg)) kg")
                                        .font(.apexBody).foregroundStyle(.apexTextPrimary)
                                    Spacer()
                                    Stepper("", value: $weightKg, in: 0...500, step: 2.5)
                                }
                            }
                        }
                    }
                    .apexPadding()
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("Übung hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        onAdd(.init(name: name, muscleGroup: muscleGroup, sets: sets, reps: reps, weightKg: weightKg))
                        dismiss()
                    }
                    .foregroundStyle(name.isNotEmpty ? .apexCyan : .apexTextTertiary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
