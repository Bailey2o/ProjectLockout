# Lockout (ProjectLockout)

**Display name:** Lockout  
**Tagline:** Make the decision once.  
**Phase:** 1 — iOS SwiftUI proof of concept  
**Minimum iOS:** **16.0** (the first version that provides `AuthorizationCenter.requestAuthorization(for: .individual)`)

Lockout is a digital commitment system. Phase 1 only proves that selected apps, categories, and web domains can be shielded with Apple’s Screen Time APIs.

This build is **local and reversible**. It is **not** impossible to bypass. It does **not** include a backend, Android, MDM, NetworkExtension, or server-authoritative unlock timers.

---

## What Phase 1 does

1. Requests **individual** Family Controls authorization.
2. Presents Apple’s `FamilyActivityPicker`.
3. Persists opaque application, category, and web-domain tokens in the **Keychain**.
4. Applies **Managed Settings** shields for those tokens.
5. Shows an honest dashboard: authorization status + whether shields match the stored selection.

A Mac developer with a paid Apple Developer account and the Family Controls capability can open `ProjectLockout.xcodeproj`, run on a physical iPhone/iPad (Simulator is limited), authorize, pick apps/domains, apply shields, and see the active dashboard.

---

## Xcode setup

### Requirements

- A Mac with **Xcode 15 or later** (the project is Xcode 14–compatible, `objectVersion = 56`).
- A paid **Apple Developer Program** membership.
- An **iPhone or iPad** running **iOS / iPadOS 16.0+**. A physical device is strongly recommended.
- The **Family Controls** capability on the App ID (available for *development* to all members; *distribution* requires a separate Apple approval).

### Open and sign

1. Open `ProjectLockout.xcodeproj`.
2. Select the **ProjectLockout** target → **Signing & Capabilities**.
3. Choose your **Team**. `DEVELOPMENT_TEAM` is left empty on purpose.
4. Confirm **Family Controls** is present (the checked-in entitlements file already contains `com.apple.developer.family-controls`).
5. Repeat signing for the **ShieldConfigurationExtension** target.
6. If Xcode complains about the bundle IDs, change both to IDs you control:

   | Target | Default bundle ID |
   |---|---|
   | ProjectLockout | `com.projectlockout.Lockout` |
   | ShieldConfigurationExtension | `com.projectlockout.Lockout.ShieldConfiguration` |

   Keep the extension ID a child of the app ID. Update the App IDs in [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) to match.

7. Select the **ProjectLockout** scheme and a physical device.
8. Run. Console logs use subsystem `com.projectlockout.Lockout` (categories: `authorization`, `managed-settings`, `commitment`, `persistence`, `health`, `session`).

### Capabilities / entitlements

Both targets include:

```xml
<key>com.apple.developer.family-controls</key>
<true/>
```

That is the only entitlement Phase 1 needs.

Not included (on purpose):

- App Groups — the Shield Configuration extension uses static copy and does not read tokens. Add an App Group in Phase 2/3 if a Device Activity monitor must share selection data.
- Associated Domains, Push Notifications, App Attest, Network Extension, MDM.

### How to request Family Controls

