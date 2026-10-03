import Foundation

// Shared data models. Owner: Task 0. Changes must be additive (new fields need defaults).
// Spec: docs/WORKFLOW.md.

// MARK: - Geography

public struct GeoPoint: Codable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// A GPS fix as delivered by a `LocationProviding`.
public struct LocationFix: Codable, Hashable, Sendable {
    public var point: GeoPoint
    /// Horizontal accuracy in metres (smaller is better).
    public var horizontalAccuracy: Double
    public var timestamp: Date

    public init(point: GeoPoint, horizontalAccuracy: Double, timestamp: Date = Date()) {
        self.point = point
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
    }
}

/// The field outline Noor walked. `points` is an open ring (first point is not repeated).
public struct FieldBoundary: Codable, Hashable, Sendable {
    public var points: [GeoPoint]
    /// Area in hectares, filled by the geometry code (Task 12). Nil until computed.
    public var areaHa: Double?
    public var isSynthetic: Bool

    public init(points: [GeoPoint], areaHa: Double? = nil, isSynthetic: Bool = false) {
        self.points = points
        self.areaHa = areaHa
        self.isSynthetic = isSynthetic
    }
}

/// A place Noor already knows has sick trees. The route must put ≥ 1 stop inside each.
public struct ProblemSpot: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var center: GeoPoint
    public var radiusM: Double

    public init(id: UUID = UUID(), center: GeoPoint, radiusM: Double = 10) {
        self.id = id
        self.center = center
        self.radiusM = radiusM
    }
}

// MARK: - Route

public struct Stop: Codable, Hashable, Identifiable, Sendable {
    /// 1-based stop number shown to Noor ("Kituo 3 kati ya 10").
    public var index: Int
    public var point: GeoPoint
    public var isProblemSpot: Bool

    public var id: Int { index }

    public init(index: Int, point: GeoPoint, isProblemSpot: Bool = false) {
        self.index = index
        self.point = point
        self.isProblemSpot = isProblemSpot
    }
}

public struct Route: Codable, Hashable, Sendable {
    /// The W-shaped path to draw.
    public var polyline: [GeoPoint]
    public var stops: [Stop]
    /// RNG seed used for the random start offset; stored so the route can be reproduced.
    public var seed: UInt64
    /// Non-fatal planner warnings (e.g. "edge buffer reduced"), as stable keys.
    public var warnings: [String]

    public init(polyline: [GeoPoint], stops: [Stop], seed: UInt64, warnings: [String] = []) {
        self.polyline = polyline
        self.stops = stops
        self.seed = seed
        self.warnings = warnings
    }
}

// MARK: - Photo quality

public enum QualityFailReason: String, Codable, CaseIterable, Sendable {
    case leafNotFilling, blurry, tooDark, tooBright

    /// String-table key for the RED retake message (docs/WORKFLOW.md §4).
    public var messageKey: String { "quality.\(rawValue)" }
}

public struct QualityResult: Codable, Hashable, Sendable {
    /// nil = passed (GREEN "good photo").
    public var failReason: QualityFailReason?
    /// Raw metric values, e.g. ["laplacianVariance": 143.2, "meanLuma": 118, "leafFill": 0.71].
    public var metrics: [String: Double]

    public var passed: Bool { failReason == nil }

    public init(failReason: QualityFailReason? = nil, metrics: [String: Double] = [:]) {
        self.failReason = failReason
        self.metrics = metrics
    }

    public static let good = QualityResult()
}

// MARK: - Classification and voice

public enum LeafClass: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case healthy, rust, leafMiner, cercospora, phoma, unknown
}

public struct Classification: Codable, Hashable, Sendable {
    public var top: LeafClass
    public var confidence: Double
    public var scores: [LeafClass: Double]

    public init(top: LeafClass, confidence: Double, scores: [LeafClass: Double] = [:]) {
        self.top = top
        self.confidence = confidence
        self.scores = scores
    }
}

public struct KeywordHit: Codable, Hashable, Sendable {
    /// Swahili keyword as listed in docs/WORKFLOW.md §5 Keywords, e.g. "kutu".
    public var keyword: String
    public var score: Double
    /// Class this word hints at; nil for generic words like "madoa".
    public var classHint: LeafClass?
    /// True when Noor tapped the chip herself rather than the model detecting it.
    public var isManual: Bool

    public init(keyword: String, score: Double, classHint: LeafClass?, isManual: Bool = false) {
        self.keyword = keyword
        self.score = score
        self.classHint = classHint
        self.isManual = isManual
    }
}

public struct VoiceNote: Codable, Hashable, Sendable {
    public var id: String
    public var duration: TimeInterval

