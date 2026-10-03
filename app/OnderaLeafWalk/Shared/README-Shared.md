# Shared (app)

Owner: **Task 0**; all workstreams may make **additive** changes.

- `AppEnvironment.swift` — dependency container. To ship a live implementation, change ONE line in `AppEnvironment.live`.
- `AppRouter.swift`, `RootView.swift` — navigation. Screens are rendered by `InfraScreens` / `WalkScreens` / `EndScreens` (one per workstream folder) so owners never edit RootView.
- `PlaceholderScreen.swift` — temporary screen for anything not built yet.
- `UI/` — shared styles (`BigButtonStyle`, `DemoBadge`).
