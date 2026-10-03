import OnderaCore
import SwiftUI

/// Owner: Workstream C. Renders every `.endScreen` route.
/// Replace a placeholder by adding a case that returns your real view.
enum EndScreens {
    @ViewBuilder
    static func view(for route: AppRoute) -> some View {
        switch route {
        // case .summary: SummaryView()   // Task 22
        default: PlaceholderScreen(route: route)
        }
    }
}
