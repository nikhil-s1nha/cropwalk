# TASKS — Ondera Leaf Walk

Status markers: `[ ]` open · `[~] in progress (who, when)` · `[x] done — note`.
Protocol for picking up a task: see **"How to work on a task"** in `CLAUDE.md` (or run `/task N`). Board view: `/tasks`.
Spec for every screen, message and rule: `docs/WORKFLOW.md`.

Workstreams: **0** shared · **A** app infra, Swahili, ML · **B** walk feature · **C** end screen · **D** stretch & submission.

---

## Checkpoints

| When | Checkpoint | Must be done (Minimum OK) |
|---|---|---|
| **Sat 3 Oct, 6 pm** | Every screen exists and is navigable on the simulator using mocks (setup → walk → stop → photo → end screen → next steps). | 0, 1, 3, 15, 16, 22 (+ placeholder screens from 0 for the rest) |
| **Sat 3 Oct, midnight** | **End-to-end demo in "simulate walk" mode**, in airplane mode, with real route planner, real summary maths, real fusion rules, stored results, outbox queueing. Classifier may still be mock. | 2, 4, 12, 13, 14, 18, 19, 20, 21, 23 |
| **Sun 4 Oct, 2 pm** | **Feature freeze.** Real classifier in app, Swahili strings + audio in, pricing panel, backend inbox. After this: bug fixes, docs, video only. | 7, 8, 11, 26, 5, 30 started |
| **Sun 4 Oct, evening** | **Video (2–5 min) + repo submitted.** | 28, 29, 30 |

## Cut order (if behind — cut from the top)

1. **27** variogram alerts (stretch) → drop entirely.
2. **6** weekday SMS mock → a static mock screenshot/web page in the video.
3. **9** keyword spotting → Minimum: voice note recorded + Noor taps symptom chips (no AI on voice).
4. **25/26** live price backend → bundled price snapshot JSON with source + date.
5. **8** ElevenLabs audio → text only (keep strings).
6. MapKit part of **14** → offline-fallback drawing only.
7. **17** OpenCV tuning → hand-set thresholds in Swift (state that they are untuned).
8. **11** → smaller model / fewer classes; anything not covered goes to "unknown".

**Never cut**: airplane-mode core flow, consent, confirm-before-send, AMBER "not sure" path, Swahili UI text, honest metrics, SYNTHETIC labels, photos-stay-on-phone.

---

## Task 0 — Shared

### Task 0 — Xcode project skeleton, shared models, protocols and mocks
- **Workstream:** 0 (shared, do first)
- **Status:** [~] in progress (Nikhil, Sat 13:05)
- **Depends on:** —
- **Where:** `app/OnderaLeafWalk.xcodeproj`, `app/OnderaLeafWalk/{Shared,Infra,Walk,EndScreen,Resources}/`, `app/OnderaCore/` (Swift package), `app/OnderaLeafWalkTests/`
- **What:**
  - Xcode 16 project, iOS 17+, SwiftUI app `OnderaLeafWalk`, using **synchronized folders** so new files never require `project.pbxproj` edits. Local package `app/OnderaCore` linked into the app.
  - Folders `Shared/ Infra/ Walk/ EndScreen/ Resources/` in the app, and `Shared/ Infra/ Walk/ EndScreen/` in `OnderaCore/Sources/OnderaCore/` (each with a `README.md` line naming the owner workstream).
  - **Shared models** (`OnderaCore/Shared`, `Codable`, `Equatable`): `GeoPoint`, `FieldBoundary` (polygon + areaHa), `ProblemSpot` (center, radiusM), `Route` (polyline + `[Stop]`), `Stop` (index, point, isProblemSpot), `StopObservation` (stopIndex, leavesChecked = 10, leavesWithSpots 0–10, photoID?, qualityResult?, classification?, voiceKeywords, verdict), `QualityResult` (pass/fail + reason enum: blurry/tooDark/tooBright/leafNotFilling), `LeafClass` enum (healthy, rust, leafMiner, cercospora, phoma, unknown), `Classification` (top class, confidence, all scores), `KeywordHit`, `StopVerdict` (green/amber + reason), `WalkSession` (id, date, field, route, observations, seed, isSynthetic), `WalkSummary`, `RecommendationID` enum, `OutboxMessage` (id, recipient, body, createdAt, status: draft/queued/sent/failed), `PriceSnapshot` (source, seriesName, date, value, unit, fetchedAt), `ConsentRecord`.
  - **Protocols** (one per seam): `RoutePlanning`, `LocationProviding`, `BoundaryRecording`, `PhotoQualityChecking`, `LeafClassifying`, `KeywordSpotting`, `VoiceRecording`, `FusionDeciding`, `SummaryCalculating`, `RecommendationProviding`, `SMSComposing`, `OutboxStoring`/`OutboxSending`, `PriceProviding`, `WalkStoring`, `AudioPrompting`, `Haptics`.
  - **Mocks** for every protocol (`Mock…`), deterministic, plus `AppEnvironment` (`.mock`, `.live`) injected via SwiftUI `Environment` so each owner swaps in their live implementation in one line.
  - `AppRoute` navigation enum covering every screen in `docs/WORKFLOW.md`, with a **placeholder view per screen** (title + "TODO task N") so the flow is clickable on day one.
  - A synthetic sample field `Resources/SYNTHETIC_sample_field.geojson` (~0.5 ha rectangle-ish polygon + 1 problem spot) used by mocks/simulate mode.
  - Empty per-workstream string tables `Infra.xcstrings`, `Walk.xcstrings`, `EndScreen.xcstrings` with `sw` + `en` languages enabled; dev language `sw`.
