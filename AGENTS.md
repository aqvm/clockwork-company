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

## GitHub guidance

- Never commit to `main`.
- Before committing changes, resync with `main`.
- If local work is on `main`, create a helpfully named branch before committing.

## Done means

A task is not done until:

- the project still opens/runs if applicable
- changed behavior is manually testable
- you summarize the diff
- you explain new concepts introduced
- you point out one file I should inspect closely
- you give me one manual follow-up exercise
