import SwiftUI
import SwiftData

struct MobilityView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MobilityRoutine.createdAt) private var routines: [MobilityRoutine]
    @State private var showAddRoutine = false
    @State private var selectedTab    = 0

    private let tabs = ["Routinen", "Heute", "Knie & Gelenke"]

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Tab bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(tabs.indices, id: \.self) { i in
                            Button { withAnimation(.spring(response: 0.3)) { selectedTab = i } } label: {
                                Text(tabs[i])
                                    .font(.apexCallout)
                                    .foregroundStyle(selectedTab == i ? .black : .apexTextSecondary)
                                    .padding(.horizontal, Spacing.md).padding(.vertical, 8)
                                    .background(Capsule().fill(selectedTab == i ? Color.apexCyan : Color.white.opacity(0.08)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .padding(.vertical, Spacing.sm)

                switch selectedTab {
                case 0: routinenListe
                case 1: heutigeRoutinen
                default: knieProgramm
                }
            }
        }
        .navigationTitle("Mobility & Dehnung")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddRoutine = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(.apexCyan)
                }
            }
        }
        .sheet(isPresented: $showAddRoutine) { MobilityRoutineEditorView() }
        .onAppear { if routines.isEmpty { defaultRoutinesErstellen() } }
    }

    // MARK: - Routinen Liste
    private var routinenListe: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                if routines.isEmpty {
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "figure.flexibility").font(.system(size: 60)).foregroundStyle(.apexTextTertiary)
                        Text("Keine Routinen").font(.apexTitle2).foregroundStyle(.apexTextPrimary)
                        Text("Erstelle deine erste Mobilitätsroutine")
                            .font(.apexBody).foregroundStyle(.apexTextSecondary).multilineTextAlignment(.center)
                        APEXButton(title: "Routine erstellen", icon: "plus") { showAddRoutine = true }
                            .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(routines) { routine in
                        NavigationLink(destination: RoutineDetailView(routine: routine)) {
                            RoutineKarte(routine: routine)
                        }
                        .buttonStyle(.plain)
                        .apexPadding()
                    }
                }
            }
            .padding(.top, Spacing.sm).padding(.bottom, 80)
        }
    }

    // MARK: - Heutige Routinen
    private var heutigeRoutinen: some View {
        let today = Weekday.today
        let todayRoutines = routines.filter { $0.scheduledDays.contains(today) }

        return ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                if todayRoutines.isEmpty {
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60)).foregroundStyle(.apexGreen.opacity(0.5))
                        Text("Kein Mobility heute").font(.apexTitle2).foregroundStyle(.apexTextPrimary)
                        Text("Für heute sind keine Routinen geplant.")
                            .font(.apexBody).foregroundStyle(.apexTextSecondary)
                    }
                    .padding(.top, 60)
                } else {
                    Text("Für heute geplant")
                        .font(.apexCallout).foregroundStyle(.apexTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.md)

                    ForEach(todayRoutines) { routine in
                        NavigationLink(destination: RoutineDetailView(routine: routine)) {
                            RoutineKarte(routine: routine, hervorheben: true)
                        }
                        .buttonStyle(.plain)
                        .apexPadding()
                    }
                }
            }
            .padding(.top, Spacing.sm).padding(.bottom, 80)
        }
    }

    // MARK: - Knie Programm
    private var knieProgramm: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                // Disclaimer
                GlassCard {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "info.circle.fill").foregroundStyle(.apexBlue).font(.title2)
                        Text("Diese Übungen dienen der Prävention und Rehabilitation. Bei Schmerzen bitte einen Arzt oder Physiotherapeuten aufsuchen.")
                            .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                    }
                }
                .apexPadding()

                // Knie Programm Sections
                programmSektion(
                    title: "Kniestabilität",
                    icon: "figure.walk",
                    color: .apexCyan,
                    uebungen: kniestabilitaetUebungen
                )

                programmSektion(
                    title: "Hüftmobilität",
                    icon: "figure.flexibility",
                    color: .apexGreen,
                    uebungen: hueftUebungen
                )

                programmSektion(
                    title: "Sprunggelenk & Fuß",
                    icon: "figure.run",
                    color: .apexPurple,
                    uebungen: sprunggelenkUebungen
                )

                programmSektion(
                    title: "Oberschenkel & Dehnung",
                    icon: "figure.cooldown",
                    color: .apexOrange,
                    uebungen: dehnUebungen
                )
            }
            .padding(.bottom, 100)
        }
    }

    private func programmSektion(title: String, icon: String, color: Color, uebungen: [UebungInfo]) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                Spacer()
                Text("\(uebungen.count) Übungen").font(.apexCaption).foregroundStyle(.apexTextTertiary)
            }
            .apexPadding()

            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(uebungen) { ueb in
                        NavigationLink(destination: UebungsTimerView(uebung: ueb)) {
                            HStack(spacing: Spacing.md) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: Radius.sm)
                                        .fill(color.opacity(0.15)).frame(width: 36, height: 36)
                                    Image(systemName: icon).font(.caption).foregroundStyle(color)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(ueb.name).font(.apexBody).foregroundStyle(.apexTextPrimary)
                                    Text("\(ueb.saetze) × \(ueb.dauer)s · \(ueb.schwierigkeit)")
                                        .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.title2).foregroundStyle(color)
                            }
                            .padding(Spacing.md)
                        }
                        .buttonStyle(.plain)
                        if ueb.id != uebungen.last?.id {
                            Divider().background(.white.opacity(0.05))
                        }
                    }
                }
            }
            .apexPadding()
        }
    }

    // MARK: - Default Routinen
    private func defaultRoutinesErstellen() {
        let knie = MobilityRoutine(name: "Kniestabilität", scheduledDays: [.monday, .wednesday, .friday])
        context.insert(knie)
        let knieUeb: [(String, Int, Int)] = [
            ("Terminal Knee Extension", 30, 3), ("Wall Sit", 45, 3),
            ("Clamshells", 20, 3), ("Hip Hinge", 30, 3), ("Ankle Circles", 30, 2)
        ]
        for (i, (name, dur, sets)) in knieUeb.enumerated() {
            let ex = MobilityExercise(name: name, durationSeconds: dur, sets: sets, description: "", sortOrder: i)
            context.insert(ex); ex.routine = knie
        }

        let huefte = MobilityRoutine(name: "Hüftmobilität", scheduledDays: [.tuesday, .thursday])
        context.insert(huefte)
        let hueftUeb: [(String, Int, Int)] = [
            ("90/90 Hip Stretch", 60, 2), ("Pigeon Pose", 60, 2), ("Hip Flexor Stretch", 45, 3)
        ]
        for (i, (name, dur, sets)) in hueftUeb.enumerated() {
            let ex = MobilityExercise(name: name, durationSeconds: dur, sets: sets, description: "", sortOrder: i)
            context.insert(ex); ex.routine = huefte
        }

        let dehnen = MobilityRoutine(name: "Abend-Dehnen", scheduledDays: Weekday.allCases)
        context.insert(dehnen)
        let dehnUeb2: [(String, Int, Int)] = [
            ("Hamstring Stretch", 45, 2), ("Quadrizeps Stretch", 30, 2),
            ("Katzenbuckel", 30, 3), ("Kindspositur", 60, 2)
        ]
        for (i, (name, dur, sets)) in dehnUeb2.enumerated() {
            let ex = MobilityExercise(name: name, durationSeconds: dur, sets: sets, description: "", sortOrder: i)
            context.insert(ex); ex.routine = dehnen
        }

        try? context.save()
    }

    // MARK: - Übungs-Daten
    private var kniestabilitaetUebungen: [UebungInfo] {[
        UebungInfo(name: "Terminal Knee Extension", saetze: 3, dauer: 30, schwierigkeit: "Anfänger", beschreibung: "Steh auf einem Bein, beuge und strecke das Knie leicht. Stärkt den VMO-Muskel."),
        UebungInfo(name: "Wall Sit", saetze: 3, dauer: 45, schwierigkeit: "Mittel", beschreibung: "Rücken an der Wand, 90° Kniewinkel, Position halten."),
        UebungInfo(name: "Clamshells", saetze: 3, dauer: 20, schwierigkeit: "Anfänger", beschreibung: "Auf der Seite liegen, Knie angewinkelt, oberes Knie heben."),
        UebungInfo(name: "Single Leg Deadlift", saetze: 3, dauer: 30, schwierigkeit: "Mittel", beschreibung: "Einbeiniges Kreuzheben für Hüftstabilität."),
        UebungInfo(name: "Step-Up", saetze: 3, dauer: 40, schwierigkeit: "Anfänger", beschreibung: "Langsam eine Stufe hinauf- und hinuntersteigen.")
    ]}

    private var hueftUebungen: [UebungInfo] {[
        UebungInfo(name: "90/90 Hip Stretch", saetze: 2, dauer: 60, schwierigkeit: "Anfänger", beschreibung: "Beide Beine in 90° Winkel, aufrecht sitzen. Halten und wechseln."),
        UebungInfo(name: "Pigeon Pose", saetze: 2, dauer: 60, schwierigkeit: "Mittel", beschreibung: "Yoga-Pose für tiefe Hüftöffnung."),
        UebungInfo(name: "Hip Flexor Stretch", saetze: 3, dauer: 45, schwierigkeit: "Anfänger", beschreibung: "Kniender Ausfallschritt, Hüfte nach vorne drücken."),
        UebungInfo(name: "Butterfly Stretch", saetze: 2, dauer: 45, schwierigkeit: "Anfänger", beschreibung: "Sohlen zusammen, Knie nach außen drücken.")
    ]}

    private var sprunggelenkUebungen: [UebungInfo] {[
        UebungInfo(name: "Ankle Circles", saetze: 2, dauer: 30, schwierigkeit: "Anfänger", beschreibung: "Große Kreise mit dem Fuß in beide Richtungen."),
        UebungInfo(name: "Calf Raises", saetze: 3, dauer: 30, schwierigkeit: "Anfänger", beschreibung: "Auf den Zehenspitzen hoch- und heruntergehen."),
        UebungInfo(name: "Eccentric Calf Lowering", saetze: 3, dauer: 40, schwierigkeit: "Mittel", beschreibung: "Auf einer Stufe: langsam herunterlassen, normal hochgehen.")
    ]}

    private var dehnUebungen: [UebungInfo] {[
        UebungInfo(name: "Hamstring Stretch", saetze: 2, dauer: 45, schwierigkeit: "Anfänger", beschreibung: "Sitzend Bein strecken, Oberkörper nach vorne beugen."),
        UebungInfo(name: "Quadrizeps Stretch", saetze: 2, dauer: 30, schwierigkeit: "Anfänger", beschreibung: "Stehend Ferse zum Gesäß ziehen."),
        UebungInfo(name: "IT-Band Stretch", saetze: 2, dauer: 40, schwierigkeit: "Anfänger", beschreibung: "Stehend Bein überkreuzen, zur Seite lehnen."),
        UebungInfo(name: "Kindspositur", saetze: 2, dauer: 60, schwierigkeit: "Anfänger", beschreibung: "Knieend, Hüfte zu den Fersen, Arme nach vorne strecken.")
    ]}
}