    public init(id: String, duration: TimeInterval) {
        self.id = id
        self.duration = duration
    }
}

// MARK: - Stop verdict

public enum VerdictColor: String, Codable, Sendable {
    case green, amber
}

public struct StopVerdict: Codable, Hashable, Sendable {
    public var color: VerdictColor
    /// Fixed message key from docs/WORKFLOW.md §5, e.g. "verdict.lowConfidence".
    public var reasonKey: String
    public var flaggedForOfficer: Bool
    /// Label shown to Noor on GREEN (nil when healthy/no spots or AMBER).
    public var label: LeafClass?

    public init(color: VerdictColor, reasonKey: String, flaggedForOfficer: Bool, label: LeafClass? = nil) {
        self.color = color
        self.reasonKey = reasonKey
        self.flaggedForOfficer = flaggedForOfficer
        self.label = label
    }
}

public enum SkipReason: String, Codable, CaseIterable, Sendable {
    case noTree, cannotReach, other
}

/// Everything recorded at one stop. `leavesWithSpots` is Noor's count and is never changed by AI.
public struct StopObservation: Codable, Hashable, Identifiable, Sendable {
    public var stopIndex: Int
    public var leavesChecked: Int
    /// Noor's tap, 0–10. nil while not yet answered or when skipped.
    public var leavesWithSpots: Int?
    public var skipReason: SkipReason?
    public var photoID: String?
    public var photoRetakes: Int
    public var quality: QualityResult?
    public var classification: Classification?
    public var voiceNote: VoiceNote?
    public var keywordHits: [KeywordHit]
    public var verdict: StopVerdict?
    public var recordedAt: Date

    public var id: Int { stopIndex }
    public var isSkipped: Bool { skipReason != nil }

    public init(
        stopIndex: Int,
        leavesChecked: Int = 10,
        leavesWithSpots: Int? = nil,
        skipReason: SkipReason? = nil,
        photoID: String? = nil,
        photoRetakes: Int = 0,
        quality: QualityResult? = nil,
        classification: Classification? = nil,
        voiceNote: VoiceNote? = nil,
        keywordHits: [KeywordHit] = [],
        verdict: StopVerdict? = nil,
        recordedAt: Date = Date()
    ) {
        self.stopIndex = stopIndex
        self.leavesChecked = leavesChecked
        self.leavesWithSpots = leavesWithSpots
        self.skipReason = skipReason
        self.photoID = photoID
        self.photoRetakes = photoRetakes
        self.quality = quality
        self.classification = classification
        self.voiceNote = voiceNote
        self.keywordHits = keywordHits
        self.verdict = verdict
        self.recordedAt = recordedAt
    }
}

// MARK: - Walk session

public enum WalkStatus: String, Codable, Sendable {
    case settingUp, walking, finished
}

public struct WalkSession: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var startedAt: Date
    public var finishedAt: Date?
    public var status: WalkStatus
    public var field: FieldBoundary?
    public var problemSpots: [ProblemSpot]
    public var route: Route?
    public var observations: [StopObservation]
    /// True for simulate-walk / sample data. UI must show the "Data ya mfano" badge.
    public var isSynthetic: Bool

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        status: WalkStatus = .settingUp,
        field: FieldBoundary? = nil,
        problemSpots: [ProblemSpot] = [],
        route: Route? = nil,
        observations: [StopObservation] = [],
        isSynthetic: Bool = false
    ) {
        self.id = id
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.status = status
        self.field = field
        self.problemSpots = problemSpots
        self.route = route
        self.observations = observations
        self.isSynthetic = isSynthetic
    }
}

// MARK: - Summary and recommendation

public struct WalkSummary: Codable, Hashable, Sendable {
    public var leavesChecked: Int
    public var leavesWithSpots: Int
    /// 0...1
    public var incidence: Double
    /// 95% Wilson interval bounds, 0...1.
    public var intervalLow: Double
    public var intervalHigh: Double
    public var stopsChecked: Int
    public var stopsSkipped: Int
    /// Number of AMBER ("not sure") trees.
    public var flaggedCount: Int
    /// Disease shared by ≥ 2 GREEN stops, if any.
    public var dominantClass: LeafClass?
    /// Count per disease label over GREEN stops (for the SMS).
    public var classCounts: [LeafClass: Int]

