import OnderaCore
import XCTest
@testable import OnderaLeafWalk

final class AppEnvironmentTests: XCTestCase {
    func testMockEnvironmentRunsWholeFlowOffline() async throws {
        let env = AppEnvironment.mock
        let route = try env.routePlanner.plan(field: try env.boundaryRecorder.finish(), problemSpots: [SampleData.syntheticProblemSpot], seed: 7)
        XCTAssertEqual(route.stops.count, AppRoute.stopCount)

        var session = WalkSession(status: .walking, field: SampleData.syntheticField, route: route, isSynthetic: true)
        for stop in route.stops {
            let count = stop.index % 3
            var obs = StopObservation(stopIndex: stop.index, leavesWithSpots: count)
            if count > 0 {
                let image = try XCTUnwrap(Self.onePixelImage())
                obs.quality = env.qualityChecker.check(image)
                obs.classification = try await env.classifier.classify(image)
            }
            obs.verdict = env.fusion.decide(FusionInput(leavesWithSpots: count, quality: obs.quality, classification: obs.classification))
            session.observations.append(obs)
            try env.walkStore.save(session)
        }
        session.status = .finished

        let summary = env.summaryCalculator.summarize(session)
        XCTAssertEqual(summary.leavesChecked, 100)
        let recommendation = env.recommender.recommend(for: summary)
        let sms = env.smsComposer.cooperativeReport(farmerID: "SYN001", session: session, summary: summary, recommendation: recommendation)
        XCTAssertLessThanOrEqual(sms.count, OutboxMessage.maxSMSLength)
        try env.outbox.enqueue(OutboxMessage(kind: .cooperativeReport, recipient: "coop", body: sms, confirmedAt: Date()))
        XCTAssertEqual(try env.outbox.all().count, 1)
        XCTAssertNotNil(env.priceProvider.cached())
    }

    func testLiveDefaultsToNoSimulation() {
        XCTAssertFalse(AppEnvironment.live.simulateWalk)
        XCTAssertTrue(AppEnvironment.mock.simulateWalk)
    }

    func testRouterReplaceTop() {
        let router = AppRouter()
        router.push(.camera(1))
        router.replaceTop(with: .photoCheck(1))
        XCTAssertEqual(router.path, [.photoCheck(1)])
        router.popToRoot()
        XCTAssertTrue(router.path.isEmpty)
    }

    private static func onePixelImage() -> CGImage? {
        CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage()
    }
}