Apple documents this in [Requesting the Family Controls entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement) and [Configuring Family Controls](https://developer.apple.com/documentation/Xcode/configuring-family-controls).

**Development**

1. In the Developer portal, open the App ID → **Capabilities** → enable **Family Controls**.
2. Do the same for the Shield Configuration extension App ID.
3. In Xcode, add the **Family Controls** capability if it is not already shown (this repo already has the entitlements files).
4. Use Automatic signing so Xcode refreshes the development profile.

Family Controls is available for development without a special approval. The capability still has to be enabled on each App ID.

**Distribution (TestFlight / App Store)**

1. The Account Holder requests **Family Controls (Distribution)** for **each** bundle ID (app and every Screen Time extension) from the Family Controls distribution request, or via **Certificates, Identifiers & Profiles → Capability Requests**.
2. Wait until the capability shows as **Assigned**.
3. Enable Family Controls (Distribution) on each App ID, regenerate profiles, and archive again.

Apple will review the use case. Do not submit copy that claims the block is permanent or impossible to bypass — reviewers reject that, and it is not true on an unsupervised device.

### Simulator vs device

| Surface | Simulator | Physical device |
|---|---|---|
| Compile / UI flow | Yes | Yes |
| `requestAuthorization(for: .individual)` | Often limited or account-type errors | Expected to work when Screen Time is available |
| `FamilyActivityPicker` | Sparse / placeholder catalog | Real apps, categories, domains |
| Shields over other apps | Not a reliable demo | The actual proof |

Treat a passing Simulator run as a UI check only.

---

## Architecture

Phase 1 keeps OS work out of SwiftUI views and leaves a clean slot for a later server-backed `CommitmentServicing` implementation.

```text
Welcome → Permission → Selection → Confirmation → Dashboard
                │            │              │
                ▼            ▼              ▼
     FamilyControlsService   Keychain    ManagedSettingsService
     AuthorizationCenter     tokens +    ManagedSettingsStore.shield
                             local record
```

| Layer | Responsibility |
|---|---|
| `Features/*` views | Presentation and user intent only |
| `AppSession` | Navigation, activation ceremony, error banners |
| `FamilyControlsService` | `AuthorizationCenter` individual auth |
| `ManagedSettingsService` | Apply / clear / read shields |
| `SelectionPersistenceService` | Encode `FamilyActivitySelection` into the Keychain |
| `LocalCommitmentService` | Local session record (`CommitmentServicing` protocol) |
| `ProtectionHealthService` | Compare authorization + store + stored selection |
| `ShieldConfigurationExtension` | Optional branded shield UI |

Phase 2 should replace `LocalCommitmentService` with a Fastify client. Views should keep talking to `CommitmentServicing`. The device must never be allowed to mark a strict commitment ended by itself.

---

## Apple APIs used (verified against current docs)

No invented types. Signatures checked against Apple Developer Documentation (retrieved 2026-09-20).

### FamilyControls

| API | Use |
|---|---|
| `AuthorizationCenter.shared` | Shared authorization object |
| `requestAuthorization(for: .individual)` | Individual (not child/parental) auth — **iOS 16+** |
| `authorizationStatus` / `$authorizationStatus` | `.notDetermined`, `.denied`, `.approved` |
| `FamilyControlsError` | Canceled, unavailable, restricted, invalid account, conflict, network |
| `FamilyActivityPicker` via `.familyActivityPicker(headerText:footerText:isPresented:selection:)` | System picker with Done/Cancel |
| `FamilyActivitySelection` | Codable opaque `applicationTokens`, `categoryTokens`, `webDomainTokens` |
| `Label(ApplicationToken)` / `Label(ActivityCategoryToken)` / `Label(WebDomainToken)` | System names/icons without exposing identifiers to our code |

Docs:

- https://developer.apple.com/documentation/familycontrols/authorizationcenter
- https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:)
- https://developer.apple.com/documentation/swiftui/view/familyactivitypicker(headertext:footertext:ispresented:selection:)
- https://developer.apple.com/documentation/familycontrols/familyactivityselection

### ManagedSettings

| API | Use |
|---|---|
| `ManagedSettingsStore()` | Default store (immediate application from the app) |
| `store.shield.applications` | Up to 50 `ApplicationToken`s |
| `store.shield.applicationCategories = .specific(_:)` | Up to 50 category tokens |
| `store.shield.webDomainCategories = .specific(_:)` | Same category tokens, for websites |
| `store.shield.webDomains` | Up to 50 `WebDomainToken`s |

Docs:

- https://developer.apple.com/documentation/managedsettings
- https://developer.apple.com/documentation/managedsettings/shieldsettings/applications-swift.property
- https://developer.apple.com/documentation/managedsettings/shieldsettings/activitycategorypolicy

### ManagedSettingsUI (extension only)

| API | Use |
|---|---|
| `ShieldConfigurationDataSource` | Principal class of the shield-configuration extension |
| `configuration(shielding:)` overloads | App, app-in-category, web domain, web-in-category |
| `ShieldConfiguration` | Title, subtitle, primary button; no secondary unshield button |
| Extension point | `com.apple.ManagedSettingsUI.shield-configuration-service` |

Docs:

- https://developer.apple.com/documentation/managedsettingsui
- https://developer.apple.com/documentation/managedsettingsui/shieldconfigurationdatasource
- https://developer.apple.com/documentation/managedsettingsui/shieldconfiguration/init(backgroundblurstyle:backgroundcolor:icon:title:subtitle:primarybuttonlabel:primarybuttonbackgroundcolor:secondarybuttonlabel:)

### Foundation / Security

| API | Use |
|---|---|
| `PropertyListEncoder` / `PropertyListDecoder` | Persist `FamilyActivitySelection` (Apple’s tokens are Codable) |
| `SecItemAdd` / `SecItemCopyMatching` / `SecItemDelete` | Keychain generic passwords |
| `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` | Available after reboot, not synced via iCloud Keychain |
| `Logger` (`os`) | Structured logs |

### Why a Shield Configuration extension is included

Apple’s shield settings documentation says that when a shielded app/site is opened, the system calls **your** extension to customize appearance. The system **also** provides a default shield if the extension is missing or slow.

Phase 1 includes `ShieldConfigurationExtension` so the overlay says “Lockout” instead of a generic Screen Time sheet. Enforcement still comes from `ManagedSettingsStore`, not from the extension.

### Why there is no Device Activity monitor

`DeviceActivityMonitor` is required for **schedule-based** start/stop events (`DeviceActivityCenter` intervals). Phase 1 applies shields **immediately** from the app process. A monitor extension is not required for shields to display, and adding an empty one would extra-tax Family Controls distribution approval (Apple requires a separate request per extension bundle ID).

A monitor should be added in a later phase if timed windows or heartbeat-triggered re-application are needed.

