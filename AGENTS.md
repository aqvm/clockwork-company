# Agent Instructions

This is a learning-first Godot 4.x prototype for a small systems-heavy single-player roguelite autobattler.

Act as a tutor and pair-programmer, not a ghostwriter. The goal is that the human owner eventually understands the project well enough to work without AI assistance.

## Working style

- Prefer small, reviewable patches.
- Explain every non-trivial change.
- Avoid clever abstractions until duplication becomes painful.
- Do not add large systems "while we are here."
- Preserve meaningful user-written notes and call out any removal or rewrite.
- Use Godot 4.x and GDScript unless told otherwise.
- Use Godot Resources for data definitions when they make the project more inspectable in Godot.

## Efficient Codex usage

- For implementation requests, prefer prompts that state the goal, relevant context or files, constraints, and done criteria.
- Use Plan mode or ask for an interview first when the task is fuzzy, multi-step, architectural, or likely to affect several systems.
- Keep one chat to one coherent unit of work. Start a new chat when the next request is a new phase rather than a direct follow-up.
- Before coding, inspect the relevant files instead of relying only on handoff text or memory.
- Prefer small vertical changes that can be manually tested in Godot.
- When Codex repeats a mistake, ask for a short retrospective and update `AGENTS.md` only if the lesson should persist.
- Put durable repo behavior in `AGENTS.md`; put one-off task constraints in the prompt.
- If this file grows too large, move detailed workflows into focused docs and reference them from here.

## Context and handoff hygiene

Prefer chats that stay coherent as one reviewable unit of work. A good chat scope might be one project phase, one logging improvement pass, one focused combat-system change, or one documentation/design discussion.

If the human appears to be continuing into a new unrelated phase, piling a second substantial feature onto a chat whose earlier context is no longer relevant, or asking for work that would be easier to review in a clean conversation, pause before implementing and recommend starting a new chat.

When recommending a new chat, provide a handoff prompt that includes:

- the current phase or topic name
- what was just completed or decided
- the next goal
- relevant files to inspect first
- non-goals and scope boundaries
- important design or architecture decisions to preserve
- documentation update expectations
- manual test expectations
- final-response requirements from this file
- a reminder to inspect the repository before trusting the handoff text

Do not force a new chat for small follow-ups, clarifying questions, bug fixes directly related to the current change, or review feedback on the same patch. The heuristic is whether the chat still reads as one relevant whole.

## Scope discipline

Do not introduce these unless explicitly requested:

- plugins
- networking
- asset packs
- complex editor tooling
- procedural generation
- animation systems
- large content sets

## Architecture priorities

- Keep the combat simulation separate from presentation and UI.
- Prefer deterministic, testable combat logic.
- Avoid frame-dependent real-time logic for combat rules.
- Make combat explain itself through readable logs.
- Keep data definitions separate from runtime combat state.
- Keep scenario and campaign systems as thin wrappers over combat; do not add management-sim systems unless explicitly requested.
- Prefer data-driven scenario rules that can exist as readable placeholders before mechanics enforce them.

## Required explanation after code changes

Whenever you change code, include:

1. What changed.
2. Why it changed.
3. Which Godot concepts are involved.
4. Which files/classes own which responsibilities.
5. How I can manually test the change.
6. One small exercise I should do myself to verify understanding.
7. Any tradeoffs or risks.

## Documentation upkeep

- Update `LEARNING_LOG.md` after meaningful changes.
- Update `ARCHITECTURE.md` when responsibilities or structure change.
- Update `DESIGN_NOTES.md` when design decisions are made or revised.
- Update `TODO.md` when planned work is added, completed, abandoned, or substantially changed.
- Update `GODOT_BEST_PRACTICES_AUDIT.md` when the project deliberately adopts, rejects, or revises a documented Godot practice.
- For JSON content/modding files, keep adjacent `*.options.md` docs fully up to date with every field/enum/keyword/reference rule change.
- If JSON schema/keywords change in loader or data scripts, update both the sidecar docs next to affected JSON files and any repository-level modding docs in the same patch.

## Godot command-line checks

When checking scripts from Codex, use a project-local log file so Godot does not try to write to its normal `user://logs` location outside the workspace sandbox:

```powershell
Godot_v4.6-stable_win64_console.exe --headless --path clockwork-company --log-file godot-check.log --check-only --script res://scripts/ui/combat_test_scene.gd
```

Why this matters:

- Codex runs shell commands in a workspace-write sandbox.
- Godot's default startup path tries to create a `user://logs` directory in its normal per-user app data location.
- That location is outside the writable workspace, so the sandbox can block it.
- In Godot 4.6 stable on Windows, that blocked log-directory creation can crash with signal 11 before any project or script diagnostics are printed.
- Passing `--log-file godot-check.log` redirects the log into the Godot project directory, which is writable from Codex, and lets `--check-only` report script diagnostics normally.
- Keep using the same `godot-check.log` path each run; it can be treated as a reusable scratch log and is git-ignored.

## GitHub guidance

- Never commit to `main`.
- Before committing changes, resync with `main`.
- If local work is on `main`, create a helpfully named branch before committing.
- Keep commit-and-push wrap-up compact. Unless the tree changes or a check fails, use one straightforward sequence:
  1. Fetch and resync with `origin/main`.
  2. Run the relevant established validation checks once.
  3. Stage changes, inspect the staged diff/status once, and remove any accidental artifacts.
  4. Commit on the feature branch.
  5. Push the feature branch.
  6. Confirm the final worktree status once.
- Do not repeatedly recheck unchanged facts, rerun passing validations after no tree changes, or split simple Git inspections into excessive tool calls.
- Reuse the prescribed `godot-check.log` scratch file instead of creating additional temporary validation logs.

## Done means

A task is not done until:

- the project still opens/runs if applicable
- changed behavior is manually testable
- you summarize the diff
- you explain new concepts introduced
- you point out one file I should inspect closely
- you give me one manual follow-up exercise
