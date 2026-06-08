# APEX — Personal Fitness App

A complete iOS fitness & lifestyle app built with SwiftUI, SwiftData, and the Anthropic Claude API.

## Tech Stack

- **Swift 5.10+** · **iOS 17+** · **Xcode 16+**
- **SwiftUI + MVVM + Repository Pattern**
- **SwiftData** for local persistence
- **CloudKit** for iCloud sync (offline-first)
- **HealthKit** (optional, permission-based)
- **WidgetKit** (App Groups for shared data)
- **UserNotifications**
- **Swift Charts**
- **Anthropic Claude API** (REST) for AI features

## Project Structure

```
APEX/
├── App/
│   ├── APEXApp.swift            # Entry point, ModelContainer setup
│   └── AppConfiguration.swift   # Constants, endpoints, defaults
├── Core/
│   ├── Models/                  # All SwiftData @Model classes
│   │   ├── UserProfile.swift
│   │   ├── SharedEnums.swift    # Weekday, TaskCategory, GoalType, …
│   │   ├── DaySection.swift
│   │   ├── APEXTask.swift
│   │   ├── WorkoutModels.swift  # WorkoutPlan, Session, Exercise, ExerciseSet
│   │   ├── NutritionModels.swift
│   │   ├── BodyEntry.swift
│   │   ├── Reminder.swift
│   │   ├── MobilityModels.swift
│   │   └── ChatMessage.swift
│   ├── Services/
│   │   ├── AIService.swift      # Anthropic Claude REST client
│   │   ├── KeychainService.swift
│   │   ├── NotificationService.swift
│   │   ├── HealthKitService.swift
│   │   └── CloudSyncService.swift
│   └── Extensions/
│       ├── DateExtensions.swift
│       └── ViewExtensions.swift
├── Features/
│   ├── Onboarding/              # 5-step onboarding with TDEE calculation
│   ├── Dashboard/               # Progress rings, tasks, weight chart
│   ├── DayPlanner/              # Week calendar + editable sections + tasks
│   ├── Training/                # Weekly plan, active workout, history
│   ├── Nutrition/               # Macros, water, meal log
│   ├── Progress/                # Weight chart, body photos
│   ├── AICoach/                 # Claude chat with context-aware system prompt
│   ├── Reminders/               # Push notification reminders
│   ├── Mobility/                # Timer-based mobility routines
│   └── Settings/                # Profile, goals, API key, HealthKit, iCloud
├── UI/
│   ├── Theme/
│   │   └── AppTheme.swift       # Colors, typography, spacing, radius
│   ├── Components/              # GlassCard, RingProgressView, MacroBar, …
│   └── Animations/
│       └── APEXAnimations.swift
└── Widget/
    └── APEXWidget.swift         # Small + Medium WidgetKit widgets
```

## Features

| # | Feature | Status |
|---|---------|--------|
| 1 | Onboarding (TDEE calc, goal setup) | ✅ |
| 2 | Dashboard (rings, tasks, chart, reminders) | ✅ |
| 3 | Day Planner (sections, tasks, repeat, reminders) | ✅ |
| 4 | Training (plan, active workout, history, summary) | ✅ |
| 5 | Nutrition (macros, water, meal log, AI estimation) | ✅ |
| 6 | Progress (weight chart, body photos) | ✅ |
| 7 | AI Coach (Claude chat with full context) | ✅ |
| 8 | Body Analysis (photo → Claude → feedback) | ✅ |
| 9 | Mobility (routines, timer, pre-built templates) | ✅ |
| 10 | Reminders (push notifications, repeat days) | ✅ |
| 11 | Settings (profile, goals, API key, HealthKit, iCloud) | ✅ |
| 12 | HealthKit Integration | ✅ |
| 13 | iCloud Sync (CloudKit status monitor) | ✅ |
| 14 | Home Screen Widget (small + medium) | ✅ |

## Setup

1. Open `APEX.xcodeproj` in Xcode 16+
2. Set your Team in Signing & Capabilities for both targets (`APEX` and `APEXWidget`)
3. Add the **HealthKit** capability to the `APEX` target
4. Add the **CloudKit** capability and select/create a container: `iCloud.com.apex.fitness`
5. Add the **App Groups** capability (both targets): `group.com.apex.fitness`
6. Add the **Push Notifications** capability to `APEX`
7. Build & run on a physical device or simulator with iOS 17+
8. On first launch complete the onboarding, then enter your **Anthropic API key** in Settings → KI Coach

## Design System

- **Dark Mode only**
- Accent: `#00D4FF` (Cyan) → `#007AFF` (Blue) gradient
- Glassmorphism cards (`ultraThinMaterial` + 1pt white border)
- Rounded, futuristic typography (SF Rounded)
- Animated ring progress views
- Spring-based transitions throughout

## AI Features

All AI features use the Anthropic Claude API:

- **AI Coach** — context-aware chat (profile + goals + history in system prompt)
- **Meal Estimation** — photo → base64 → Claude → JSON macros (marked as "KI-Schätzung")
- **Body Analysis** — photo → Claude → posture/symmetry/composition feedback

> ⚠️ All AI outputs are estimates. No medical diagnoses. Always consult a doctor for injuries.

## Notes

- No third-party dependencies — pure Apple frameworks + Anthropic REST API
- Everything is editable/deletable/renameable by the user
- Works fully offline (AI features require internet)
- API key stored securely in the iOS Keychain
