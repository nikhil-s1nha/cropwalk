# Ondera Leaf Walk — Claude project guide

Hackathon entry for the **Small AI for Development Hackathon** (World Bank Youth Summit × Hack-Nation), **Agriculture track (Annex B)**.
Brief: `docs/brief.pdf` (read pp. 1–12 and Annex B pp. 16–17). **Deadline: end of Sunday 4 Oct 2026.**

## What we are building

An **offline-first iPhone app (Swift/SwiftUI + Core ML)** that guides Noor through a weekend **coffee-leaf scouting walk**.
Noor is a smallholder, speaks Swahili, has a basic phone, can use her daughter's smartphone on weekends, and has no Wi-Fi.

1. **Setup**: choose Swahili → consent → walk the field boundary with GPS → optionally mark known problem spots.
2. **Walk**: W-shaped route along the field's longest axis (skip edge rows, random start offset, 10 stops, ≥1 stop in each problem spot). Phone vibrates at each stop.
3. **Stop**: check 10 leaves on the nearest tree (lower third, 3rd–4th leaf pair, UH CTAHR pd-125) → tap how many have spots (0–10).
4. **Photo** (if spots): worst leaf inside an on-screen outline → quality gate → GREEN "good photo" / RED "retake: <reason>".
5. **AI**: on-device classifier (healthy / rust / leaf miner / cercospora / phoma / unknown) + optional Swahili voice note with on-device keyword spotting. Disagreement or low confidence → AMBER "not sure, tree flagged for extension officer".
6. **End screen**: incidence %, 95% Wilson interval, coloured stop map, recommendation from a **fixed** message list, next steps (send to cooperative by SMS with preview + confirm + store-and-forward; check again next Saturday; ask extension officer), pricing panel (cached reference price → rough farm-gate range, with source + date, labelled "estimate").
7. **Weekday**: mock SMS check-in to Noor's basic phone. Stretch: cooperative-level variogram alerts on synthetic multi-farm data.

Full screen-by-screen spec, fixed messages, fusion table, SMS/pricing templates and Swahili prompts: **`docs/WORKFLOW.md`**. All tasks: **`TASKS.md`**.

## Hard rules (from the brief — never break these)

1. **Core works in airplane mode.** Setup → walk → photo → AI → end screen needs no network. Only outbox sending and price refresh use the network, and both degrade gracefully.
2. **Models < 10 MB total** (classifier + keyword spotter + anything else bundled as a model). Check with `ls -l` before committing a model.
3. **Swahili throughout.** Every user-facing string has a Swahili version; no hard-coded English in views. New strings go in the workstream's string table and get listed in `docs/SWAHILI_REVIEW.md`.
4. **Human in the loop.** The app never sends, schedules or acts without an explicit confirm tap. The AI never changes Noor's leaf count; it only labels and flags.
5. **Fixed answers only.** Everything the app "says" comes from the fixed lists in `docs/WORKFLOW.md`. No free-text generation. **No LLM anywhere** (build time or runtime).
6. **Explicit "not sure" fallback.** Low confidence, disagreement, or bad input → AMBER "not sure — tree flagged for extension officer". Never guess.
7. **Photos never leave the phone.** No photo or voice audio is uploaded, attached to SMS, or synced. SMS carries counts/labels only. Photos are stored with file protection and excluded from backup.
8. **Never invent metrics.** Accuracy numbers, prices, conversion factors, and evidence must come from a run we did or a cited source (with date). If we don't have it, say "not measured".
9. **Label synthetic data.** Any synthetic/simulated data has `SYNTHETIC` in its filename or table name and a visible "Data ya mfano / Demo data" badge in UI.

## Stack (team decision — don't change without the team)

- **iOS app**: Swift 5.10+/SwiftUI, iOS 17+, Core ML (+ Vision), AVFoundation, CoreLocation, MapKit, Core Haptics/UIFeedbackGenerator, SwiftData or JSON files for storage.
- **Pure logic**: local Swift package `app/OnderaCore` (no UIKit/MapKit) so tests run with `swift test` on a Mac in seconds.
- **Audio**: ElevenLabs at **build time only** (`tools/audio/`) to pre-generate bundled Swahili audio. The app never calls ElevenLabs. API key lives in `.env` (git-ignored).
- **Maps**: MapKit, plus an offline fallback that draws field/route/stops on a plain background.
- **Quality gate**: tuned with OpenCV in Python (`tools/quality_gate/`), then re-implemented in Swift with parity tests.
- **ML**: Python (PyTorch/timm or similar) → `coremltools` export. Datasets in `ml/data/` (git-ignored).
- **Backend**: FastAPI + SQLite (`backend/`), only for the cooperative inbox, SMS mock, price data and alerts.

## Repo layout and ownership

