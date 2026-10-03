import SwiftUI

@main
struct OnderaLeafWalkApp: App {
    /// `-mock` launch argument forces all mocks (UI tests, demos). Otherwise `.live`,
    /// which is mocks until each task swaps in its implementation.
    private let environment: AppEnvironment = ProcessInfo.processInfo.arguments.contains("-mock") ? .mock : .live

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.app, environment)
        }
    }
}
