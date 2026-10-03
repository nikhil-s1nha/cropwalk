---
description: Work on task N from TASKS.md using the CLAUDE.md task protocol
argument-hint: <task number>
---

Work on task **$ARGUMENTS** from `TASKS.md`.

Follow the **"How to work on a task"** protocol in `CLAUDE.md` exactly:

1. `git pull`, then read task $ARGUMENTS in `TASKS.md` in full, plus the sections of `docs/WORKFLOW.md` it references and the hard rules in `CLAUDE.md`.
2. Check its "Depends on". For dependencies not `[x] done`, use the Task 0 protocols/mocks (or a stub inside this task's own paths). Don't implement another task's scope.
3. Claim it on `main`: change only this task's status line to `[~] in progress (<git user.name>, <time>)`, commit `task $ARGUMENTS: claim`, push (pull --rebase and retry if rejected). If it's already `[~]` or `[x]`, stop and tell me.
4. Create branch `task-$ARGUMENTS-<short-name>`.
5. Work only in the task's "Where" paths; shared files additive only.
6. Meet every "Done when" item, with tests. If time is short, deliver the "Minimum" first and say so.
7. Mark `[x] done — <one-line note>`, tick the met "Done when" boxes, commit `task $ARGUMENTS: <summary>`, push the branch and open a PR (`gh pr create --fill`) if `gh` is available.
8. Finish by telling me what was built, what is Minimum-only or missing, and exactly how to test it (commands + manual/simulator/airplane-mode steps).

If `$ARGUMENTS` is empty: list the open tasks whose dependencies are done (or mockable), grouped by workstream, recommend one, and wait for me to pick.
