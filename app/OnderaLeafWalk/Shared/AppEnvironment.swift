import OnderaCore
import SwiftUI

/// Dependency container. Every seam is a protocol from OnderaCore/Shared/Protocols.swift.
/// Owner: Task 0. To ship your live implementation, change ONLY your line in `live`.
struct AppEnvironment {
    // Walk (B)
    var routePlanner: any RoutePlanning
    var makeLocationProvider: (Route?) -> any LocationProviding
    var boundaryRecorder: any BoundaryRecording
    var qualityChecker: any PhotoQualityChecking
    var classifier: any LeafClassifying
    var fusion: any FusionDeciding
    var haptics: any Haptics
    // Infra (A)
    var walkStore: any WalkStoring
    var consentStore: any ConsentStoring
    var outbox: any OutboxStoring & OutboxSending
    var voiceRecorder: any VoiceRecording
    var keywordSpotter: any KeywordSpotting
    var audio: any AudioPrompting
    // End screen (C)
    var summaryCalculator: any SummaryCalculating
    var recommender: any RecommendationProviding
    var smsComposer: any SMSComposing
    var priceProvider: any PriceProviding
    // Flags
    /// Simulate-walk demo mode (Task 14): synthetic field + scripted GPS. Sessions get isSynthetic = true.
    var simulateWalk: Bool

    /// Everything mocked. Always compiles and runs the full flow.
    static var mock: AppEnvironment {
        AppEnvironment(
            routePlanner: MockRoutePlanner(),
            makeLocationProvider: { route in
                route.map { MockLocationProvider(walking: $0) } ?? MockLocationProvider()
            },
            boundaryRecorder: MockBoundaryRecorder(),
            qualityChecker: MockPhotoQualityChecker(),
            classifier: MockLeafClassifier(),
            fusion: MockFusion(),
            haptics: MockHaptics(),
            walkStore: InMemoryWalkStore(),
            consentStore: MockConsentStore(),
            outbox: MockOutbox(),
            voiceRecorder: MockVoiceRecorder(),
            keywordSpotter: MockKeywordSpotter(),
            audio: MockAudioPrompter(),
            summaryCalculator: MockSummaryCalculator(),
            recommender: MockRecommendationProvider(),
            smsComposer: MockSMSComposer(),
            priceProvider: MockPriceProvider(),
            simulateWalk: true
        )
    }

    /// What the app ships with. Each task swaps in its implementation here (one line each).
    static var live: AppEnvironment {
        var env = AppEnvironment.mock
        // env.routePlanner = WRoutePlanner()              // Task 13
        // env.makeLocationProvider = { ... }               // Task 14
        // env.boundaryRecorder = GPSBoundaryRecorder()     // Task 12
        // env.qualityChecker = LeafQualityGate()           // Task 18
        // env.classifier = CoreMLLeafClassifier()          // Task 19
        // env.fusion = FusionRules()                       // Task 20
        // env.haptics = DeviceHaptics()                    // Task 14
        // env.walkStore = FileWalkStore()                  // Task 2
        // env.consentStore = FileConsentStore()            // Task 3
        // env.outbox = PersistentOutbox()                  // Task 4
        // env.voiceRecorder = AVVoiceRecorder()            // Task 9
        // env.keywordSpotter = SwahiliKeywordSpotter()     // Task 9
        // env.audio = BundledAudioPrompter()               // Task 8
        // env.summaryCalculator = WilsonSummary()          // Task 21
        // env.recommender = FixedRecommendations()         // Task 21
        // env.smsComposer = TemplateSMSComposer()          // Task 23
        // env.priceProvider = CachedPriceProvider()        // Task 26
        env.simulateWalk = false
        return env
    }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.mock
}

extension EnvironmentValues {
    var app: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
