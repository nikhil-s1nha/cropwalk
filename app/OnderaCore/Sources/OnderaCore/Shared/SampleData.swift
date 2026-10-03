import Foundation

/// SYNTHETIC sample data for mocks, previews and simulate-walk mode.
/// Same geometry as app/OnderaLeafWalk/Resources/SYNTHETIC_sample_field.geojson.
/// Not a real farm: a ~100 m × 50 m quadrilateral rotated 30°, placed near Nyeri, Kenya for realism only.
public enum SampleData {
    public static let syntheticField = FieldBoundary(
        points: [
            GeoPoint(latitude: -0.4204219, longitude: 36.9497233),
            GeoPoint(latitude: -0.4199697, longitude: 36.9505013),
            GeoPoint(latitude: -0.4195769, longitude: 36.9502967),
            GeoPoint(latitude: -0.4200134, longitude: 36.9495098),
        ],
        areaHa: nil,
        isSynthetic: true
    )

    public static let syntheticProblemSpot = ProblemSpot(
        id: UUID(uuidString: "00000000-0000-0000-0000-00000000005A")!,
        center: GeoPoint(latitude: -0.4197860, longitude: 36.9501885),
        radiusM: 10
    )

    /// A finished SYNTHETIC walk: mix of clean, spotted and "not sure" stops. Useful for end-screen work.
    public static func syntheticFinishedWalk(planner: RoutePlanning = MockRoutePlanner()) -> WalkSession {
        let route = try? planner.plan(field: syntheticField, problemSpots: [syntheticProblemSpot], seed: 42)
        let counts = [0, 1, 0, 3, 2, 0, 0, 4, 1, 1]
        let observations: [StopObservation] = counts.enumerated().map { i, count in
            let k = i + 1
            var obs = StopObservation(stopIndex: k, leavesWithSpots: count)
            if count == 0 {
                obs.verdict = StopVerdict(color: .green, reasonKey: "verdict.noSpots", flaggedForOfficer: false)
            } else if k == 8 || k == 10 {
                obs.photoID = "SYNTHETIC-photo-\(k)"
                obs.quality = .good
                obs.classification = Classification(top: .unknown, confidence: 0.41)
                obs.verdict = StopVerdict(color: .amber, reasonKey: "verdict.lowConfidence", flaggedForOfficer: true)
            } else {
                obs.photoID = "SYNTHETIC-photo-\(k)"
                obs.quality = .good
                obs.classification = Classification(top: .rust, confidence: 0.88)
                obs.verdict = StopVerdict(color: .green, reasonKey: "verdict.confident", flaggedForOfficer: false, label: .rust)
            }
            return obs
        }
        return WalkSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
            startedAt: Date(timeIntervalSince1970: 1_791_014_400), // 3 Oct 2026 08:00 UTC
            finishedAt: Date(timeIntervalSince1970: 1_791_016_200),
            status: .finished,
            field: syntheticField,
            problemSpots: [syntheticProblemSpot],
            route: route,
            observations: observations,
            isSynthetic: true
        )
    }
}