// MARK: - Übung Info (static data)
struct UebungInfo: Identifiable {
    let id = UUID()
    var name: String
    var saetze: Int
    var dauer: Int
    var schwierigkeit: String
    var beschreibung: String
}

// MARK: - Routine Karte
struct RoutineKarte: View {
    var routine: MobilityRoutine
    var hervorheben: Bool = false

    var body: some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.apexGreen.opacity(0.15)).frame(width: 48, height: 48)
                    Image(systemName: "figure.flexibility").font(.title2).foregroundStyle(.apexGreen)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    Text("\(routine.exercises.count) Übungen · ca. \(routine.totalDurationSeconds / 60) Min.")
                        .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                    if !routine.scheduledDays.isEmpty {
                        Text(routine.scheduledDays.sorted { $0.rawValue < $1.rawValue }.map(\.shortName).joined(separator: ", "))
                            .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.apexTextTertiary)
            }
        }
        .if(hervorheben) { $0.overlay(RoundedRectangle(cornerRadius: Radius.lg + 2).stroke(Color.apexGreen.opacity(0.4), lineWidth: 1.5)) }
    }
}

// MARK: - Routine Detail
struct RoutineDetailView: View {
    @Bindable var routine: MobilityRoutine
    @Environment(\.modelContext) private var context
    @State private var activeExercise: MobilityExercise?
    @State private var showAddExercise = false
    @State private var editRoutine = false

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    // Summary card
                    GlassCard {
                        HStack(spacing: Spacing.xl) {
                            VStack(spacing: 3) {
                                Text("\(routine.exercises.count)").font(.apexTitle).foregroundStyle(.apexCyan)
                                Text("Übungen").font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            }
                            Divider().background(.white.opacity(0.1)).frame(height: 40)
                            VStack(spacing: 3) {
                                Text("\(routine.totalDurationSeconds / 60)").font(.apexTitle).foregroundStyle(.apexGreen)
                                Text("Minuten").font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            }
                            Divider().background(.white.opacity(0.1)).frame(height: 40)
                            VStack(spacing: 3) {
                                Text(routine.scheduledDays.isEmpty ? "–" : routine.scheduledDays.map(\.shortName).joined(separator: ","))
                                    .font(.apexCallout).foregroundStyle(.apexPurple)
                                Text("Tage").font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .apexPadding()

                    // Start all button
                    if !routine.exercises.isEmpty {
                        NavigationLink(destination: RoutineTimerView(routine: routine)) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Routine starten")
                            }
                            .font(.apexHeadline).foregroundStyle(.black)
                            .frame(maxWidth: .infinity).padding(Spacing.md)
                            .background { RoundedRectangle(cornerRadius: Radius.pill).fill(Color.apexAccentGradient) }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Spacing.md)
                    }

                    // Exercises
                    ForEach(routine.exercises.sorted { $0.sortOrder < $1.sortOrder }) { exercise in
                        MobilityUebungsZeile(exercise: exercise) { activeExercise = exercise }
                            .apexPadding()
                    }

                    Button { showAddExercise = true } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Übung hinzufügen")
                        }
                        .font(.apexBody).foregroundStyle(.apexGreen)
                        .frame(maxWidth: .infinity).padding(Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .stroke(Color.apexGreen.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        }
                    }
                    .buttonStyle(.plain).padding(.horizontal, Spacing.md)
                }
                .padding(.top, Spacing.md).padding(.bottom, 80)
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editRoutine = true } label: {
                    Image(systemName: "pencil").foregroundStyle(.apexCyan)
                }
            }
        }
        .sheet(item: $activeExercise) { ex in MobilityTimerView(exercise: ex) }
        .sheet(isPresented: $showAddExercise) { MobilityExerciseEditorView(routine: routine) }
        .sheet(isPresented: $editRoutine) { MobilityRoutineEditorView(routine: routine) }
    }
}

