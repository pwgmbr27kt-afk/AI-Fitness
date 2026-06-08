import Foundation
import CloudKit
import SwiftData

// Cloud sync is handled automatically by SwiftData + CloudKit.
// This service provides status monitoring and manual trigger capabilities.

@MainActor
final class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var iCloudAvailable = false

    enum SyncStatus: String {
        case idle      = "Bereit"
        case syncing   = "Synchronisiert…"
        case success   = "Synchronisiert"
        case error     = "Fehler"
        case offline   = "Offline"
    }

    init() {
        Task { await checkiCloudStatus() }
        observeNetworkChanges()
    }

    func checkiCloudStatus() async {
        do {
            let container = CKContainer(identifier: AppConfiguration.cloudKitContainer)
            let status = try await container.accountStatus()
            iCloudAvailable = (status == .available)
            syncStatus = iCloudAvailable ? .idle : .offline
        } catch {
            iCloudAvailable = false
            syncStatus = .error
        }
    }

    private func observeNetworkChanges() {
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.checkiCloudStatus() }
        }
    }
}
