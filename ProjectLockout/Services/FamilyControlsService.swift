import Combine
import FamilyControls
import Foundation

/// Owns Family Controls authorization. Views must not call `AuthorizationCenter` directly.
@MainActor
final class FamilyControlsService {
    private let center: AuthorizationCenter

    /// `AuthorizationCenter.shared` is main-actor isolated, so it is captured in
    /// the initializer body — never as a default argument (those are nonisolated).
    init() {
        self.center = .shared
    }

    init(center: AuthorizationCenter) {
        self.center = center
    }

    var authorizationStatus: AuthorizationStatus {
        center.authorizationStatus
    }

    /// Apple documents `$authorizationStatus` as the publisher for authorization changes,
    /// including changes made in Settings.
    var authorizationStatusPublisher: AnyPublisher<AuthorizationStatus, Never> {
        center.$authorizationStatus.eraseToAnyPublisher()
    }

    func requestIndividualAuthorization() async throws {
        LockoutLog.authorization.info("Requesting Family Controls authorization for FamilyControlsMember.individual")
        do {
            try await center.requestAuthorization(for: .individual)
            LockoutLog.authorization.info(
                "Authorization request finished. status=\(self.statusName, privacy: .public)"
            )
            guard center.authorizationStatus == .approved else {
                throw LockoutError.authorizationNotApproved
            }
        } catch let error as LockoutError {
            throw error
        } catch {
            let message = Self.userFacingMessage(for: error)
            LockoutLog.authorization.error("Authorization failed: \(message, privacy: .public)")
            throw LockoutError.authorizationFailed(message)
        }
    }

    private var statusName: String {
        authorizationStatus.lockoutTitle
    }

    static func userFacingMessage(for error: Error) -> String {
        if let familyError = error as? FamilyControlsError {
            switch familyError {
            case .authorizationCanceled:
                return "The Screen Time authorization request was canceled."
            case .invalidAccountType:
                return "This Apple Account cannot complete individual Family Controls authorization on this device."
            case .unavailable:
                return "Family Controls is unavailable. Enable Screen Time in Settings if it is off, and try again on a supported iPhone or iPad."
            case .restricted:
                return "Family Controls is restricted on this device, for example by a configuration profile."
            case .authorizationConflict:
                return "Family Controls authorization conflicts with another configuration on this device."
            case .networkError:
                return "A network error occurred while requesting authorization. Check connectivity and try again."
            default:
                return familyError.localizedDescription
            }
        }
        return error.localizedDescription
    }
}