    public init(
        leavesChecked: Int,
        leavesWithSpots: Int,
        incidence: Double,
        intervalLow: Double,
        intervalHigh: Double,
        stopsChecked: Int,
        stopsSkipped: Int,
        flaggedCount: Int,
        dominantClass: LeafClass? = nil,
        classCounts: [LeafClass: Int] = [:]
    ) {
        self.leavesChecked = leavesChecked
        self.leavesWithSpots = leavesWithSpots
        self.incidence = incidence
        self.intervalLow = intervalLow
        self.intervalHigh = intervalHigh
        self.stopsChecked = stopsChecked
        self.stopsSkipped = stopsSkipped
        self.flaggedCount = flaggedCount
        self.dominantClass = dominantClass
        self.classCounts = classCounts
    }
}

/// Fixed recommendation messages (docs/WORKFLOW.md §6).
public enum RecommendationID: String, Codable, CaseIterable, Sendable {
    case notEnough, above, close, low

    public var messageKey: String { "rec.\(rawValue)" }
    /// Short code used in the cooperative SMS (docs/WORKFLOW.md §7.1).
    public var smsCode: String {
        switch self {
        case .notEnough: return "HAIJULIKANI"
        case .above: return "JUU"
        case .close: return "KARIBU"
        case .low: return "CHINI"
        }
    }
}

public enum RecommendationAddOn: Codable, Hashable, Sendable {
    case unsure(count: Int)
    case disease(LeafClass)

    public var messageKey: String {
        switch self {
        case .unsure: return "rec.addUnsure"
        case .disease: return "rec.addDisease"
        }
    }
}

public struct Recommendation: Codable, Hashable, Sendable {
    public var id: RecommendationID
    public var addOns: [RecommendationAddOn]

    public init(id: RecommendationID, addOns: [RecommendationAddOn] = []) {
        self.id = id
        self.addOns = addOns
    }
}

// MARK: - Outbox

public enum OutboxKind: String, Codable, Sendable {
    case cooperativeReport, officerRequest
}

public enum OutboxStatus: String, Codable, Sendable {
    case queued, sending, sent, failed, cancelled
}

/// An SMS waiting to go out. Only created after Noor saw the exact text and tapped Confirm.
public struct OutboxMessage: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var kind: OutboxKind
    public var recipient: String
    public var body: String
    public var createdAt: Date
    /// When Noor tapped Confirm. Outboxes must reject messages where this is nil.
    public var confirmedAt: Date?
    public var status: OutboxStatus
    public var attempts: Int
    public var lastError: String?
    public var sessionID: UUID?

    public init(
        id: UUID = UUID(),
        kind: OutboxKind,
        recipient: String,
        body: String,
        createdAt: Date = Date(),
        confirmedAt: Date? = nil,
        status: OutboxStatus = .queued,
        attempts: Int = 0,
        lastError: String? = nil,
        sessionID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.recipient = recipient
        self.body = body
        self.createdAt = createdAt
        self.confirmedAt = confirmedAt
        self.status = status
        self.attempts = attempts
        self.lastError = lastError
        self.sessionID = sessionID
    }

    public static let maxSMSLength = 160
}

// MARK: - Price

public struct PriceRange: Codable, Hashable, Sendable {
    public var low: Double
    public var high: Double
    public var currency: String
    /// e.g. "kg parchment"
    public var unit: String

    public init(low: Double, high: Double, currency: String, unit: String) {
        self.low = low
        self.high = high
        self.currency = currency
        self.unit = unit
    }
}

/// A cached reference price. Source and observedDate must always be shown with the value.
public struct PriceSnapshot: Codable, Hashable, Sendable {
    public var source: String
    public var series: String
    public var unit: String
    public var value: Double
    public var observedDate: Date
    public var fetchedAt: Date
    /// nil when conversion factors are not cited (then only the reference line is shown).
    public var farmGateRange: PriceRange?
    /// Always "estimate"; mocks use "MOCK".
    public var label: String

    public init(
        source: String,
        series: String,
        unit: String,
        value: Double,
        observedDate: Date,
        fetchedAt: Date,
        farmGateRange: PriceRange? = nil,
        label: String = "estimate"
    ) {
        self.source = source
        self.series = series
        self.unit = unit
        self.value = value
        self.observedDate = observedDate
        self.fetchedAt = fetchedAt
        self.farmGateRange = farmGateRange
        self.label = label
    }
}

// MARK: - Consent and settings

public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case swahili = "sw"
    case english = "en"
}

public struct ConsentRecord: Codable, Hashable, Sendable {
    public var version: Int
    public var acceptedAt: Date
    public var language: AppLanguage

    public init(version: Int, acceptedAt: Date = Date(), language: AppLanguage) {
        self.version = version
        self.acceptedAt = acceptedAt
        self.language = language
    }

    public static let currentVersion = 1
}