- **Minimum:** Project builds, models + protocols + mocks exist, placeholder screens navigable.
- **Done when:**
  - [ ] `swift test` passes in `app/OnderaCore` (at least model Codable round-trip tests).
  - [ ] App builds and runs on the iPhone simulator; every `AppRoute` placeholder is reachable by tapping through.
  - [ ] Adding a new `.swift` file to any folder needs no `project.pbxproj` change (verified once).
  - [ ] Every protocol has a mock, and `AppEnvironment.mock` drives the whole placeholder flow.
  - [ ] Folder READMEs name owners; CLAUDE.md layout still accurate.

---

## Workstream A — App infra, Swahili, ML

### Task 1 — App shell, navigation and language choice
- **Workstream:** A
- **Status:** [ ]
- **Depends on:** 0
- **Where:** `app/OnderaLeafWalk/Infra/Shell/`, `app/OnderaLeafWalk/OnderaLeafWalkApp.swift`
- **What:** `NavigationStack` driven by `AppRoute`; home screen (Start new walk / Continue walk / Past walks / Settings); language picker (Kiswahili default, English) stored in settings and applied app-wide (in-app locale override, not only system locale); large-tap-target style; "Demo data" badge component for synthetic sessions; Settings: language, simulate-walk toggle, backend URL, delete all data.
- **Minimum:** Navigation through all screens + language switch working.
- **Done when:**
  - [ ] Switching language changes all visible strings immediately without restart.
  - [ ] Back/forward navigation works for the full flow; app restores to home after relaunch (or to the in-progress walk once Task 2 exists).
  - [ ] Simulate-walk toggle visible and passed through `AppEnvironment`.
  - [ ] UI test or snapshot proving home → setup → walk → end screen reachable with mocks.

### Task 2 — Local storage (walks, observations, photos)
- **Workstream:** A
- **Status:** [ ]
- **Depends on:** 0
- **Where:** `app/OnderaLeafWalk/Infra/Storage/`, `app/OnderaCore/Sources/OnderaCore/Infra/Storage/`
- **What:** `WalkStoring` live implementation (SwiftData or JSON files in Application Support). Save after **every** stop so a crash/battery loss loses nothing; resume an in-progress walk. Photos and voice notes saved as files in a private folder with `FileProtectionType.complete` and `isExcludedFromBackup = true`; referenced by ID only. Past walks list. "Delete all data" wipes walks, photos, audio, outbox.
- **Minimum:** JSON-file store for sessions + photo files with protection flags; resume works.
- **Done when:**
  - [ ] Tests: save/load round trip, resume mid-walk, delete-all leaves no files behind.
  - [ ] Photo files have complete protection + excluded from backup (asserted in a test).
  - [ ] Killing the app mid-walk and relaunching offers "Continue walk" at the right stop.

### Task 3 — Consent screen and privacy notice
- **Workstream:** A
- **Status:** [ ]
- **Depends on:** 0 (1 for navigation polish)
- **Where:** `app/OnderaLeafWalk/Infra/Consent/`, `docs/PRIVACY.md`
- **What:** Consent screen in Swahili (text from `docs/WORKFLOW.md` §Consent) with audio play button; explains: what is stored, that photos/voice stay on this phone, that nothing is sent without her tap, that results can be deleted, that AI can be wrong and will say "not sure". Explicit Agree / Not now. Store `ConsentRecord` (version, date, language). Walk cannot start without consent. Write `docs/PRIVACY.md`: data inventory (what, where, who can read, retention), shared-phone and lost-phone scenarios, what goes in SMS, backend data, deletion.
- **Minimum:** Consent screen + stored record + gate; PRIVACY.md data inventory table.
- **Done when:**
  - [ ] Cannot reach the walk without consent; consent can be withdrawn in Settings (offers delete-all).
  - [ ] Consent text listed in `docs/SWAHILI_REVIEW.md`.
  - [ ] `docs/PRIVACY.md` covers storage, SMS content, backend, shared/lost phone, deletion, and the human-in-loop guarantees.

### Task 4 — Outbox and store-and-forward SMS
- **Workstream:** A
- **Status:** [ ]
- **Depends on:** 0, 2
- **Where:** `app/OnderaLeafWalk/Infra/Outbox/`, `app/OnderaCore/Sources/OnderaCore/Infra/Outbox/`
- **What:** Persistent outbox of `OutboxMessage`s. A message only enters the outbox after the user has seen the **exact text** and tapped confirm (the preview UI lives in Task 23; this task provides `enqueue(confirmed:)` that refuses unconfirmed messages). Two transports: (a) **HTTP to the backend mock gateway** (`POST /sms/send`) when `NWPathMonitor` says online — retries with backoff, (b) **native SMS** via `MFMessageComposeViewController` pre-filled (user taps send — works on GSM with no data; not available on the simulator). Outbox screen: queued/sent/failed with retry and cancel. Never sends photo or audio.
- **Minimum:** Persistent queue + HTTP transport that flushes when the backend becomes reachable; outbox list screen.
- **Done when:**
  - [ ] Tests: unconfirmed enqueue is rejected; queued messages survive relaunch; flush sends in order and marks sent; failure → retry; body > 160 chars rejected.
  - [ ] Demo: queue in airplane mode → turn network on → message appears in backend inbox (Task 5).
  - [ ] Grep check: no code path attaches photo/audio files to any outgoing request.