struct MobilityUebungsZeile: View {
    var exercise: MobilityExercise
    var onStart: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    HStack(spacing: Spacing.sm) {
                        Label("\(exercise.sets)×", systemImage: "repeat")
                        Label("\(exercise.durationSeconds)s", systemImage: "timer")
                    }
                    .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                    if !exercise.exerciseDescription.isEmpty {
                        Text(exercise.exerciseDescription)
                            .font(.apexCaption).foregroundStyle(.apexTextTertiary).lineLimit(2)
                    }
                }
                Spacer()
                Button(action: onStart) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40)).foregroundStyle(.apexGreen)
                        .glowEffect(color: .apexGreen, radius: 6)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Übungs Timer View (für statische Daten)
struct UebungsTimerView: View {
    var uebung: UebungInfo
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: Int
    @State private var currentSet = 1
    @State private var isRunning  = false
    @State private var timer: Timer?
    @State private var isFinished = false

    init(uebung: UebungInfo) {
        self.uebung = uebung
        _timeRemaining = State(initialValue: uebung.dauer)
    }

    var body: some View {
        NavigationStack {
            timerContent
                .navigationTitle(uebung.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Schließen") { dismiss() }.foregroundStyle(.apexCyan)
                    }
                }
        }
    }

    private var timerContent: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            VStack(spacing: Spacing.xl) {
                Text("Satz \(currentSet) / \(uebung.saetze)")
                    .font(.apexBody).foregroundStyle(.apexTextSecondary)
                    .padding(.top, Spacing.xl)

                // Timer ring
                ZStack {
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 18)
                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(uebung.dauer))
                        .stroke(Color.apexGreen, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)
                    Text(timeRemaining.durationFormatted)
                        .font(.system(size: 56, weight: .black, design: .monospaced))
                        .foregroundStyle(.apexTextPrimary)
                }
                .frame(width: 240, height: 240)

                Text(uebung.beschreibung)
                    .font(.apexBody).foregroundStyle(.apexTextSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, Spacing.xl)

                if isFinished {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 60)).foregroundStyle(.apexGreen)
                        Text("Fertig!").font(.apexTitle).foregroundStyle(.apexTextPrimary)
                        APEXButton(title: "Schließen") { dismiss() }
                            .padding(.horizontal, Spacing.xl)
                    }
                } else {
                    HStack(spacing: Spacing.xl) {
                        Button { resetTimer() } label: {
                            Image(systemName: "arrow.counterclockwise").font(.title2).foregroundStyle(.apexTextSecondary)
                        }
                        Button { toggleTimer() } label: {
                            Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 72)).foregroundStyle(.apexGreen)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
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
            if currentSet < uebung.saetze {
                currentSet += 1
                timeRemaining = uebung.dauer
                isRunning = false
            } else {
                isFinished = true
            }
        }
    }

    private func resetTimer() {
        timer?.invalidate(); isRunning = false; timeRemaining = uebung.dauer
    }
}

