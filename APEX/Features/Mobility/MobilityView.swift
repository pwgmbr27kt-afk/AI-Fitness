import SwiftUI
import SwiftData

struct MobilityView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MobilityRoutine.createdAt) private var routines: [MobilityRoutine]
    @State private var showAddRoutine = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(routines) { routine in
                            NavigationLink(destination: MobilityRoutineDetailView(routine: routine)) {
                                MobilityRoutineCard(routine: routine)
                            }
                            .buttonStyle(.plain)
                            .apexPadding()
                        }

                        APEXButton(title: "Routine hinzufügen", icon: "plus") { showAddRoutine = true }
                            .padding(.horizontal, Spacing.md)
                    }
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("Mobilität")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddRoutine = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.apexCyan)
                    }
                }
            }
            .sheet(isPresented: $showAddRoutine) { MobilityRoutineEditorView() }
            .onAppear { if routines.isEmpty { createDefaultRoutines() } }
        }
    }

    private func createDefaultRoutines() {
        // Knee stability starter template
        let kneeRoutine = MobilityRoutine(
            name: "Kniestabilität",
            scheduledDays: [.monday, .wednesday, .friday],
            notes: "Vorbeugung & Rehabilitation für das Kniegelenk"
        )
        context.insert(kneeRoutine)

        let exercises: [(String, Int, Int, String)] = [
            ("Terminal Knee Extension", 30, 3, "Steh auf einem Bein, beuge leicht das Knie und strecke es wieder aus."),
            ("Wall Sit", 45, 3, "Rücken an der Wand, 90° Kniewinkel, Position halten."),
            ("Clamshells", 20, 3, "Auf der Seite liegen, Knie angewinkelt, oberes Knie heben."),
            ("Hip Hinge", 30, 3, "Hüfte nach hinten schieben, Rücken gerade halten."),
            ("Ankle Circles", 30, 2, "Große Kreise mit dem Fuß in beide Richtungen.")
        ]

        for (i, (name, duration, sets, desc)) in exercises.enumerated() {
            let ex = MobilityExercise(name: name, durationSeconds: duration, sets: sets, description: desc, sortOrder: i)
            context.insert(ex)
            ex.routine = kneeRoutine
        }

        // Hip mobility
        let hipRoutine = MobilityRoutine(name: "Hüftmobilität", scheduledDays: [.tuesday, .thursday])
        context.insert(hipRoutine)
        let hipExercises: [(String, Int, Int, String)] = [
            ("90/90 Hip Stretch", 60, 2, "Beide Beine in 90° Winkel, aufrecht sitzen."),
            ("Pigeon Pose", 60, 2, "Vorderes Bein quer, hinteres Bein gestreckt."),
            ("Hip Flexor Stretch", 45, 3, "Kniender Ausfallschritt, Hüfte nach vorne drücken.")
        ]
        for (i, (name, duration, sets, desc)) in hipExercises.enumerated() {
            let ex = MobilityExercise(name: name, durationSeconds: duration, sets: sets, description: desc, sortOrder: i)
            context.insert(ex)
            ex.routine = hipRoutine
        }

        try? context.save()
    }
}

struct MobilityRoutineCard: View {
    var routine: MobilityRoutine

    var body: some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.apexCyan.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "figure.flexibility")
                        .font(.title2)
                        .foregroundStyle(.apexCyan)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    Text("\(routine.exercises.count) Übungen · \(routine.totalDurationSeconds / 60) Min.")
                        .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                    if !routine.scheduledDays.isEmpty {
                        Text(routine.scheduledDays.map(\.shortName).joined(separator: ", "))
                            .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.apexTextTertiary)
            }
        }
    }
}

struct MobilityRoutineDetailView: View {
    @Bindable var routine: MobilityRoutine
    @Environment(\.modelContext) private var context
    @State private var activeExercise: MobilityExercise?
    @State private var showAddExercise = false

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(routine.exercises.sorted { $0.sortOrder < $1.sortOrder }) { exercise in
                        MobilityExerciseRow(exercise: exercise) {
                            activeExercise = exercise
                        }
                        .apexPadding()
                    }

                    Button { showAddExercise = true } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Übung hinzufügen")
                        }
                        .font(.apexBody).foregroundStyle(.apexCyan)
                        .frame(maxWidth: .infinity).padding(Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .stroke(Color.apexCyan.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.md)
                }
                .padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle(routine.name)
        .sheet(item: $activeExercise) { ex in MobilityTimerView(exercise: ex) }
        .sheet(isPresented: $showAddExercise) { MobilityExerciseEditorView(routine: routine) }
    }
}

