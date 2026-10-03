import OnderaCore
import SwiftUI

/// Navigation root. Screens are rendered by the owning workstream's `…Screens` type,
/// so owners edit their own folder, not this file.
struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            InfraScreens.home()
                .navigationDestination(for: AppRoute.self) { route in
                    Self.destination(for: route)
                }
        }
        .environment(router)
    }

    @ViewBuilder
    static func destination(for route: AppRoute) -> some View {
        switch route.workstream {
        case .infra: InfraScreens.view(for: route)
        case .walk: WalkScreens.view(for: route)
        case .endScreen: EndScreens.view(for: route)
        }
    }
}

#Preview {
    RootView()
}