// MARK: - Routine Timer (complete routine flow)
struct RoutineTimerView: View {
    var routine: MobilityRoutine
    @Environment(\.dismiss) private var dismiss
    @State private var currentExerciseIndex = 0
    @State private var currentSet = 1
    @State private var timeRemaining: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var isRestPhase = false
    @State private var isFinished  = false
    @State private var restSeconds = 15

    private var sortedExercises: [MobilityExercise] {
        routine.exercises.sorted { $0.sortOrder < $1.sortOrder }
    }
    private var currentExercise: MobilityExercise? {
        guard currentExerciseIndex < sortedExercises.count else { return nil }
        return sortedExercises[currentExerciseIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                if isFinished {
                    fertigView
                } else if let ex = currentExercise {
                    aktiveUebung(ex)
                }
            }
            .navigationTitle(routine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Beenden") { dismiss() }.foregroundStyle(.apexRed)
                }
            }
            .onAppear {
                if let first = sortedExercises.first { timeRemaining = first.durationSeconds }
            }
            .onDisappear { timer?.invalidate() }
        }
    }

    private func aktiveUebung(_ ex: MobilityExercise) -> some View {
        VStack(spacing: Spacing.xl) {
            // Progress bar
            progressBar

            Spacer()

            Text(isRestPhase ? "Pause" : ex.name)
                .font(.apexTitle).foregroundStyle(isRestPhase ? .apexOrange : .apexTextPrimary)
            if !isRestPhase {
                Text("Satz \(currentSet) von \(ex.sets)")
                    .font(.apexBody).foregroundStyle(.apexTextSecondary)
            }

            ZStack {
                Circle().stroke(Color.white.opacity(0.08), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(isRestPhase ? restSeconds : ex.durationSeconds))
                    .stroke(isRestPhase ? Color.apexOrange : Color.apexGreen, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                Text(timeRemaining.durationFormatted)
                    .font(.system(size: 52, weight: .black, design: .monospaced))
                    .foregroundStyle(.apexTextPrimary)
            }
            .frame(width: 220, height: 220)

            if !isRestPhase, !ex.exerciseDescription.isEmpty {
                Text(ex.exerciseDescription)
                    .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, Spacing.xl)
            }

            Button { toggleTimer() } label: {
                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(isRestPhase ? Color.apexOrange : Color.apexGreen)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(Array(sortedExercises.enumerated()), id: \.offset) { i, _ in
                    Capsule()
                        .fill(i < currentExerciseIndex ? Color.apexGreen : (i == currentExerciseIndex ? Color.apexCyan : Color.white.opacity(0.15)))
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, Spacing.md)
            Text("\(currentExerciseIndex + 1)/\(sortedExercises.count)")
                .font(.apexCaption).foregroundStyle(.apexTextTertiary)
        }
    }

    private var fertigView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80)).foregroundStyle(.apexGreen).glowEffect(color: .apexGreen)
            Text("Routine abgeschlossen!").font(.apexTitle).foregroundStyle(.apexTextPrimary)
            Text("Super gemacht! 💪").font(.apexBody).foregroundStyle(.apexTextSecondary)
            APEXButton(title: "Fertig", icon: "checkmark") { dismiss() }
                .padding(.horizontal, Spacing.xl)
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
        guard timeRemaining > 0 else {
            timer?.invalidate()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            moveToNext()
            return
        }
        timeRemaining -= 1
    }

    private func moveToNext() {
        if isRestPhase {
            isRestPhase = false
            if let ex = currentExercise { timeRemaining = ex.durationSeconds }
            isRunning = false
            return
        }
        guard let ex = currentExercise else { return }
        if currentSet < ex.sets {
            currentSet += 1
            isRestPhase = true
            timeRemaining = restSeconds
            isRunning = false
        } else {
            currentExerciseIndex += 1
            currentSet = 1
            if currentExerciseIndex >= sortedExercises.count {
                isFinished = true
                timer?.invalidate()
            } else {
                isRestPhase = true
                timeRemaining = restSeconds
                isRunning = false
            }
        }
    }
}
