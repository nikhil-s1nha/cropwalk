# app/ — Ondera Leaf Walk iOS app

- `OnderaLeafWalk.xcodeproj` — open in Xcode 16+ (built with Xcode 26). Generated from `project.yml` by XcodeGen, but committed, so you don't need XcodeGen.
- **Synchronized folders**: add/move/delete files in Finder or Xcode and they're picked up automatically. `project.pbxproj` does **not** change, so no merge conflicts. Only run `xcodegen` here when changing targets/settings in `project.yml`.
- `OnderaLeafWalk/` — app target. `Shared/` (Task 0, additive), `Infra/` (A), `Walk/` (B), `EndScreen/` (C), `Resources/`.
- `OnderaCore/` — Swift package with pure logic: models, protocols, mocks, `AppRoute`. Tests run on the Mac with no simulator.
- `OnderaLeafWalkTests/` — unit tests in the app target. `OnderaLeafWalkUITests/` — taps through the whole flow.

## Run and test

```bash
cd app/OnderaCore && swift test                # pure logic, ~seconds
cd app && xcodebuild -project OnderaLeafWalk.xcodeproj -scheme OnderaLeafWalk \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test   # app + UI tests (~3 min)
```
`xcodebuild -project app/OnderaLeafWalk.xcodeproj -scheme OnderaLeafWalk -showdestinations` lists the simulators you have.
Launch argument `-mock` forces `AppEnvironment.mock`.

## How to plug your work in

1. Build your screen in your folder and return it from your workstream's `…Screens.swift` switch (`InfraScreens`, `WalkScreens`, `EndScreens`). Never edit `RootView`.
2. Implement the protocol from `OnderaCore/Sources/OnderaCore/Shared/Protocols.swift` and swap it in with **one line** in `AppEnvironment.live`.
3. Read dependencies from `@Environment(\.app)` and navigate with `@Environment(AppRouter.self)`.
4. Use `SampleData.syntheticFinishedWalk()` / `SampleData.syntheticField` for previews and tests (SYNTHETIC).
5. If you replace a placeholder, keep `accessibilityIdentifier("screen.<id>")` on the screen and `go.<id>` on the buttons the UI test taps, or update `PlaceholderFlowUITests`.
