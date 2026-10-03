import CoreGraphics
import Foundation

// Deterministic mocks for Workstream B seams. Replace with live implementations in AppEnvironment.live.

/// Puts 10 stops on a simple zigzag across the field's lat/lon bounding box. NOT the real W planner (Task 13).
public final class MockRoutePlanner: RoutePlanning {
    public init() {}

    public func plan(field: FieldBoundary, problemSpots: [ProblemSpot], seed: UInt64) throws -> Route {
        let lats = field.points.map(\.latitude)
        let lons = field.points.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(), let minLon = lons.min(), let maxLon = lons.max() else {
            return Route(polyline: [], stops: [], seed: seed, warnings: ["mock.emptyField"])
        }
        let n = AppRoute.stopCount
        var stops: [Stop] = (0..<n).map { i in
            let t = (Double(i) + 0.5) / Double(n)
            let side = i.isMultiple(of: 2) ? 0.35 : 0.65
            return Stop(
                index: i + 1,
                point: GeoPoint(latitude: minLat + (maxLat - minLat) * side, longitude: minLon + (maxLon - minLon) * t)
            )
        }
        for (j, spot) in problemSpots.prefix(n).enumerated() {
            stops[n - 1 - j] = Stop(index: n - j, point: spot.center, isProblemSpot: true)
        }
        return Route(polyline: stops.map(\.point), stops: stops, seed: seed, warnings: ["mock.planner"])
    }
}

/// Yields a fixed list of fixes (e.g. the route's stops) then finishes.
public final class MockLocationProvider: LocationProviding {
    public var scripted: [LocationFix]
    private var continuation: AsyncStream<LocationFix>.Continuation?

    public init(scripted: [LocationFix] = []) {
        self.scripted = scripted
    }

    public convenience init(walking route: Route, accuracy: Double = 4) {
        self.init(scripted: route.stops.map { LocationFix(point: $0.point, horizontalAccuracy: accuracy) })
    }

    public func fixes() -> AsyncStream<LocationFix> {
        AsyncStream { continuation in
            self.continuation = continuation
            for fix in scripted { continuation.yield(fix) }
            continuation.finish()
        }
    }

    public func stop() {
        continuation?.finish()
    }
}

/// Ignores GPS and returns the SYNTHETIC sample field.
public final class MockBoundaryRecorder: BoundaryRecording {
    public private(set) var points: [GeoPoint] = []

    public init() {}

    public func start() { points = [] }
    public func add(_ fix: LocationFix) { points.append(fix.point) }
    public func finish() throws -> FieldBoundary { SampleData.syntheticField }
}

/// Returns scripted results in order (then repeats the last one). Default: always passes.
public final class MockPhotoQualityChecker: PhotoQualityChecking {
    public var results: [QualityResult]
    private var calls = 0

    public init(results: [QualityResult] = [.good]) {
        self.results = results
    }

    public func check(_ image: CGImage) -> QualityResult {
        defer { calls += 1 }
        return results[min(calls, results.count - 1)]
    }
}

public final class MockLeafClassifier: LeafClassifying {
    public var result: Classification

    public init(result: Classification = Classification(top: .rust, confidence: 0.88, scores: [.rust: 0.88, .healthy: 0.05, .unknown: 0.07])) {
        self.result = result
    }

    public func classify(_ image: CGImage) async throws -> Classification { result }
}

/// Crude stand-in for Task 20: 0 spots → green; confident → green; otherwise amber "not sure".
public final class MockFusion: FusionDeciding {
    public init() {}

    public func decide(_ input: FusionInput) -> StopVerdict {
        if input.leavesWithSpots == 0 {
            return StopVerdict(color: .green, reasonKey: "verdict.noSpots", flaggedForOfficer: false)
        }
        if let c = input.classification, c.top != .unknown, c.top != .healthy, c.confidence >= 0.8, !input.gaveUpOnPhoto {
            return StopVerdict(color: .green, reasonKey: "verdict.confident", flaggedForOfficer: false, label: c.top)
        }
        return StopVerdict(color: .amber, reasonKey: "verdict.lowConfidence", flaggedForOfficer: true)
    }
}

public final class MockHaptics: Haptics {
    public private(set) var events: [String] = []

    public init() {}

    public func arrivedAtStop() { events.append("arrived") }
    public func success() { events.append("success") }
    public func warning() { events.append("warning") }
}
