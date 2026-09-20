import Combine
import FamilyControls
import Foundation
import SwiftUI

/// Application-layer coordinator. SwiftUI views observe this object and never call OS APIs directly.
@MainActor
final class AppSession: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    @Published private(set) var route: AppRoute = .welcome
    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published private(set) var commitment: LocalCommitment?
    @Published private(set) var health = ProtectionHealth.unknown
    @Published private(set) var isBusy = false
    @Published var bannerError: String?

    private let familyControls: FamilyControlsService
    private let managedSettings: ManagedSettingsService
    private let selectionStore: SelectionPersistenceService
    private let commitments: LocalCommitmentService
    private let healthService: ProtectionHealthService
    private var cancellables = Set<AnyCancellable>()
    private var didStart = false

    init(
        familyControls: FamilyControlsService = FamilyControlsService(),
        managedSettings: ManagedSettingsService = ManagedSettingsService(),
        keychain: KeychainService = KeychainService()
    ) {
        self.familyControls = familyControls
        self.managedSettings = managedSettings
        self.selectionStore = SelectionPersistenceService(keychain: keychain)
        self.commitments = LocalCommitmentService(keychain: keychain)
        self.healthService = ProtectionHealthService()
        observeAuthorization()
    }

    var restriction: RestrictionSelection {
        RestrictionSelection(selection)
    }

    func start() {
        guard !didStart else {
            refreshFromSystem()
            return
        }
        didStart = true
        LockoutLog.session.info("AppSession starting")
        authorizationStatus = familyControls.authorizationStatus
        do {
            if let storedSelection = try selectionStore.load() {
                selection = storedSelection
            }
            commitment = try commitments.load()
        } catch {
            bannerError = error.localizedDescription
            LockoutLog.session.error("Failed to restore local state: \(error.localizedDescription, privacy: .public)")
        }
        refreshHealth()
        route = (commitment?.status == .active) ? .dashboard : .welcome
        LockoutLog.session.info("Initial route=\(String(describing: self.route), privacy: .public)")
    }

    func go(to newRoute: AppRoute) {
        bannerError = nil
        route = newRoute
    }

    func requestAuthorization() async {
        isBusy = true
        bannerError = nil
        defer { isBusy = false }
        do {
            try await familyControls.requestIndividualAuthorization()
            authorizationStatus = familyControls.authorizationStatus
            refreshHealth()
        } catch {
            authorizationStatus = familyControls.authorizationStatus
            bannerError = error.localizedDescription
            refreshHealth()
        }
    }

    func persistDraftSelection() {
        do {
            try selectionStore.save(selection)
            if var current = commitment, current.status != .active {
                current.selectionSummary = restriction.summary
                current.status = .draft
                try commitments.save(current)
                commitment = current
            }
        } catch {
            LockoutLog.session.error("Draft selection persist failed: \(error.localizedDescription, privacy: .public)")
            bannerError = error.localizedDescription
        }
        refreshHealth()
    }

    func prepareConfirmation() throws {
        guard !restriction.isEmpty else {
            throw LockoutError.emptySelection
        }
        try persistOrThrow()
        var record = commitment ?? LocalCommitment.draft(selectionSummary: restriction.summary)
        record.status = .confirmationPending
        record.selectionSummary = restriction.summary
        try commitments.save(record)
        commitment = record
        go(to: .confirmation)
    }

    func activateLocalSession() async {
        isBusy = true
        bannerError = nil
        defer { isBusy = false }

        LockoutLog.session.info("Activating Phase 1 local session")
        authorizationStatus = familyControls.authorizationStatus
        guard authorizationStatus == .approved else {
            failActivation(LockoutError.authorizationNotApproved)
            return
        }
        guard !restriction.isEmpty else {
            failActivation(LockoutError.emptySelection)
            return
        }

        var record = commitment ?? LocalCommitment.draft(selectionSummary: restriction.summary)
        record.status = .activating
        record.selectionSummary = restriction.summary
        do {
            try commitments.save(record)
            try selectionStore.save(selection)
            try managedSettings.applyShields(for: selection)
        } catch {
            failActivation(error)
            return
        }

        refreshHealth()
        let snapshot = managedSettings.snapshot()
        guard snapshot.matches(selection) else {
            LockoutLog.session.error("Shield verification failed after apply; clearing store so activation is not left half-applied")
            managedSettings.clearShields()
            failActivation(LockoutError.shieldVerificationFailed)
            return
        }

        record.status = .active
        record.activatedAt = Date()
        record.endedAt = nil
        do {
            try commitments.save(record)
            commitment = record
            refreshHealth()
            route = .dashboard
            LockoutLog.session.info("Phase 1 local session active id=\(record.id.uuidString, privacy: .public)")
        } catch {
            failActivation(error)
        }
    }

    func endLocalDevelopmentSession() async {
        isBusy = true
        bannerError = nil
        defer { isBusy = false }

        LockoutLog.session.info("Ending Phase 1 local development session")
        managedSettings.clearShields()
        if var record = commitment {
            record.status = .ended
            record.endedAt = Date()
            do {
                try commitments.save(record)
                commitment = record
            } catch {
                bannerError = error.localizedDescription
            }
        }
        refreshHealth()
        route = .welcome
    }

    func refreshFromSystem() {
        authorizationStatus = familyControls.authorizationStatus
        refreshHealth()
    }

    private func observeAuthorization() {
        familyControls.authorizationStatusPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.authorizationStatus = status
                LockoutLog.authorization.info("Authorization status changed to \(status.lockoutTitle, privacy: .public)")
                self.refreshHealth()
            }
            .store(in: &cancellables)
    }

    private func refreshHealth() {
        health = healthService.evaluate(
            authorization: authorizationStatus,
            commitment: commitment,
            selection: selection,
            snapshot: managedSettings.snapshot()
        )
    }

    private func persistOrThrow() throws {
        try selectionStore.save(selection)
    }

    private func failActivation(_ error: Error) {
        let message = error.localizedDescription
        bannerError = message
        LockoutLog.session.error("Activation failed: \(message, privacy: .public)")
        if var record = commitment {
            record.status = .activationFailed
            try? commitments.save(record)
            commitment = record
        }
        refreshHealth()
    }
}
