# Ondera Leaf Walk

**Offline-first iPhone app for a weekend coffee-leaf scouting walk.** Built for the *Small AI for Development Hackathon* (World Bank Youth Summit × Hack-Nation), Agriculture track. Brief: [`docs/brief.pdf`](docs/brief.pdf). Deadline: **end of Sunday 4 Oct 2026**.

Noor, a Swahili-speaking coffee smallholder with no Wi-Fi, walks her field with her daughter's iPhone on a Saturday:

1. **Setup** — Swahili, consent, walk the field boundary with GPS, mark known problem spots.
2. **Walk** — the app plans a W-shaped route with 10 stops and vibrates at each one.
3. **Stop** — she checks 10 leaves on the nearest tree (UH CTAHR pd-125 protocol) and taps how many have spots.
4. **Photo + AI** — a quality gate checks the photo of the worst leaf; an on-device Core ML model labels it (healthy / rust / leaf miner / cercospora / phoma / unknown), with an optional Swahili voice note. When unsure, it says so: *"Sina uhakika — mti umewekwa alama kwa afisa ugani."*
5. **End screen** — leaf-spot incidence with a 95% interval, coloured stop map, a recommendation from a fixed list, a confirm-before-send SMS to the cooperative (store-and-forward), and an estimated reference price with source and date.
6. **Weekday** — SMS check-in on her basic phone (mock).

Everything core runs in **airplane mode**. Models are under 10 MB. Photos never leave the phone. No LLM.

| Doc | What's in it |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Hard rules, stack, folder ownership, and the task protocol Claude follows |
| [`TASKS.md`](TASKS.md) | All numbered tasks, checkpoints, cut order |
| [`docs/WORKFLOW.md`](docs/WORKFLOW.md) | Screens, fixed messages, fusion rules, SMS + pricing templates, Swahili prompts |
| `docs/DATA_CARD.md`, `PRICING.md`, `PRIVACY.md`, `SWAHILI_REVIEW.md`, `DEMO_AND_VIDEO.md` | Filled in by their tasks |

## Repo layout

```
app/        iOS app (Xcode project, OnderaCore Swift package)   — created by Task 0
backend/    FastAPI + SQLite: coop inbox, SMS mock, prices, alerts
ml/         dataset prep, classifier + keyword-spotter training
tools/      ElevenLabs audio script, quality-gate tuning, synthetic data, QA
docs/       brief, workflow spec, data card, privacy, pricing, demo
```

## Teammate workflow

```bash
git pull          # get the latest board
claude            # start Claude Code in the repo root
/tasks            # board as a table + 3 recommended next tasks
/task 13          # Claude claims task 13, branches, builds, tests, marks it done, explains how to test
```

What `/task N` does (full protocol in `CLAUDE.md`):
1. Reads task N and checks its dependencies (uses mocks if they aren't done).
2. Marks **only** that task `[~] in progress` on `main` and pushes, so others can see it's taken.
3. Works on branch `task-N-<name>`, stays inside the task's paths (shared files are additive only).
4. Meets every "Done when" item with tests; ships the "Minimum" version first if time is short.
5. Marks it `[x] done` with a one-line note, commits `task N: …`, pushes and opens a PR.
6. Tells you how to test it.

Before Task 0 lands, only tasks with no app dependency can start (5, 10, 17, 24, 29). Check `/tasks`.

## Checkpoints

- **Sat 6 pm** — all screens navigable with mocks
- **Sat midnight** — end-to-end demo in simulate-walk mode, airplane mode
- **Sun 2 pm** — feature freeze
- **Sun evening** — video submitted
