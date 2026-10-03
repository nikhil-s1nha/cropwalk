import Observation
import OnderaCore
import SwiftUI

/// Navigation state for the whole app. Owner: Task 0 (Task 1 may extend).
@Observable
final class AppRouter {
    var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    /// Replace the current screen (e.g. retake photo without growing the stack).
    func replaceTop(with route: AppRoute) {
        if path.isEmpty { path = [route] } else { path[path.count - 1] = route }
    }
}