| Path | Owner | Notes |
|---|---|---|
| `app/OnderaLeafWalk.xcodeproj` | Task 0 | Uses Xcode 16 synchronized folders, so adding files must NOT require editing `project.pbxproj`. Avoid pbxproj edits; if unavoidable, keep them minimal and mention in the commit. |
| `app/OnderaLeafWalk/Shared/` | Task 0 (all, additive) | App environment/DI, navigation route enum, mocks, shared UI components. |
| `app/OnderaLeafWalk/Infra/` | **A** | App shell, storage, consent, outbox, audio player, voice note, KWS. |
| `app/OnderaLeafWalk/Walk/` | **B** | Boundary, map, route view, stops, leaf count, camera, quality gate, classifier, fusion. |
| `app/OnderaLeafWalk/EndScreen/` | **C** | Summary UI, next steps, pricing panel. |
| `app/OnderaLeafWalk/Resources/` | A (strings/audio), B (models, thresholds) | String tables are split per workstream: `Infra.xcstrings`, `Walk.xcstrings`, `EndScreen.xcstrings`. |
| `app/OnderaCore/Sources/OnderaCore/{Shared,Infra,Walk,EndScreen}/` | same as app folders | Pure Swift logic + models + protocols. Tests in `app/OnderaCore/Tests/`. |
| `backend/` | **A** (core, inbox, SMS mock); **C** `backend/app/price*`; **D** `backend/app/alerts*` | FastAPI + SQLite + pytest. |
| `ml/` | **A** | Dataset parsing, classifier training, KWS training, eval reports. |
| `tools/audio/` | A | ElevenLabs generation script. |
| `tools/quality_gate/` | B | OpenCV threshold tuning. |
| `tools/synthetic/` | D | Synthetic multi-farm data (labelled SYNTHETIC). |
| `docs/` | per file: `PRIVACY.md` A, `SWAHILI_REVIEW.md` A, `PRICING.md` C, `DATA_CARD.md` D, `DEMO_AND_VIDEO.md` D, `WORKFLOW.md` all (edit carefully) | |

**Shared files** (`Shared/`, `OnderaCore/.../Shared/`, `docs/WORKFLOW.md`, `TASKS.md`, `CLAUDE.md`): changes must be **additive** — add new types/cases/fields with defaults; never rename or delete what others use. If a breaking change is truly needed, stop and ask the user.

## How to work on a task

When the user says **"work on task N"** or **"/task N"**:

1. **Read** task N in `TASKS.md` in full, plus the relevant sections of `docs/WORKFLOW.md` and this file.
2. **Check dependencies** listed in "Depends on". `git pull` first. For any dependency not `[x] done`, **use the mocks/protocols from Task 0** (or write a local stub inside your own paths) — don't block, and don't implement another task's scope.
3. **Claim it**: on `main`, change **only that task's** status line to `- **Status:** [~] in progress (<git user.name>, <time>)`, commit `task N: claim`, push. If push is rejected, `git pull --rebase` and retry. If someone else already has it `[~]`, stop and tell the user.
4. **Branch**: `git checkout -b task-N-<short-kebab-name>`.
5. **Stay in the task's "Where" paths.** Shared-file changes are additive only (see above). Don't touch another workstream's folder; if you need something from it, use its protocol/mock.
6. **Build to "Done when"**: meet every item, with **tests** for all logic (`swift test` in `app/OnderaCore`, `pytest` in `backend/` or `ml/`/`tools/`, XCTest/`xcodebuild test` for app-target code where practical). Respect every hard rule above.
7. **Short on time?** Deliver the task's **"Minimum"** version first, commit it, then extend. Say clearly which parts are Minimum-only.
8. **Finish**: set the status line to `- **Status:** [x] done — <one-line note, e.g. "W planner + 14 tests; problem spots via nearest-stop swap">`. Tick the "Done when" boxes you met. Commit with message `task N: <summary>`.
9. **Integrate**: push the branch and open a PR (`gh pr create --fill`) if `gh` is available; otherwise rebase on `main` and push to `main` once tests pass. Don't merge with failing tests.
10. **Report** to the user: what was built, what's Minimum-only or missing, and **exactly how to test it** (commands + manual steps, including simulator / airplane-mode steps).

When the user says **"work on a task"** / **"/task"** without a number: list the open (`[ ]`) tasks whose dependencies are all `[x]` (or mockable), grouped by workstream, and recommend one. Don't start until the user picks.

## Conventions

- Build/test: `cd app/OnderaCore && swift test`; app: `xcodebuild -project app/OnderaLeafWalk.xcodeproj -scheme OnderaLeafWalk -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test` (add `OS=` — names alone can be ambiguous; see `app/README.md`); backend: `cd backend && pytest`.
- Every protocol in `Shared` has a `Mock…` implementation; `AppEnvironment.mock` must always compile and run the full flow.
- Swift: SwiftUI views stay thin; logic goes in `OnderaCore` with tests. Use `Codable` models. Seeded RNG for anything random (testability).
- Python: 3.11+, `requirements.txt` per folder, `pytest`. Secrets only in `.env`.
- Never commit datasets, model checkpoints larger than the shipped `.mlpackage`, `.env`, or photos of real people.
- Commit messages: `task N: <what>`. Small, frequent commits. No `Co-Authored-By: Claude` (or any AI attribution) trailers in commits or PRs.
