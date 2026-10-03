import Foundation

/// Every screen in docs/WORKFLOW.md §2. Home is the navigation root and has no route.
/// Owner: Task 0. Add cases freely; don't rename existing ones.
public enum AppRoute: Hashable, Codable, Sendable {
    // Setup
    case language
    case consent
    case boundary
    case problemSpots
    case routePreview
    // Walk
    case walk
    case stopInstructions(Int)
    case leafCount(Int)
    case camera(Int)
    case photoCheck(Int)
    case voiceNote(Int)
    case stopResult(Int)
    // End
    case summary
    case sendCooperative
    case checkAgain
    case askOfficer
    case outbox
    // Other
    case settings
    case pastWalks

    public static let stopCount = 10

    public enum Workstream: String, Sendable {
        case infra, walk, endScreen
    }

    /// Which app folder renders this screen.
    public var workstream: Workstream {
        switch self {
        case .language, .consent, .outbox, .settings, .pastWalks: return .infra
        case .boundary, .problemSpots, .routePreview, .walk, .stopInstructions, .leafCount,
             .camera, .photoCheck, .voiceNote, .stopResult: return .walk
        case .summary, .sendCooperative, .checkAgain, .askOfficer: return .endScreen
        }
    }

    /// Screen ID from docs/WORKFLOW.md §2.
    public var screenID: String {
        switch self {
        case .language: return "S1"
        case .consent: return "S2"
        case .boundary: return "S3"
        case .problemSpots: return "S4"
        case .routePreview: return "S5"
        case .walk: return "S6"
        case .stopInstructions: return "S7"
        case .leafCount: return "S8"
        case .camera: return "S9"
        case .photoCheck: return "S10"
        case .voiceNote: return "S11"
        case .stopResult: return "S12"
        case .summary: return "S13"
        case .sendCooperative: return "S14"
        case .checkAgain: return "S15"
        case .askOfficer: return "S16"
        case .outbox: return "S17"
        case .settings: return "S18"
        case .pastWalks: return "S0b"
        }
    }

    /// Task(s) in TASKS.md that build this screen.
    public var ownerTasks: [Int] {
        switch self {
        case .language, .settings, .pastWalks: return [1]
        case .consent: return [3]
        case .outbox: return [4]
        case .boundary, .problemSpots: return [12]
        case .routePreview, .walk: return [13, 14]
        case .stopInstructions, .leafCount: return [15]
        case .camera: return [16]
        case .photoCheck: return [16, 18]
        case .voiceNote: return [9]
        case .stopResult: return [20]
        case .summary: return [22]
        case .sendCooperative, .checkAgain, .askOfficer: return [23]
        }
    }

    /// The stop number for per-stop screens.
    public var stopIndex: Int? {
        switch self {
        case .stopInstructions(let k), .leafCount(let k), .camera(let k),
             .photoCheck(let k), .voiceNote(let k), .stopResult(let k):
            return k
        default:
            return nil
        }
    }

    /// Developer-only English title for placeholder screens (not user-facing text).
    public var devTitle: String {
        let stop = stopIndex.map { " (stop \($0))" } ?? ""
        switch self {
        case .language: return "Language"
        case .consent: return "Consent"
        case .boundary: return "Field boundary"
        case .problemSpots: return "Problem spots"
        case .routePreview: return "Route preview"
        case .walk: return "Walk map"
        case .stopInstructions: return "Stop instructions" + stop
        case .leafCount: return "Leaf count" + stop
        case .camera: return "Camera" + stop
        case .photoCheck: return "Photo check" + stop
        case .voiceNote: return "Voice note" + stop
        case .stopResult: return "Stop result" + stop
        case .summary: return "Summary"
        case .sendCooperative: return "Send to cooperative"
        case .checkAgain: return "Check again Saturday"
        case .askOfficer: return "Ask extension officer"
        case .outbox: return "Outbox"
        case .settings: return "Settings"
        case .pastWalks: return "Past walks"
        }
    }

    /// Stable identifier for UI tests / accessibility, e.g. "leafCount-3".
    public var identifier: String {
        let base = String(describing: self).split(separator: "(").first.map(String.init) ?? ""
        return stopIndex.map { "\(base)-\($0)" } ?? base
    }

    /// Where the placeholder flow can go next. Real screens decide their own navigation.
    public var placeholderNext: [AppRoute] {
        switch self {
        case .language: return [.consent]
        case .consent: return [.boundary]
        case .boundary: return [.problemSpots]
        case .problemSpots: return [.routePreview]
        case .routePreview: return [.walk]
        case .walk: return [.stopInstructions(1)]
        case .stopInstructions(let k): return [.leafCount(k), .stopResult(k)]
        case .leafCount(let k): return [.camera(k), .stopResult(k)]
        case .camera(let k): return [.photoCheck(k)]
        case .photoCheck(let k): return [.voiceNote(k), .camera(k)]
        case .voiceNote(let k): return [.stopResult(k)]
        case .stopResult(let k): return k < Self.stopCount ? [.stopInstructions(k + 1)] : [.summary]
        case .summary: return [.sendCooperative, .checkAgain, .askOfficer]
        case .sendCooperative: return [.outbox]
        case .checkAgain, .askOfficer, .outbox, .settings, .pastWalks: return []
        }
    }

    /// Entry points from the home screen.
    public static let homeActions: [AppRoute] = [.language, .pastWalks, .outbox, .settings]

    /// One representative of every screen (per-stop screens for every stop).
    public static var allScreens: [AppRoute] {
        var routes: [AppRoute] = [.language, .consent, .boundary, .problemSpots, .routePreview, .walk]
        for k in 1...stopCount {
            routes += [.stopInstructions(k), .leafCount(k), .camera(k), .photoCheck(k), .voiceNote(k), .stopResult(k)]
        }
        routes += [.summary, .sendCooperative, .checkAgain, .askOfficer, .outbox, .settings, .pastWalks]
        return routes
    }
}
