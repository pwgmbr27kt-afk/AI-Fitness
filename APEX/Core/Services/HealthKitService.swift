import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    @Published var isAuthorized = false
    @Published var isAvailable = HKHealthStore.isHealthDataAvailable()

    private let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount, .activeEnergyBurned, .bodyMass,
            .bodyFatPercentage, .dietaryEnergyConsumed,
            .dietaryProtein, .dietaryCarbohydrates, .dietaryFatTotal,
            .dietaryWater
        ]
        identifiers.compactMap { HKQuantityType($0) }.forEach { types.insert($0) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }()

    private let writeTypes: Set<HKSampleType> = {
        var types: Set<HKSampleType> = []
        let identifiers: [HKQuantityTypeIdentifier] = [
            .bodyMass, .dietaryWater
        ]
        identifiers.compactMap { HKQuantityType($0) }.forEach { types.insert($0) }
        return types
    }()

    func requestPermission() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    // MARK: - Steps today
    func stepsToday() async -> Double {
        guard isAvailable else { return 0 }
        guard let type = HKQuantityType(.stepCount) else { return 0 }
        return await querySum(type: type, unit: HKUnit.count(), predicate: todayPredicate())
    }

    // MARK: - Active calories today
    func activeCaloriesToday() async -> Double {
        guard isAvailable else { return 0 }
        guard let type = HKQuantityType(.activeEnergyBurned) else { return 0 }
        return await querySum(type: type, unit: HKUnit.kilocalorie(), predicate: todayPredicate())
    }

    // MARK: - Latest body weight
    func latestBodyWeight() async -> Double? {
        guard isAvailable else { return nil }
        guard let type = HKQuantityType(.bodyMass) else { return nil }
        let samples = await queryMostRecent(type: type, limit: 1)
        return (samples.first as? HKQuantitySample)?.quantity.doubleValue(for: .gramUnit(with: .kilo))
    }

    // MARK: - Save body weight
    func saveBodyWeight(kg: Double, date: Date = Date()) async throws {
        guard isAvailable else { return }
        guard let type = HKQuantityType(.bodyMass) else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await store.save(sample)
    }

    // MARK: - Helpers
    private func todayPredicate() -> NSPredicate {
        let start = Calendar.current.startOfDay(for: Date())
        let end   = Date()
        return HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
    }

    private func querySum(type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    private func queryMostRecent(type: HKSampleType, limit: Int) async -> [HKSample] {
        await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: limit, sortDescriptors: [sort]) { _, samples, _ in
                cont.resume(returning: samples ?? [])
            }
            store.execute(query)
        }
    }
}
