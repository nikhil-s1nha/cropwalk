import OnderaCore
import SwiftUI

/// Temporary screen for anything not built yet. Developer-only English text (verbatim, not localised);
/// real screens must use string-table keys. Delete usages as screens get built.
struct PlaceholderScreen: View {
    let route: AppRoute
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text(verbatim: route.screenID)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Text(verbatim: route.devTitle)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(verbatim: "TODO task \(route.ownerTasks.map(String.init).joined(separator: ", "))")
                .font(.headline)
                .foregroundStyle(.orange)
            Spacer().frame(height: 24)
            ForEach(route.placeholderNext, id: \.self) { next in
                Button {
                    router.push(next)
                } label: {
                    Text(verbatim: "→ \(next.devTitle)")
                }
                .buttonStyle(BigButtonStyle())
                .accessibilityIdentifier("go.\(next.identifier)")
            }
            if route.placeholderNext.isEmpty {
                Button {
                    router.popToRoot()
                } label: {
                    Text(verbatim: "⌂ Home")
                }
                .buttonStyle(BigButtonStyle(prominent: false))
                .accessibilityIdentifier("go.home")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.\(route.identifier)")
        .navigationTitle(Text(verbatim: route.screenID))
        .navigationBarTitleDisplayMode(.inline)
    }
}