### Task 5 — FastAPI + SQLite backend (cooperative inbox)
- **Workstream:** A
- **Status:** [~] in progress (Nikhil, Sat 13:05)
- **Depends on:** — 
- **Where:** `backend/` (except `backend/app/price*` = C, `backend/app/alerts*` = D)
- **What:** FastAPI app with SQLite (`backend/data/ondera.db`, git-ignored). Endpoints: `POST /sms/send` (mock SMS gateway: stores message, recipient, received_at), `GET /coop/inbox` (simple HTML page for the cooperative officer listing received walk reports, newest first, parsed fields from the SMS template), `GET /health`. Router stubs for `/price/latest` (C) and `/alerts` (D) so others plug in. `requirements.txt`, `README` run instructions, seed script. No photos or audio endpoints, ever.
- **Minimum:** `/sms/send` + `/coop/inbox` + tests.
- **Done when:**
  - [ ] `cd backend && pytest` passes (send → appears in inbox; malformed rejected; >160 chars rejected).
  - [ ] `uvicorn app.main:app` runs; iOS simulator can reach it at `http://localhost:8000`.
  - [ ] Inbox page parses the SMS template from `docs/WORKFLOW.md` into columns.

### Task 6 — Weekday SMS check-in mock (basic phone)
- **Workstream:** A
- **Status:** [ ]
- **Depends on:** 5
- **Where:** `backend/app/checkin*`, `backend/templates/phone*`
- **What:** Simulates the weekday follow-up to Noor's **basic phone**: a web page styled as a feature-phone screen; endpoint to trigger the Wednesday check-in (fixed Swahili template from `docs/WORKFLOW.md` §Weekday SMS, filled from her last walk report); Noor replies with a number (1/2/3); reply parsed with fixed keyword rules and shown in the coop inbox. Clearly labelled "MOCK — no real SMS".
- **Minimum:** Trigger endpoint + phone page showing the message + numeric reply parsed.
- **Done when:**
  - [ ] pytest: check-in text ≤ 160 chars, built only from fixed template; replies 1/2/3 + unknown reply → "not understood, call back" path.
  - [ ] Page usable in a browser for the demo video; labelled MOCK.

### Task 7 — Swahili strings and localisation
- **Workstream:** A
- **Status:** [ ]
- **Depends on:** 0
- **Where:** `app/OnderaLeafWalk/Resources/*.xcstrings` (translations), `docs/SWAHILI_REVIEW.md`
- **What:** Fill Swahili + English for every key in all three string tables using `docs/WORKFLOW.md` as source. Keep each workstream's keys in its own table (owners add keys; this task fills/reviews translations). Build `docs/SWAHILI_REVIEW.md`: table of key / English / Swahili draft / reviewer / status, and get at least one native or fluent speaker to review (name + date, or "not yet reviewed"). Add a script/test that fails if any key lacks `sw`.
- **Minimum:** All keys on the core flow have `sw`; review doc lists them as "draft, not reviewed".
- **Done when:**
  - [ ] Missing-translation check passes (no `sw` gaps).
  - [ ] Running the app in Swahili shows no English on the core flow.
  - [ ] `docs/SWAHILI_REVIEW.md` complete with review status; we can answer "how would this fare in a less-supported language?" (paragraph in the doc).

### Task 8 — ElevenLabs build-time Swahili audio
- **Workstream:** A
- **Status:** [ ]
- **Depends on:** 7 (text), 0
- **Where:** `tools/audio/`, `app/OnderaLeafWalk/Resources/Audio/sw/`, `app/OnderaLeafWalk/Infra/Audio/`
- **What:** `tools/audio/prompts.csv` (key, sw text, en text) generated from/kept in sync with the string tables for spoken prompts (`docs/WORKFLOW.md` §Swahili prompts). `generate_audio.py` reads `ELEVENLABS_API_KEY` from `.env`, uses a model/voice that supports Swahili (verify in ElevenLabs docs), writes `<key>.m4a` (convert with `afconvert`, small bitrate), and a `manifest.json` with text hashes so only changed prompts regenerate. App-side `AudioPrompting` live impl plays bundled files (offline) with a speaker button on each screen. **App never calls ElevenLabs.** Record voice/model/date and terms in `docs/DATA_CARD.md` notes.
- **Minimum:** Audio for consent, stop arrival, leaf count, photo retake, not-sure, and the recommendation messages.
- **Done when:**
  - [ ] Script idempotent (second run makes no API calls); no key in git.
  - [ ] Total bundled audio size reported; app plays prompts in airplane mode.
  - [ ] Grep check: no ElevenLabs host in app code.

