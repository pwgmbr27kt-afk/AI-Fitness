import SwiftUI

// MARK: - Step 0: Welcome
struct WelcomeStep: View {
    var onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Logo
            ZStack {
                Circle()
                    .fill(Color.apexAccentGradient)
                    .frame(width: 100, height: 100)
                    .glowEffect()
                Text("A")
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: Spacing.sm) {
                Text("APEX")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.apexTextPrimary)

                Text("Dein persönlicher\nFitness-Assistent")
                    .font(.apexTitle2)
                    .foregroundStyle(.apexTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .slideUp(delay: 0.2)

            Spacer()

            VStack(spacing: Spacing.md) {
                featureBadge(icon: "dumbbell.fill",    text: "Training planen & tracken")
                featureBadge(icon: "fork.knife",       text: "Ernährung im Blick behalten")
                featureBadge(icon: "brain.head.profile", text: "KI-Coach rund um die Uhr")
            }
            .slideUp(delay: 0.4)

            Spacer()

            APEXButton(title: "Loslegen", icon: "arrow.right") { onNext() }
                .padding(.horizontal, Spacing.lg)
                .slideUp(delay: 0.6)
                .padding(.bottom, Spacing.xxl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }

    private func featureBadge(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.apexCyan)
                .frame(width: 32)
            Text(text)
                .font(.apexBody)
                .foregroundStyle(.apexTextSecondary)
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Step 1: Name & Age
struct NameAgeStep: View {
    @Binding var name: String
    @Binding var birthDate: Date
    var onNext: () -> Void
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.xl) {
            stepHeader(icon: "person.fill", title: "Wie heißt du?", subtitle: "Damit ich dich persönlich ansprechen kann")

            VStack(spacing: Spacing.md) {
                // Name field
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Dein Name")
                        .font(.apexCallout)
                        .foregroundStyle(.apexTextSecondary)

                    TextField("z.B. Max", text: $name)
                        .font(.apexTitle2)
                        .foregroundStyle(.apexTextPrimary)
                        .focused($nameFieldFocused)
                        .padding(Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: Radius.md)
                                        .stroke(nameFieldFocused ? Color.apexCyan : Color.white.opacity(0.1), lineWidth: 1)
                                }
                        }
                }

                // Birth date
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Geburtsdatum")
                        .font(.apexCallout)
                        .foregroundStyle(.apexTextSecondary)

                    DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .padding(Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: Radius.md)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                }
                        }
                }
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            APEXButton(title: "Weiter", icon: "arrow.right", isEnabled: name.count >= 2) { onNext() }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
        }
        .onAppear { nameFieldFocused = true }
    }
}

// MARK: - Step 2: Body Measurements
struct BodyStep: View {
    @Binding var heightCm: Double
    @Binding var weightKg: Double
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            stepHeader(icon: "figure.stand", title: "Dein Körper", subtitle: "Für genaue Kalorienberechnung")

            VStack(spacing: Spacing.lg) {
                // Height
                measurementPicker(
                    label: "Größe",
                    value: $heightCm,
                    range: 140...220,
                    step: 1,
                    unit: "cm",
                    color: .apexCyan
                )

                // Weight
                measurementPicker(
                    label: "Gewicht",
                    value: $weightKg,
                    range: 40...200,
                    step: 0.5,
                    unit: "kg",
                    color: .apexBlue
                )
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            APEXButton(title: "Weiter", icon: "arrow.right") { onNext() }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
        }
    }

    private func measurementPicker(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String, color: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(label)
                    .font(.apexCallout)
                    .foregroundStyle(.apexTextSecondary)

                HStack {
                    Text("\(Int(value.wrappedValue))")
                        .font(.apexNumber)
                        .foregroundStyle(color)
                    Text(unit)
                        .font(.apexHeadline)
                        .foregroundStyle(.apexTextSecondary)
                    Spacer()
                }

                Slider(value: value, in: range, step: step)
                    .tint(color)
            }
        }
    }
}

// MARK: - Step 3: Goal Selection
struct GoalStep: View {
    @Binding var goalType: GoalType
    @Binding var activityLevel: ActivityLevel
    var onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                stepHeader(icon: "target", title: "Dein Ziel", subtitle: "Wofür trainierst du?")
                    .padding(.horizontal, Spacing.lg)

                // Goal type
                VStack(spacing: Spacing.sm) {
                    ForEach(GoalType.allCases, id: \.self) { goal in
                        goalCard(goal: goal)
                    }
                }
                .padding(.horizontal, Spacing.lg)

