import CoreGraphics
import Foundation

// One protocol per seam so workstreams can build in parallel against mocks.
// Owner: Task 0. Additive changes only. Every protocol has a Mock… in Shared/Mocks.
// Implementations that need Apple UI/device frameworks live in the app target;
// pure ones live in OnderaCore.

// MARK: - Walk (Workstream B)

/// Task 13. Must be deterministic for (field, spots, seed). Rules: docs/WORKFLOW.md §3.
public protocol RoutePlanning {
    func plan(field: FieldBoundary, problemSpots: [ProblemSpot], seed: UInt64) throws -> Route
}

/// Task 14 (live GPS + simulate-walk provider).
public protocol LocationProviding: AnyObject {
    /// Stream of fixes; finishes when `stop()` is called.
    func fixes() -> AsyncStream<LocationFix>
    func stop()
}

/// Task 12. Collects fixes while Noor walks the edge, then closes the polygon.
public protocol BoundaryRecording: AnyObject {
    var points: [GeoPoint] { get }
    func start()
    func add(_ fix: LocationFix)
    func finish() throws -> FieldBoundary
}

/// Tasks 17–18. Runs on the outline crop. Order of checks: docs/WORKFLOW.md §4.
public protocol PhotoQualityChecking {
    func check(_ image: CGImage) -> QualityResult
}

/// Task 19 (Core ML). Must work offline.
public protocol LeafClassifying {
    func classify(_ image: CGImage) async throws -> Classification
}

/// Task 20. Implements docs/WORKFLOW.md §5 exactly. Never changes Noor's count.
public protocol FusionDeciding {
    func decide(_ input: FusionInput) -> StopVerdict
}

public struct FusionInput: Hashable, Sendable {
    public var leavesWithSpots: Int
    public var quality: QualityResult?
    /// True when Noor chose "continue without a good photo" after the retake limit.
    public var gaveUpOnPhoto: Bool
    public var classification: Classification?
    public var keywordHits: [KeywordHit]

    public init(
        leavesWithSpots: Int,
        quality: QualityResult? = nil,
        gaveUpOnPhoto: Bool = false,
        classification: Classification? = nil,
        keywordHits: [KeywordHit] = []
    ) {
        self.leavesWithSpots = leavesWithSpots
        self.quality = quality
        self.gaveUpOnPhoto = gaveUpOnPhoto
        self.classification = classification
        self.keywordHits = keywordHits
    }
}

/// Task 14. Arrival vibration and other feedback.
public protocol Haptics {
    func arrivedAtStop()
    func success()
    func warning()
}

// MARK: - Infra (Workstream A)

/// Task 2. Saves after every stop; photos/voice in a protected, non-backed-up folder.
public protocol WalkStoring: AnyObject {
    func save(_ session: WalkSession) throws
    func load(id: UUID) throws -> WalkSession?
    func inProgress() throws -> WalkSession?
    func all() throws -> [WalkSession]
    /// Stores photo bytes on this phone only and returns an ID.
    func savePhoto(_ data: Data) throws -> String
    func photoData(id: String) throws -> Data?
    func deleteAll() throws
}

/// Task 3.
public protocol ConsentStoring: AnyObject {
    var current: ConsentRecord? { get }
    func accept(language: AppLanguage) throws -> ConsentRecord
    func withdraw() throws
}

/// Task 4. Rejects messages without `confirmedAt` or longer than 160 chars.
public protocol OutboxStoring: AnyObject {
    func all() throws -> [OutboxMessage]
    func enqueue(_ message: OutboxMessage) throws
    func update(_ message: OutboxMessage) throws
    func cancel(id: UUID) throws
}

/// Task 4. Sends queued messages when there is signal; never attaches photos/audio.
public protocol OutboxSending {
    /// Tries to send every queued message; returns the ones now marked sent.
    func flush() async -> [OutboxMessage]
}

public enum OutboxError: Error, Equatable {
    case notConfirmed
    case tooLong(Int)
    case notFound
}

/// Task 9. Voice note stays on the phone.
public protocol VoiceRecording: AnyObject {
    func start() throws
    func stop() async throws -> VoiceNote
}

/// Task 9. On-device only.
public protocol KeywordSpotting {
    func spot(in note: VoiceNote) async throws -> [KeywordHit]
}

/// Task 8. Plays bundled, pre-generated audio for a string key. Offline.
public protocol AudioPrompting {
    func play(key: String)
    func stop()
}

// MARK: - End screen (Workstream C)

/// Task 21. Incidence + 95% Wilson interval; skipped stops reduce n, never imputed.
public protocol SummaryCalculating {
    func summarize(_ session: WalkSession) -> WalkSummary
}

/// Task 21. Picks from the fixed list in docs/WORKFLOW.md §6.
public protocol RecommendationProviding {
    func recommend(for summary: WalkSummary) -> Recommendation
}

/// Task 23. ≤ 160 chars, GSM-7 only, farmer ID never name. Templates: docs/WORKFLOW.md §7.
public protocol SMSComposing {
    func cooperativeReport(farmerID: String, session: WalkSession, summary: WalkSummary, recommendation: Recommendation) -> String
    func officerRequest(farmerID: String, session: WalkSession, summary: WalkSummary) -> String
}

/// Task 26. Bundled snapshot → cache → refresh when online. Never blocks the UI.
public protocol PriceProviding {
    func cached() -> PriceSnapshot?
    func refresh() async throws -> PriceSnapshot
}
