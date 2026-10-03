import CoreGraphics
import XCTest
@testable import OnderaCore

final class ModelCodableTests: XCTestCase {
    private func roundTrip<T: Codable & Equatable>(_ value: T, file: StaticString = #filePath, line: UInt = #line) throws {
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(T.self, from: data)
        XCTAssertEqual(decoded, value, file: file, line: line)
    }

    func testFinishedWalkRoundTrips() throws {
        try roundTrip(SampleData.syntheticFinishedWalk())
    }

    func testSmallModelsRoundTrip() throws {
        try roundTrip(QualityResult(failReason: .blurry, metrics: ["laplacianVariance": 42]))
        try roundTrip(Classification(top: .cercospora, confidence: 0.7, scores: [.cercospora: 0.7, .phoma: 0.3]))
        try roundTrip(KeywordHit(keyword: "kutu", score: 0.9, classHint: .rust))
        try roundTrip(Recommendation(id: .above, addOns: [.unsure(count: 3), .disease(.rust)]))
        try roundTrip(OutboxMessage(kind: .cooperativeReport, recipient: "+254700000000", body: "OLW", confirmedAt: Date()))
        try roundTrip(MockPriceProvider.snapshot)
        try roundTrip(ConsentRecord(version: 1, language: .swahili))
        try roundTrip(AppRoute.leafCount(3))
    }

    func testClassScoresEncodeAsKeyedObject() throws {
        let json = String(data: try JSONEncoder().encode(Classification(top: .rust, confidence: 1, scores: [.rust: 1])), encoding: .utf8)!
        XCTAssertTrue(json.contains("\"rust\":1"), json)
    }
}

final class AppRouteTests: XCTestCase {
    func testEveryScreenReachableFromHome() {
        var seen = Set<AppRoute>()
        var queue = AppRoute.homeActions
        while let next = queue.popLast() {
            guard seen.insert(next).inserted else { continue }
            queue += next.placeholderNext
        }
        for route in AppRoute.allScreens {
            XCTAssertTrue(seen.contains(route), "\(route) not reachable")
        }
    }

    func testLastStopLeadsToSummary() {
        XCTAssertEqual(AppRoute.stopResult(AppRoute.stopCount).placeholderNext, [.summary])
        XCTAssertEqual(AppRoute.stopResult(3).placeholderNext, [.stopInstructions(4)])
    }

    func testIdentifiersAreUnique() {
        let ids = AppRoute.allScreens.map(\.identifier)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(AppRoute.leafCount(7).identifier, "leafCount-7")
        XCTAssertEqual(AppRoute.summary.identifier, "summary")
    }

    func testEveryScreenHasOwnerTask() {
        for route in AppRoute.allScreens {
            XCTAssertFalse(route.ownerTasks.isEmpty, "\(route)")
        }
    }
}

final class MockTests: XCTestCase {
    func testMockPlannerGivesTenStopsAndCoversProblemSpot() throws {
        let route = try MockRoutePlanner().plan(field: SampleData.syntheticField, problemSpots: [SampleData.syntheticProblemSpot], seed: 1)
        XCTAssertEqual(route.stops.count, 10)
        XCTAssertEqual(route.stops.map(\.index), Array(1...10))
        XCTAssertTrue(route.stops.contains { $0.isProblemSpot && $0.point == SampleData.syntheticProblemSpot.center })
    }

    func testOutboxRejectsUnconfirmedAndLong() async throws {
        let outbox = MockOutbox()
        XCTAssertThrowsError(try outbox.enqueue(OutboxMessage(kind: .cooperativeReport, recipient: "coop", body: "hi"))) {
            XCTAssertEqual($0 as? OutboxError, .notConfirmed)
        }
        let long = String(repeating: "a", count: 161)
        XCTAssertThrowsError(try outbox.enqueue(OutboxMessage(kind: .cooperativeReport, recipient: "coop", body: long, confirmedAt: Date()))) {
            XCTAssertEqual($0 as? OutboxError, .tooLong(161))
        }

        try outbox.enqueue(OutboxMessage(kind: .cooperativeReport, recipient: "coop", body: "hi", confirmedAt: Date()))
        let offline = await outbox.flush()
        XCTAssertTrue(offline.isEmpty)
        outbox.isOnline = true
        let sent = await outbox.flush()
        XCTAssertEqual(sent.count, 1)
        XCTAssertEqual(try outbox.all().first?.status, .sent)
    }

    func testMockFusionNeverTouchesCountAndFlagsUnsure() {
        let fusion = MockFusion()
        XCTAssertEqual(fusion.decide(FusionInput(leavesWithSpots: 0)).color, .green)
        let unsure = fusion.decide(FusionInput(leavesWithSpots: 3, quality: .good, classification: Classification(top: .unknown, confidence: 0.3)))
        XCTAssertEqual(unsure.color, .amber)
        XCTAssertTrue(unsure.flaggedForOfficer)
    }

    func testMockSummaryOnSyntheticWalk() {
        let walk = SampleData.syntheticFinishedWalk()
        let s = MockSummaryCalculator().summarize(walk)
        XCTAssertEqual(s.leavesChecked, 100)
        XCTAssertEqual(s.leavesWithSpots, 12)
        XCTAssertEqual(s.flaggedCount, 2)
        XCTAssertEqual(s.dominantClass, .rust)
        XCTAssertTrue(walk.isSynthetic)
    }

    func testWalkStoreResumeAndDeleteAll() throws {
        let store = InMemoryWalkStore()
        try store.save(WalkSession(status: .walking))
        try store.save(SampleData.syntheticFinishedWalk())
        XCTAssertEqual(try store.inProgress()?.status, .walking)
        _ = try store.savePhoto(Data([1, 2, 3]))
        try store.deleteAll()
        XCTAssertTrue(try store.all().isEmpty)
        XCTAssertTrue(store.photos.isEmpty)
    }

    func testMockPriceIsClearlyMock() {
        XCTAssertEqual(MockPriceProvider().cached()?.label, "MOCK")
        XCTAssertTrue(MockPriceProvider.snapshot.source.contains("MOCK"))
    }

    func testQualityMockSequence() throws {
        let ctx = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let image = ctx.makeImage()!
        let checker = MockPhotoQualityChecker(results: [QualityResult(failReason: .blurry), .good])
        XCTAssertEqual(checker.check(image).failReason, .blurry)
        XCTAssertTrue(checker.check(image).passed)
        XCTAssertTrue(checker.check(image).passed)
    }
}