struct MobilityExerciseRow: View {
    var exercise: MobilityExercise
    var onStart: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    Text("\(exercise.sets) Sätze · \(exercise.durationSeconds)s")
                        .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                    if !exercise.exerciseDescription.isEmpty {
                        Text(exercise.exerciseDescription)
                            .font(.apexCaption).foregroundStyle(.apexTextTertiary).lineLimit(2)
                    }
                }
                Spacer()
                Button(action: onStart) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.apexCyan)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MobilityTimerView: View {
    var exercise: MobilityExercise
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: Int
    @State private var currentSet = 1
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var isFinished = false

    init(exercise: MobilityExercise) {
        self.exercise = exercise
        _timeRemaining = State(initialValue: exercise.durationSeconds)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                VStack(spacing: Spacing.xl) {
                    Text(exercise.name).font(.apexTitle).foregroundStyle(.apexTextPrimary)
                    Text("Satz \(currentSet) / \(exercise.sets)")
                        .font(.apexBody).foregroundStyle(.apexTextSecondary)

                    // Timer ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 16)
                        Circle()
                            .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(exercise.durationSeconds))
                            .stroke(Color.apexCyan, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timeRemaining)
                        Text(timeRemaining.durationFormatted)
                            .font(.system(size: 52, weight: .bold, design: .monospaced))
                            .foregroundStyle(.apexTextPrimary)
                    }
                    .frame(width: 220, height: 220)

                    if !exercise.exerciseDescription.isEmpty {
                        Text(exercise.exerciseDescription)
                            .font(.apexBody).foregroundStyle(.apexTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }

                    if isFinished {
                        Text("Fertig! 🎉")
                            .font(.apexTitle).foregroundStyle(.apexGreen)
                        APEXButton(title: "Schließen") { dismiss() }
                            .padding(.horizontal, Spacing.xl)
                    } else {
                        HStack(spacing: Spacing.lg) {
                            Button { resetTimer() } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2).foregroundStyle(.apexTextSecondary)
                            }
                            Button { toggleTimer() } label: {
                                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(.apexCyan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
            }
        }
    }

    private func toggleTimer() {
        isRunning.toggle()
        if isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in tick() }
        } else {
            timer?.invalidate()
        }
    }

    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timer?.invalidate()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            if currentSet < exercise.sets {
                currentSet += 1
                timeRemaining = exercise.durationSeconds
                isRunning = false
            } else {
                isFinished = true
            }
        }
    }

    private func resetTimer() {
        timer?.invalidate()
        isRunning = false
        timeRemaining = exercise.durationSeconds
    }
}

struct MobilityRoutineEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var notes = ""
    @State private var selectedDays: Set<Weekday> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Name").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("z.B. Morgen-Mobilität", text: $name)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Wochentage").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                HStack(spacing: Spacing.xs) {
                                    ForEach(Weekday.allCases) { day in
                                        let isOn = selectedDays.contains(day)
                                        Button {
                                            if isOn { selectedDays.remove(day) } else { selectedDays.insert(day) }
                                        } label: {
                                            Text(day.shortName).font(.apexCaption)
                                                .foregroundStyle(isOn ? .black : .apexTextSecondary)
                                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                                                .background {
                                                    RoundedRectangle(cornerRadius: Radius.sm)
                                                        .fill(isOn ? Color.apexCyan : Color.white.opacity(0.06))
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Notizen").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("Optional…", text: $notes, axis: .vertical)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                            }
                        }
                    }
                    .apexPadding().padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("Neue Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        let r = MobilityRoutine(name: name, scheduledDays: Array(selectedDays), notes: notes)
                        context.insert(r)
                        try? context.save()
                        dismiss()
                    }
                    .foregroundStyle(name.isNotEmpty ? .apexCyan : .apexTextTertiary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct MobilityExerciseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var routine: MobilityRoutine
    @State private var name = ""
    @State private var duration = 30
    @State private var sets = 3
    @State private var description = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Übungsname").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("z.B. Hip Circles", text: $name)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                            }
                        }
                        GlassCard {
                            VStack(spacing: Spacing.md) {
                                Stepper("Dauer: \(duration)s", value: $duration, in: 5...300, step: 5)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                                Stepper("Sätze: \(sets)", value: $sets, in: 1...10)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Beschreibung").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("Optional…", text: $description, axis: .vertical)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                            }
                        }
                    }
                    .apexPadding().padding(.vertical, Spacing.md)
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
                        let ex = MobilityExercise(
                            name: name, durationSeconds: duration, sets: sets,
                            description: description, sortOrder: routine.exercises.count
                        )
                        context.insert(ex)
                        ex.routine = routine
                        try? context.save()
                        dismiss()
                    }
                    .foregroundStyle(name.isNotEmpty ? .apexCyan : .apexTextTertiary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
