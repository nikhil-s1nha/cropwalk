---
description: Show the TASKS.md board as a table and recommend the next 3 tasks
---

Run `git pull --ff-only` (ignore failure if offline), then read `TASKS.md`.

1. Print a markdown table with one row per task: **#**, **Title**, **Workstream**, **Status** (`[ ]` / `[~] who` / `[x]`), **Depends on**, **Ready?** (yes if every dependency is `[x]` done; "mockable" if the only missing dependencies can be replaced by Task 0 mocks; otherwise no).
2. Show progress per workstream (done / in progress / open) and which checkpoint is next (from the Checkpoints table) with the tasks still missing for it.
3. Recommend the **next 3 tasks** to start: prefer tasks needed for the next checkpoint, that are ready or mockable, not in progress, and that unblock the most other tasks. Respect the cut order (don't recommend stretch tasks while checkpoint tasks are open). One line of reasoning each.

Don't modify any files.