### Why there is no Shield Action extension

A Shield Action extension (`com.apple.ManagedSettings.shield-action-service`) is only required to customize what the shield buttons *do*. Phase 1 uses a single **OK** button and the system default action (dismiss). There is no “unlock” control on the shield.

---

## Known Phase 1 limitations and bypasses

Do not market this version as permanent, irreversible, or impossible to bypass.

On an unsupervised consumer iPhone, a determined owner can still:

| Attack | Phase 1 result |
|---|---|
| Tap **End local session** in Lockout | Shields are cleared. This is an explicit development control. |
| Settings → Screen Time → revoke the app | Authorization becomes denied; Apple voids tokens; health shows interrupted. |
| Delete Lockout | The app is gone. Individual authorization does **not** prevent deletion (Apple documents that individual auth removes the parental-control deletion restrictions). Residual Managed Settings may or may not remain — **not verified here without the entitlement**. |
| Reinstall | Local Keychain data is gone unless this-device Keychain items survived. No server exists to restore policy. |
| Erase / restore device | Outer boundary of consumer hardware. |
| Another browser / private browsing | Only domains and categories selected in the picker are shielded. Unlisted browsers/apps are not blocked unless their tokens were selected or they fall in a shielded category. |
| VPN / DNS change | Phase 1 has no NetworkExtension or DNS filter. |
| Change device date | No timers in Phase 1. Later unlock delays must use **server** time. |
| Simulator | Not a valid enforcement test. |

Honest product language used in the UI:

- “Phase 1 is a local, reversible development session.”
- “Lockout will not claim you are protected” when health does not match.
- Never “impossible to bypass.”

Apple also documents a hard cap of **50** application tokens, **50** category tokens, and **50** web-domain tokens per shield setting. Phase 1 refuses to activate above those limits rather than silently truncating.

---

## What could not be verified in this environment

This repository was assembled on Linux without:

- Xcode
- an iOS Simulator
- a physical iPhone
- a Family Controls–entitled provisioning profile

Therefore the following are **unchecked** until a Mac developer with the entitlement runs the app:

- Compiling against the current iOS SDK (API names were checked against Apple’s documentation, not `xcodebuild`).
- The Family Controls system alert and biometric sheet.
- `FamilyActivityPicker` contents on a real device.
- Whether shields actually overlay the selected apps/Safari domains.
- Whether shields survive reboot (Apple’s store is system-persisted; still needs a device test).
- Whether residual shields remain after deleting the app under individual authorization.
- Provisioning: Automatic signing with `com.apple.developer.family-controls` on both bundle IDs.

If `AuthorizationCenter.$authorizationStatus` fails to compile on a given SDK, observe status on `scenePhase == .active` instead — `RootView` already refreshes there.

---

## File tree

```text
ProjectLockout/
├── README.md
├── .gitignore
├── ProjectLockout.xcodeproj/
│   ├── project.pbxproj
│   ├── project.xcworkspace/
│   └── xcshareddata/xcschemes/ProjectLockout.xcscheme
├── ProjectLockout/
│   ├── ProjectLockoutApp.swift
│   ├── ProjectLockout.entitlements
│   ├── Assets.xcassets/
│   ├── Models/
│   │   ├── AppRoute.swift
│   │   ├── LocalCommitment.swift
│   │   ├── LockoutError.swift
│   │   ├── ProtectionHealth.swift
│   │   ├── RestrictionSelection.swift
│   │   └── ShieldSnapshot.swift
│   ├── Services/
│   │   ├── FamilyControlsService.swift
│   │   ├── ManagedSettingsService.swift
│   │   ├── KeychainService.swift
│   │   ├── SelectionPersistenceService.swift
│   │   ├── LocalCommitmentService.swift   # CommitmentServicing protocol lives here
│   │   ├── ProtectionHealthService.swift
│   │   └── LockoutLog.swift
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── WelcomeView.swift          # tagline: Make the decision once.
│   │   │   └── PermissionView.swift
│   │   ├── Selection/
│   │   │   ├── SelectionView.swift
│   │   │   └── SelectionTokenList.swift
│   │   ├── Commitment/
│   │   │   └── CommitmentConfirmationView.swift
│   │   └── Dashboard/
│   │       ├── DashboardView.swift
│   │       └── HealthCard.swift
│   └── Shared/
│       ├── AppSession.swift
│       ├── RootView.swift
│       ├── LockoutIdentity.swift
│       ├── LockoutTheme.swift
│       └── LockoutChrome.swift
└── ShieldConfigurationExtension/
    ├── ShieldConfigurationExtension.swift
    ├── Info.plist
    └── ShieldConfigurationExtension.entitlements
```

---

## Next phases (not in this PR)

- **Phase 2:** Fastify + Prisma + PostgreSQL commitments, guardians, server timestamps.
- **Phase 3:** App Attest, heartbeats, compromise alerts.
- **Phase 4:** NetworkExtension / managed DNS / supervision.
- **Phase 5:** Android.
