import OnderaCore
import SwiftUI

/// Owner: Workstream A. Renders every `.infra` route and the home screen.
/// Replace a placeholder by adding a case that returns your real view.
enum InfraScreens {
    @ViewBuilder
    static func view(for route: AppRoute) -> some View {
        switch route {
        // case .consent: ConsentView()          // Task 3
        default: PlaceholderScreen(route: route)
        }
    }

    /// S0 Home (Task 1 replaces this).
    @ViewBuilder
    static func home() -> some View {
        HomePlaceholder()
    }
}

private struct HomePlaceholder: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.app) private var app

    var body: some View {
        VStack(spacing: 16) {
            Text(verbatim: "Ondera Leaf Walk")
                .font(.largeTitle.bold())
            Text(verbatim: "S0 Home — TODO task 1")
                .foregroundStyle(.orange)
            if app.simulateWalk { DemoBadge() }
            Spacer().frame(height: 24)
            ForEach(AppRoute.homeActions, id: \.self) { route in
                Button {
                    router.push(route)
                } label: {
                    Text(verbatim: route == .language ? "Start new walk" : route.devTitle)
                }
                .buttonStyle(BigButtonStyle(prominent: route == .language))
                .accessibilityIdentifier("go.\(route.identifier)")
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.home")
    }
}