### Task 9 — Voice note and on-device Swahili keyword spotting
- **Workstream:** A
- **Status:** [ ]
- **Depends on:** 0
- **Where:** `app/OnderaLeafWalk/Infra/Voice/`, `ml/kws/`
- **What:** Optional voice note at a stop (hold-to-record, ≤ 15 s, stored locally only). Detect ~10 Swahili symptom keywords (list in `docs/WORKFLOW.md` §Keywords) on-device → `[KeywordHit]` with scores → symptom hints for fusion. Approach, in order: (1) check whether `SFSpeechRecognizer` supports `sw` with `requiresOnDeviceRecognition` — use it only if truly on-device; (2) otherwise train a tiny KWS model (log-mel + small CNN, < 1 MB) in `ml/kws/` from Mozilla Common Voice Swahili (CC0) word clips via forced alignment + team recordings, export to Core ML; (3) Minimum fallback below. Show detected words as chips Noor can confirm/remove (human in loop). Report precision/recall per keyword on a held-out set — or "not measured".
- **Minimum:** Voice note recorded + stored; Noor taps symptom chips (labelled as manual); `KeywordSpotting` returns her taps. State that no voice AI shipped.
- **Done when:**
  - [ ] Works in airplane mode; audio never leaves the phone.
  - [ ] Model (if any) < 1 MB and counted in the 10 MB budget.
  - [ ] Eval numbers in `ml/kws/REPORT.md` from an actual run, with data sources + licences.
  - [ ] Tests for the keyword→symptom mapping.