                // Activity level
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Aktivitätslevel")
                        .font(.apexHeadline)
                        .foregroundStyle(.apexTextPrimary)
                        .padding(.horizontal, Spacing.lg)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                activityChip(level: level)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                }

                APEXButton(title: "Weiter", icon: "arrow.right") { onNext() }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
            }
            .padding(.top, Spacing.xl)
        }
    }

    private func goalCard(goal: GoalType) -> some View {
        let isSelected = goalType == goal
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                goalType = goal
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .black : .apexCyan)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.displayName)
                        .font(.apexHeadline)
                        .foregroundStyle(isSelected ? .black : .apexTextPrimary)
                    Text(goal.description)
                        .font(.apexCaption)
                        .foregroundStyle(isSelected ? .black.opacity(0.7) : .apexTextSecondary)
                }
                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.black)
                }
            }
            .padding(Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(isSelected ? Color.apexCyan : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(isSelected ? .clear : Color.white.opacity(0.1), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private func activityChip(level: ActivityLevel) -> some View {
        let isSelected = activityLevel == level
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                activityLevel = level
            }
        } label: {
            Text(level.displayName)
                .font(.apexCallout)
                .foregroundStyle(isSelected ? .black : .apexTextSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background {
                    Capsule().fill(isSelected ? Color.apexCyan : Color.white.opacity(0.08))
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 4: Summary
struct SummaryStep: View {
    var profile: OnboardingData
    var onComplete: () -> Void

    private var tempProfile: UserProfile {
        UserProfile(
            name: profile.name,
            birthDate: profile.birthDate,
            heightCm: profile.heightCm,
            weightKg: profile.weightKg,
            goalType: profile.goalType,
            activityLevel: profile.activityLevel
        )
    }

    private var goals: (calories: Int, protein: Int, carbs: Int, fat: Int, water: Int) {
        tempProfile.suggestedGoals()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                stepHeader(icon: "checkmark.seal.fill", title: "Bereit, \(profile.name)!", subtitle: "Deine personalisierten Ziele")
                    .padding(.horizontal, Spacing.lg)

                // Goals summary
                AccentGlassCard {
                    VStack(spacing: Spacing.md) {
                        goalRow(icon: "flame.fill", label: "Kalorien", value: "\(goals.calories) kcal", color: .apexOrange)
                        Divider().background(.white.opacity(0.1))
                        goalRow(icon: "bolt.fill", label: "Protein", value: "\(goals.protein)g", color: .apexCyan)
                        Divider().background(.white.opacity(0.1))
                        goalRow(icon: "drop.fill", label: "Wasser", value: "\(goals.water / 1000)L", color: .apexBlue)
                    }
                }
                .padding(.horizontal, Spacing.lg)

                Text("Alle Ziele lassen sich später in den Einstellungen anpassen.")
                    .font(.apexCallout)
                    .foregroundStyle(.apexTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                APEXButton(title: "App starten", icon: "arrow.right") { onComplete() }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
            }
            .padding(.top, Spacing.xl)
        }
    }

    private func goalRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(.apexBody)
                .foregroundStyle(.apexTextSecondary)
            Spacer()
            Text(value)
                .font(.apexHeadline)
                .foregroundStyle(.apexTextPrimary)
        }
    }
}

// MARK: - Shared helpers
@ViewBuilder
func stepHeader(icon: String, title: String, subtitle: String) -> some View {
    VStack(spacing: Spacing.md) {
        Image(systemName: icon)
            .font(.system(size: 44))
            .foregroundStyle(.apexCyan)

        VStack(spacing: Spacing.xs) {
            Text(title)
                .font(.apexLargeTitle)
                .foregroundStyle(.apexTextPrimary)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.apexBody)
                .foregroundStyle(.apexTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
    .padding(.top, Spacing.xl)
}

// MARK: - APEX Button
struct APEXButton: View {
    var title: String
    var icon: String? = nil
    var style: Style = .primary
    var isEnabled: Bool = true
    var action: () -> Void

    enum Style { case primary, secondary, destructive }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.apexHeadline)
                if let icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: Radius.pill)
                    .fill(backgroundColor)
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:     return .black
        case .secondary:   return .apexCyan
        case .destructive: return .white
        }
    }

    private var backgroundColor: some ShapeStyle {
        switch style {
        case .primary:     return AnyShapeStyle(Color.apexAccentGradient)
        case .secondary:   return AnyShapeStyle(Color.white.opacity(0.08))
        case .destructive: return AnyShapeStyle(Color.apexRed)
        }
    }
}
