import OnderaCore
import SwiftUI

/// Owner: Workstream B. Renders every `.walk` route.
/// Replace a placeholder by adding a case that returns your real view.
enum WalkScreens {
    @ViewBuilder
    static func view(for route: AppRoute) -> some View {
        switch route {
        // case .leafCount(let stop): LeafCountView(stop: stop)   // Task 15
        default: PlaceholderScreen(route: route)
        }
    }
}
