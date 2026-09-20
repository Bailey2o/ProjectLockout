import Foundation
import os

enum LockoutLog {
    static let authorization = Logger(subsystem: LockoutIdentity.logSubsystem, category: "authorization")
    static let settings = Logger(subsystem: LockoutIdentity.logSubsystem, category: "managed-settings")
    static let commitment = Logger(subsystem: LockoutIdentity.logSubsystem, category: "commitment")
    static let persistence = Logger(subsystem: LockoutIdentity.logSubsystem, category: "persistence")
    static let health = Logger(subsystem: LockoutIdentity.logSubsystem, category: "health")
    static let session = Logger(subsystem: LockoutIdentity.logSubsystem, category: "session")
}
