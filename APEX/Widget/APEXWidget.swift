import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry
struct APEXWidgetEntry: TimelineEntry {
    let date: Date
    var taskProgress: Double
    var caloriesCurrent: Int
    var caloriesGoal: Int
    var proteinCurrent: Double
    var proteinGoal: Int
    var waterCurrentMl: Int
    var waterGoalMl: Int
    var nextReminderTitle: String?
    var nextReminderTime: Date?
    var userName: String
}

// MARK: - Timeline Provider
struct APEXWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> APEXWidgetEntry {
        APEXWidgetEntry(
            date: Date(),
            taskProgress: 0.6,
            caloriesCurrent: 1800,
            caloriesGoal: 2500,
            proteinCurrent: 120,
            proteinGoal: 180,
            waterCurrentMl: 1500,
            waterGoalMl: 3000,
            nextReminderTitle: "Vitamine",
            nextReminderTime: Date().addingTimeInterval(3600),
            userName: "Max"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (APEXWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<APEXWidgetEntry>) -> Void) {
        // Read from App Group UserDefaults for live data
        let defaults = UserDefaults(suiteName: AppConfiguration.appGroupIdentifier)
        let entry = APEXWidgetEntry(
            date: Date(),
            taskProgress: defaults?.double(forKey: "widget.taskProgress") ?? 0,
            caloriesCurrent: defaults?.integer(forKey: "widget.calories") ?? 0,
            caloriesGoal: defaults?.integer(forKey: "widget.calorieGoal") ?? 2500,
            proteinCurrent: defaults?.double(forKey: "widget.protein") ?? 0,
            proteinGoal: defaults?.integer(forKey: "widget.proteinGoal") ?? 180,
            waterCurrentMl: defaults?.integer(forKey: "widget.water") ?? 0,
            waterGoalMl: defaults?.integer(forKey: "widget.waterGoal") ?? 3000,
            nextReminderTitle: defaults?.string(forKey: "widget.nextReminderTitle"),
            userName: defaults?.string(forKey: "widget.userName") ?? "Athlete"
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Small Widget
struct APEXSmallWidget: View {
    var entry: APEXWidgetEntry

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0F")

            VStack(alignment: .leading, spacing: 8) {
                // Logo + name
                HStack {
                    Text("APEX")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#00D4FF"))
                    Spacer()
                    Text(Date().formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: entry.taskProgress)
                        .stroke(Color(hex: "#00D4FF"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(entry.taskProgress * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Tasks")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(width: 70, height: 70)

                Spacer()

                if let title = entry.nextReminderTitle {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill").font(.system(size: 9)).foregroundStyle(Color(hex: "#00D4FF"))
                        Text(title).font(.system(size: 10)).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                    }
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Medium Widget
struct APEXMediumWidget: View {
    var entry: APEXWidgetEntry

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0F")

            HStack(spacing: 16) {
                // Rings
                VStack(spacing: 8) {
                    smallRing(progress: Double(entry.caloriesCurrent) / Double(entry.caloriesGoal), color: "#FF9800", label: "kcal")
                    smallRing(progress: entry.proteinCurrent / Double(entry.proteinGoal), color: "#9B59B6", label: "Pro")
                    smallRing(progress: Double(entry.waterCurrentMl) / Double(entry.waterGoalMl), color: "#007AFF", label: "H₂O")
                }

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("APEX").font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(Color(hex: "#00D4FF"))

                    VStack(alignment: .leading, spacing: 4) {
                        infoRow(label: "Kalorien", value: "\(entry.caloriesCurrent)/\(entry.caloriesGoal)")
                        infoRow(label: "Protein", value: "\(Int(entry.proteinCurrent))g")
                        infoRow(label: "Wasser", value: "\(entry.waterCurrentMl)ml")
                    }

                    if let title = entry.nextReminderTitle {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill").font(.system(size: 9)).foregroundStyle(Color(hex: "#00D4FF"))
                            Text(title).font(.system(size: 10)).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                        }
                    }
                }
                Spacer()
            }
            .padding(14)
        }
    }

    private func smallRing(progress: Double, color: String, label: String) -> some View {
        ZStack {
            Circle().stroke(.white.opacity(0.1), lineWidth: 5)
            Circle()
                .trim(from: 0, to: min(1, progress))
                .stroke(Color(hex: color), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(label).font(.system(size: 6)).foregroundStyle(.white.opacity(0.5))
        }
        .frame(width: 44, height: 44)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 10)).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value).font(.system(size: 10, weight: .semibold)).foregroundStyle(.white)
        }
    }
}

// MARK: - Widget Bundle
struct APEXWidget: Widget {
    let kind = "APEXWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: APEXWidgetProvider()) { entry in
            APEXSmallWidget(entry: entry)
                .containerBackground(Color(hex: "#0A0A0F"), for: .widget)
        }
        .configurationDisplayName("APEX")
        .description("Tagesfortschritt auf einen Blick")
        .supportedFamilies([.systemSmall])
    }
}

struct APEXMediumWidgetDef: Widget {
    let kind = "APEXMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: APEXWidgetProvider()) { entry in
            APEXMediumWidget(entry: entry)
                .containerBackground(Color(hex: "#0A0A0F"), for: .widget)
        }
        .configurationDisplayName("APEX Makros")
        .description("Kalorien, Protein und Wasser im Überblick")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct APEXWidgetBundle: WidgetBundle {
    var body: some Widget {
        APEXWidget()
        APEXMediumWidgetDef()
    }
}