### Task 10 — Coffee leaf dataset parsing, dedupe and split
- **Workstream:** A
- **Status:** [ ]
- **Depends on:** —
- **Where:** `ml/data_prep/`, `ml/data/` (git-ignored)
- **What:** Download scripts (or documented manual steps) for **JMuBEN** (+ JMuBEN2) and **BRACOL** from Mendeley Data; record exact DOI, version, licence, image counts. Map source labels to our 6 classes (`docs/WORKFLOW.md` §Classes; note e.g. "brown leaf spot" ↔ phoma — verify against each dataset's paper). **Dedupe** with perceptual hashing (JMuBEN contains augmented/near-duplicate crops) and **split by source image** so near-duplicates never cross train/val/test. Build a separate **field-style eval set** from BRACOT photos (verify availability and licence; if unavailable, another field set such as RoCoLe or team-taken photos — document which). Output `manifest.csv` (path, class, source dataset, group_id, split).
- **Minimum:** One dataset (BRACOL or JMuBEN) parsed + dedupe + group split + manifest.
- **Done when:**
  - [ ] pytest: no group_id appears in two splits; no pHash near-duplicate pairs across splits; class counts printed.
  - [ ] `ml/data_prep/DATASETS.md`: source, licence, size, label mapping, what the data does **not** cover (studio backgrounds, varieties, lighting, phone cameras, regions).

### Task 11 — Train, evaluate and export the disease classifier
- **Workstream:** A
- **Status:** [ ]
- **Depends on:** 10
- **Where:** `ml/classifier/`, output `app/OnderaLeafWalk/Resources/Models/LeafClassifier.mlpackage`
- **What:** Fine-tune a small backbone (e.g. MobileNetV3-Small / EfficientNet-Lite0) with field-style augmentation (blur, light, background clutter, crop); classes healthy/rust/leafMiner/cercospora/phoma + "unknown" handled by confidence threshold (optionally an "other" class from non-coffee leaves — labelled). Export with `coremltools`, quantize (fp16 or int8) to **≤ 6 MB**. Evaluate on (a) held-out lab test split and (b) the field-style set: accuracy, per-class precision/recall, confusion matrix, and **coverage vs. precision curve** to choose the confidence thresholds used by fusion (Task 20). Write numbers into `ml/classifier/REPORT.md` from the actual run (seed, commit, date). Provide a tiny fixture set of images for app tests.
- **Minimum:** Model trained on available data, exported < 6 MB, honest eval on held-out split; field eval "not measured" if no field set.
- **Done when:**
  - [ ] `.mlpackage` committed (size checked), input size/normalisation documented for Task 19.
  - [ ] REPORT.md has lab vs field results side by side and the chosen thresholds with justification.
  - [ ] Reproducible: `python train.py --config …` + `python export.py` documented.

---

## Workstream B — Walk feature

### Task 12 — Field boundary capture and problem spots
- **Workstream:** B
- **Status:** [ ]
- **Depends on:** 0
- **Where:** `app/OnderaLeafWalk/Walk/Boundary/`, `app/OnderaCore/Sources/OnderaCore/Walk/Geometry/`
- **What:** "Walk your field edge" screen: start/stop recording; collect `CLLocation`s with accuracy filter (e.g. ≤ 15 m) and distance filter (~2 m); show live track + accuracy; close polygon, simplify (Douglas–Peucker), reject self-intersecting/too-small polygons with a fixed message; show area in ha. "Mark problem spot here" button (current position, default 10 m radius) during or after the walk, plus tap-on-map to add/remove. Simulate mode loads `SYNTHETIC_sample_field.geojson`. Pure geometry (local metric projection, area, simplify, self-intersection, point-in-polygon) in `OnderaCore` with tests.
- **Minimum:** Simulate-mode boundary + manual problem-spot add; live GPS recording basic.
- **Done when:**
  - [ ] Geometry tests: area of known rectangles/triangles, simplify keeps corners, self-intersection detected, point-in-polygon.
  - [ ] Works with no network (no geocoding, no tiles required).
  - [ ] Location permission text in Swahili.

### Task 13 — Route planner (pure Swift + tests)
- **Workstream:** B
- **Status:** [ ]
- **Depends on:** 0 (uses 12's geometry if done; otherwise its own helpers in `Walk/Route/`)
- **Where:** `app/OnderaCore/Sources/OnderaCore/Walk/Route/`, tests in `app/OnderaCore/Tests/`
- **What:** `RoutePlanning` implementation per `docs/WORKFLOW.md` §Route rules: project to local metres; find longest axis (minimum-area bounding rectangle or PCA); inset by edge buffer (skip edge rows; default 2 rows × configurable row spacing); W polyline with 5 vertices alternating sides along the long axis; place **10 stops** evenly by arc length with **random start offset** (seeded RNG); clip/keep stops inside the inset polygon; ensure **≥ 1 stop inside every problem spot** (swap the nearest non-assigned stop to the spot centre, then re-order stops along the route). Degrade gracefully for tiny/odd fields (reduce buffer, warn).
- **Minimum:** Works for convex fields; problem-spot guarantee; tests.
- **Done when:**
  - [ ] Tests: always 10 stops; all inside polygon (and inside inset when feasible); each problem spot contains ≥ 1 stop; same seed → same route; different seeds → different offsets; route oriented along the long axis for a rotated rectangle; L-shaped field still valid; 3 problem spots handled.
  - [ ] Runs in < 50 ms for a 200-vertex boundary.

### Task 14 — Map view, offline fallback, arrival vibration, simulate-walk mode
- **Workstream:** B
- **Status:** [ ]
- **Depends on:** 12, 13 (mocks OK)
- **Where:** `app/OnderaLeafWalk/Walk/Map/`, `app/OnderaLeafWalk/Walk/WalkSession/`
- **What:** Reusable `FieldMapView(field:route:stops:position:stopColors:)` used by walk **and** end screen (Task 22). MapKit satellite/standard when tiles are available; **offline fallback**: SwiftUI `Canvas` drawing polygon, W route, numbered stops, current position, north arrow and scale bar on a plain background (auto when offline or toggled). Walk screen: next-stop distance/direction, "Stop k of 10". **Arrival** when within max(5 m, GPS accuracy) → strong haptic pattern + audio prompt + auto-open stop screen. **Simulate walk** mode: a `LocationProviding` that moves along the route at walking speed (×speed-up), used for the demo and simulator. Stop colours: grey = not done, green, amber, red per `docs/WORKFLOW.md`.
- **Minimum:** Offline Canvas map + simulate mode + haptic on arrival (MapKit optional).
- **Done when:**
  - [ ] In airplane mode the map still draws field/route/stops.
  - [ ] Simulate mode walks all 10 stops hands-free on the simulator, triggering arrival each time.
  - [ ] Unit tests for arrival detection and simulated path progression (in `OnderaCore`).

### Task 15 — Stop screen and leaf count
- **Workstream:** B
- **Status:** [ ]
- **Depends on:** 0
- **Where:** `app/OnderaLeafWalk/Walk/Stop/`
- **What:** Stop screen per `docs/WORKFLOW.md` §Stop: instructions with a simple illustration (lower third of tree, 3rd–4th leaf pair, 10 leaves) + audio button; big 0–10 count buttons (≥ 60 pt), confirm; count 0 → mark stop green and go to next; count > 0 → photo flow (Task 16) → optional voice → verdict. "Skip this stop" with a reason (no tree / can't reach) recorded, never silently dropped. Saves `StopObservation` via `WalkStoring` after each step.
- **Minimum:** Count buttons + instructions + save + routing to photo when > 0.
- **Done when:**
  - [ ] Count is stored exactly as tapped; AI results never modify it (test).
  - [ ] Skip is recorded and counted in the summary as "not checked" (n shrinks).
  - [ ] All strings from `Walk.xcstrings`, Swahili first.

### Task 16 — Camera with leaf outline
- **Workstream:** B
- **Status:** [ ]
- **Depends on:** 0
- **Where:** `app/OnderaLeafWalk/Walk/Camera/`
- **What:** AVFoundation camera screen with a leaf-shaped outline overlay; instruction "put the worst leaf inside the outline"; capture → crop/normalise to the outline region → pass to `PhotoQualityChecking` → GREEN "good photo" / RED "retake: <reason>" (fixed reasons); max 3 retakes then allow "continue without good photo" (→ AMBER later). Photo saved locally via storage (Task 2). Simulator: pick from a bundled fixture image instead of the camera.
- **Minimum:** Capture + outline overlay + mock quality result + fixture-image path for simulator.
- **Done when:**
  - [ ] Outline crop rectangle mapping tested (preview coords → image coords).
  - [ ] Works on simulator via fixtures and on a device with the camera.
  - [ ] Photo never written outside the protected folder.

### Task 17 — Quality-gate threshold tuning (Python + OpenCV)
- **Workstream:** B
- **Status:** [ ]
- **Depends on:** — (uses Task 10 data if available)
- **Where:** `tools/quality_gate/`
- **What:** Implement three metrics on the outline crop: **blur** (variance of Laplacian on grayscale), **brightness** (mean luma + % clipped dark/bright pixels), **leaf fill** (fraction of outline mask covered by leaf-coloured pixels — green **and** yellow/brown diseased tissue, e.g. ExG + HSV ranges). Build a small labelled set (team phone photos of any leaves: good / blurry / dark / bright / leaf too small) plus synthetic degradations of dataset images (label SYNTHETIC). Sweep thresholds, report precision/recall for "should retake", choose thresholds, export `thresholds.json` and fixture images + expected metric values for the Swift parity test.
- **Minimum:** Metrics + hand-picked thresholds on ~30 photos, `thresholds.json` + fixtures.
- **Done when:**
  - [ ] `pytest` for metric functions on generated images (solid, noise, blurred).
  - [ ] `tools/quality_gate/REPORT.md` with set size, sources, chosen thresholds, measured rates.
  - [ ] `thresholds.json` + `fixtures/expected_metrics.json` committed.

### Task 18 — Quality gate in Swift
- **Workstream:** B
- **Status:** [ ]
- **Depends on:** 16, 17 (hand-set thresholds if 17 not done)
- **Where:** `app/OnderaCore/Sources/OnderaCore/Walk/Quality/` (metric maths on raw RGBA buffers), `app/OnderaLeafWalk/Walk/Camera/` (CGImage → buffer glue)
- **What:** Same three metrics as Task 17 in Swift (Accelerate/vImage or plain loops on a downscaled buffer, < 100 ms). Load `thresholds.json` from bundle. Return `QualityResult` with the first failing reason in fixed priority: leafNotFilling → blurry → tooDark/tooBright.
- **Minimum:** Blur + brightness + fill with hand-set thresholds.
- **Done when:**
  - [ ] Parity test: Swift metrics on `fixtures/` within tolerance of Python's `expected_metrics.json`.
  - [ ] Unit tests for each fail reason.
  - [ ] Runs < 100 ms on device-sized image (measured, noted in status).

### Task 19 — Classifier integration (Core ML)
- **Workstream:** B
- **Status:** [ ]
- **Depends on:** 0, 11 (use mock / placeholder model until 11 is done)
- **Where:** `app/OnderaLeafWalk/Walk/Classifier/`
- **What:** `LeafClassifying` live implementation using Vision + the bundled `LeafClassifier.mlpackage` (preprocessing per Task 11 docs). Returns `Classification` with all class scores; maps low confidence to `unknown` using thresholds from `Resources/Models/classifier_thresholds.json` (written by Task 11). Runs off the main thread; fully offline. Bundle size check script `tools/check_model_size.sh` (fails if all models > 10 MB).
- **Minimum:** Integration working with whatever model exists (even a tiny placeholder) behind the protocol.
- **Done when:**
  - [ ] XCTest runs the model on fixture images and gets the expected top class for at least the fixtures Task 11 provides.
  - [ ] Works in airplane mode; < 500 ms per image on simulator (noted).
  - [ ] `tools/check_model_size.sh` passes.

### Task 20 — Photo + voice fusion rules (pure Swift + tests)
- **Workstream:** B
- **Status:** [ ]
- **Depends on:** 0
- **Where:** `app/OnderaCore/Sources/OnderaCore/Walk/Fusion/`
- **What:** `FusionDeciding` implementing the table in `docs/WORKFLOW.md` §Fusion rules exactly (inputs: count, quality result, classification, keyword hits; output: `StopVerdict` green/amber + fixed reason ID + flagged-for-officer bool + display label). Thresholds injected (defaults from the doc; Task 11 provides tuned values). Then wire the verdict screen in `app/OnderaLeafWalk/Walk/Stop/` showing GREEN or AMBER "not sure — tree flagged".
- **Minimum:** All table rows implemented with one test each.
- **Done when:**
  - [ ] One test per table row + boundary tests at each threshold.
  - [ ] Count never altered by fusion (test).
  - [ ] Every output maps to a fixed message key that exists in `Walk.xcstrings`.

---

## Workstream C — End screen

### Task 21 — Summary maths (pure Swift + tests)
- **Workstream:** C
- **Status:** [ ]
- **Depends on:** 0
- **Where:** `app/OnderaCore/Sources/OnderaCore/EndScreen/Summary/`
- **What:** `SummaryCalculating`: incidence = Σ leavesWithSpots / Σ leavesChecked over checked stops; **95% Wilson score interval** (z = 1.959964); per-stop colour; counts of flagged (amber) trees; dominant confident disease label (only from GREEN stops). `RecommendationProviding`: pick the fixed message per `docs/WORKFLOW.md` §Recommendation rules (threshold 5% example from pd-125; "close to treatment level" when the interval straddles it; not-enough-data rules). Thresholds in one config struct with a comment citing pd-125 and "verify".
- **Minimum:** Incidence + Wilson + recommendation selection with tests.
- **Done when:**
  - [ ] Tests use these vectors (x/n → %, low–high %): 0/100 → 0, 0.00–3.70 · 3/100 → 3, 1.03–8.45 · 5/100 → 5, 2.15–11.18 · 8/100 → 8, 4.11–15.00 · 12/100 → 12, 7.00–19.81 · 30/100 → 30, 21.89–39.58 · 100/100 → 100, 96.30–100 · 2/50 → 4, 1.10–13.46 · 0/10 → 0, 0.00–27.75 (tolerance 0.01).
  - [ ] Recommendation tests for every rule in WORKFLOW.md (low, close, above, not enough data, many flagged).
  - [ ] Skipped stops reduce n and are reported, never imputed.

### Task 22 — Summary UI (end screen)
- **Workstream:** C
- **Status:** [ ]
- **Depends on:** 21, 14 (use a placeholder map until 14's `FieldMapView` exists)
- **Where:** `app/OnderaLeafWalk/EndScreen/Summary/`
- **What:** End screen per `docs/WORKFLOW.md` §End screen: big incidence ("12 kati ya 100 majani yana madoa"), interval in plain words + simple bar with the 5% line, coloured stop map (`FieldMapView` with stop colours), recommendation text + audio button, list of flagged trees (tap → see photo on this phone), "Demo data" badge when synthetic, then the Next steps (Task 23) and Pricing panel (Task 26) sections.
- **Minimum:** Incidence + interval + recommendation + stop list with colours (map optional).
- **Done when:**
  - [ ] Renders correctly for: all-zero walk, mixed walk, all-amber walk, walk with skipped stops (previews or snapshot tests).
  - [ ] Swahili-first strings; no number shown without its label.

### Task 23 — Next steps: send to cooperative, check again, ask extension officer
- **Workstream:** C
- **Status:** [ ]
- **Depends on:** 21, 4 (mock outbox until done)
- **Where:** `app/OnderaLeafWalk/EndScreen/NextSteps/`, `app/OnderaCore/Sources/OnderaCore/EndScreen/SMS/`
- **What:** `SMSComposing` builds the cooperative SMS from `docs/WORKFLOW.md` §SMS template (≤ 160 chars, GSM-7 only, farmer ID not name). Three buttons: **Send to cooperative** → preview screen showing the **exact** SMS text + character count + recipient → Confirm / Cancel → outbox (Task 4) → status "Waiting for signal / Sent". **Check again next Saturday** → confirm → local notification next Saturday 08:00. **Ask extension officer** → preview of officer SMS (flagged stop numbers, counts) → confirm → outbox; plus on-phone list of flagged trees with photos to show the officer in person (photos never sent).
- **Minimum:** Cooperative SMS composer + preview + confirm + outbox enqueue.
- **Done when:**
  - [ ] Composer tests: ≤ 160 chars for worst-case values, GSM-7 only, all placeholders filled, deterministic.
  - [ ] Nothing is queued or scheduled without the confirm tap (test with mock outbox).
  - [ ] Notification permission asked only when she taps "check again".

### Task 24 — Pricing source research and conversion factors
- **Workstream:** C
- **Status:** [~] in progress (Tanish Priyadarshi, 2026-10-03 12:49)
- **Depends on:** —
- **Where:** `docs/PRICING.md`, `backend/app/price_data/`
- **What:** Find and verify a free, citable arabica reference price — e.g. **IMF Primary Commodity Prices "Coffee, Other Mild Arabicas"** (US cents/lb, monthly) or **World Bank Pink Sheet "Coffee, Arabica"** (USD/kg, monthly). Record URL, series code, units, frequency, latest value + date, licence/terms. Document every conversion factor with a citation: lb→kg, green ↔ parchment out-turn ratio, FX rate (source + date), and the farm-gate share range (cite a source, e.g. ICO or national coffee board data; if no source found, **don't show a farm-gate range** — only the reference price). Save a dated snapshot CSV/JSON. Produce the worked example used by the pricing template.
- **Minimum:** One verified source + snapshot file + documented conversions (uncited factors marked "not shown").
- **Done when:**
  - [ ] `docs/PRICING.md` has source table, each factor with citation + date, worked example, and the limitations (not a buyer offer, quality grades, local premiums).
  - [ ] No number in the doc lacks a source.

### Task 25 — Backend `/price/latest`
- **Workstream:** C
- **Status:** [ ]
- **Depends on:** 5 (router stub; can start standalone), 24
- **Where:** `backend/app/price*`, `backend/tests/test_price*`
- **What:** `GET /price/latest` returns `{source, series, unit, value, observed_date, fetched_at, fx_rate, fx_date, conversion: {...}, farm_gate_range: {low, high, currency, unit} | null, label: "estimate"}` from the snapshot (and optionally a refresh script that pulls the latest value from the source). Computation uses the documented factors only.
- **Minimum:** Serves the committed snapshot.
- **Done when:**
  - [ ] pytest: schema, conversion maths against the PRICING.md worked example, `farm_gate_range` null when factors are uncited.

### Task 26 — Pricing panel and cache in the app
- **Workstream:** C
- **Status:** [ ]
- **Depends on:** 25 (mock until done), 0
- **Where:** `app/OnderaLeafWalk/EndScreen/Pricing/`, `app/OnderaCore/Sources/OnderaCore/EndScreen/Pricing/`
- **What:** `PriceProviding` live: bundled snapshot as baseline; refresh from `/price/latest` when online (never blocks the UI); cache with `fetchedAt`. Panel uses the fixed pricing template from `docs/WORKFLOW.md` §Pricing: reference price, rough farm-gate range, **source + date always visible**, "Makadirio / estimate" label, and a "price is X days old" warning when stale (> 45 days).
- **Minimum:** Bundled snapshot shown with source, date and estimate label.
- **Done when:**
  - [ ] Works in airplane mode from bundle/cache.
  - [ ] Tests: staleness rule, formatting, never shows a value without source + date.

---

## Workstream D — Stretch and submission

### Task 27 — (Stretch) Cooperative variogram alerts on synthetic multi-farm data
- **Workstream:** D
- **Status:** [ ]
- **Depends on:** 5
- **Where:** `tools/synthetic/`, `backend/app/alerts*`, `backend/tests/test_alerts*`
- **What:** Generate `SYNTHETIC_farms.csv` (e.g. 40 farms, coordinates, weekly incidence with a spatially correlated rust hotspot) — clearly labelled synthetic. Compute an empirical semivariogram of farm incidence, fit a simple model (spherical/exponential), and raise a fixed-text alert when neighbours within the fitted range exceed the threshold ("rust rising near you — check this Saturday"). Show on the coop inbox page with a "SYNTHETIC DATA" banner. Alerts are suggestions to the cooperative officer, who decides whether to send.
- **Minimum:** Synthetic data + neighbour-incidence alert (no variogram fit), labelled.
- **Done when:**
  - [ ] pytest: variogram on synthetic data recovers the generating range within tolerance; alert text from fixed list.
  - [ ] Every output marked SYNTHETIC.

### Task 28 — Data card and evidence
- **Workstream:** D
- **Status:** [ ]
- **Depends on:** 10, 11, 24 (start early; fill as results arrive)
- **Where:** `docs/DATA_CARD.md`
- **What:** (1) **Problem-is-real evidence** — cited, with source, year, country (e.g. GSMA Mobile Gender Gap, FAOSTAT coffee yields, extension coverage, World Bank sources from the brief). (2) **Data we build with** — every dataset: name, source, licence, size, how used. (3) **What the data does not cover** (scored by judges): studio vs field images, varieties, regions, phone cameras, Swahili dialects, keyword list size. (4) Model cards: classifier + KWS metrics copied from REPORTs (no invented numbers), size, thresholds. (5) Synthetic data inventory. (6) ElevenLabs usage (build-time only).
- **Minimum:** Dataset table + coverage gaps + metrics copied from reports.
- **Done when:**
  - [ ] Every number has a source/run reference; every dataset has a licence.
  - [ ] "Does not cover" section has ≥ 6 concrete gaps.

### Task 29 — Demo plan, video script and judging checklist
- **Workstream:** D
- **Status:** [ ]
- **Depends on:** — (start Saturday; finalise after 2 pm Sunday)
- **Where:** `docs/DEMO_AND_VIDEO.md`
- **What:** 2–5 min video script covering the brief's required parts: one-sentence problem statement ("Because of this tool, Noor will … by … that she would otherwise …; we know because …"), AI capabilities + why SMS/spreadsheet/search can't do it + guardrails, end-to-end demo in **airplane mode** (show the toggle), where it sits in Noor's day + tech stack, "our take on localizing AI". Shot list, who records what, demo device setup, fallback (simulator recording). Judging checklist mapping each criterion (25/20/15/15/15/10 + pass/fail Responsible AI) to evidence in the repo.
- **Minimum:** Script + shot list + checklist.
- **Done when:**
  - [ ] Script timed ≤ 5 min; every brief-required section present.
  - [ ] Checklist items each point to a file/screen.
  - [ ] Video uploaded and link recorded in the doc; submission done.

### Task 30 — Integration, airplane-mode QA and release checks
- **Workstream:** D
- **Status:** [ ]
- **Depends on:** core tasks (run first pass Sat midnight, final pass Sun 2 pm)
- **Where:** `tools/qa/`, `docs/DEMO_AND_VIDEO.md` (QA section)
- **What:** Scripted checks: model size budget (`tools/check_model_size.sh`), missing Swahili strings, grep for network calls outside Outbox/Price, grep for ElevenLabs/LLM hosts in app, photo files never referenced by networking code, SYNTHETIC labels present. Manual QA checklist: fresh install → consent → simulate walk in airplane mode → end screen → send (queued) → network on → appears in coop inbox; kill-and-resume; Swahili-only pass; delete-all. Log bugs as new tasks at the bottom of this file.
- **Minimum:** Scripted checks + one full manual pass recorded.
- **Done when:**
  - [ ] `tools/qa/run_checks.sh` passes.
  - [ ] Manual checklist completed on simulator and (ideally) one real iPhone, with date.
