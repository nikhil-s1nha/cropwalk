import Foundation

// Deterministic mocks for Workstream C seams. The maths here is deliberately simplistic;
// the real Wilson interval and recommendation rules are Task 21.

public final class MockSummaryCalculator: SummaryCalculating {
    public init() {}

    public func summarize(_ session: WalkSession) -> WalkSummary {
        let checked = session.observations.filter { !$0.isSkipped && $0.leavesWithSpots != nil }
        let n = checked.reduce(0) { $0 + $1.leavesChecked }
        let x = checked.reduce(0) { $0 + ($1.leavesWithSpots ?? 0) }
        let p = n > 0 ? Double(x) / Double(n) : 0
        var counts: [LeafClass: Int] = [:]
        for o in checked where o.verdict?.color == .green {
            if let label = o.verdict?.label { counts[label, default: 0] += 1 }
        }
        return WalkSummary(
            leavesChecked: n,
            leavesWithSpots: x,
            incidence: p,
            intervalLow: max(0, p - 0.05), // MOCK band, not a real interval
            intervalHigh: min(1, p + 0.05),
            stopsChecked: checked.count,
            stopsSkipped: session.observations.filter(\.isSkipped).count,
            flaggedCount: session.observations.filter { $0.verdict?.flaggedForOfficer == true }.count,
            dominantClass: counts.filter { $0.value >= 2 }.max { $0.value < $1.value }?.key,
            classCounts: counts
        )
    }
}

public final class MockRecommendationProvider: RecommendationProviding {
    public var fixed: Recommendation

    public init(fixed: Recommendation = Recommendation(id: .close)) {
        self.fixed = fixed
    }

    public func recommend(for summary: WalkSummary) -> Recommendation { fixed }
}

public final class MockSMSComposer: SMSComposing {
    public init() {}

    public func cooperativeReport(farmerID: String, session: WalkSession, summary: WalkSummary, recommendation: Recommendation) -> String {
        "OLW \(farmerID) MOCK Madoa \(summary.leavesWithSpots)/\(summary.leavesChecked) \(recommendation.id.smsCode)"
    }

    public func officerRequest(farmerID: String, session: WalkSession, summary: WalkSummary) -> String {
        "OLW \(farmerID) MOCK AFISA: miti \(summary.flaggedCount) ina shaka"
    }
}

/// Clearly fake price. Source says MOCK so it can never be mistaken for real data.
public final class MockPriceProvider: PriceProviding {
    public static let snapshot = PriceSnapshot(
        source: "MOCK — not a real price",
        series: "MOCK",
        unit: "USD/kg",
        value: 0,
        observedDate: Date(timeIntervalSince1970: 1_790_812_800), // 1 Oct 2026
        fetchedAt: Date(timeIntervalSince1970: 1_790_812_800),
        farmGateRange: nil,
        label: "MOCK"
    )

    public init() {}

    public func cached() -> PriceSnapshot? { Self.snapshot }
    public func refresh() async throws -> PriceSnapshot { Self.snapshot }
}
