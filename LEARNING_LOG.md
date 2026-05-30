# Learning Log

This file tracks what I should understand as the project develops.

Each entry should include:

- Date
- Feature worked on
- Godot concepts introduced
- Game architecture concepts introduced
- Files touched
- What I should now be able to explain
- Manual exercise
- Open questions

## 2026-05-30 - Phase 1 text-only combat simulator

Feature worked on:

- Added one playable Godot scene with a button that runs a hardcoded deterministic 3v3 fight and prints a combat log.

Godot concepts introduced:

- A `.tscn` scene file stores a node tree.
- `Control` is the base node type for UI scenes.
- `Button` emits a `pressed` signal when clicked.
- `TextEdit` can display multiline text and is useful for a quick combat log.
- `@onready` waits until child nodes exist before assigning variables.
- The `%NodeName` shorthand finds child nodes marked as unique in the scene.
- `preload()` loads a script resource before runtime.
- `RefCounted` is useful for plain logic objects that do not need to be scene nodes.
- `project.godot` can set a main scene with `run/main_scene`.
- Modern Godot versions may create `.gd.uid` sidecar files for scripts; keep them with the script files when they appear.

Game architecture concepts introduced:

- UI and combat rules are separated.
- The UI asks the simulator for a log; it does not decide combat outcomes.
- The simulator advances a discrete-event clock instead of using frame time.
- Deterministic tie-breaking makes repeated runs produce the same result.
- Hardcoded data is acceptable in Phase 1 because Phase 2 will move unit definitions into data.

Files touched:

- `clockwork-company/scenes/combat_test_scene.tscn`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scripts/ui/combat_test_scene.gd.uid`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd.uid`
- `clockwork-company/project.godot`
- `ARCHITECTURE.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why combat code should not live inside the button script.
- How the simulator chooses the next unit to act.
- How frontmost targeting works in this first version.
- Why the same fight produces the same log every time.
- What each Phase 1 file owns.

Manual exercise:

- In `combat_simulator.gd`, change one unit's `action_interval` by 1 or 2 points, run the scene again, and predict which action log lines should move earlier or later.

Open questions:

- Should ties eventually favor allies, enemies, random seeded order, or a visible speed/tiebreak stat?
- How much roster/order information should the UI show before a fight starts?

## 2026-05-30 - Repository bootstrap

Feature worked on:

- Created project guidance, architecture notes, roadmap, design notes, and a minimal Godot-friendly folder structure.

Godot concepts introduced:

- `project.godot` marks the Godot project root.
- `res://` paths are relative to the Godot project root, currently `clockwork-company/`.
- Common Godot project folders include `scenes/`, `scripts/`, and `resources/`.
- `.godot/` is editor-generated cache and should stay out of Git.

Game architecture concepts introduced:

- Separate combat simulation from UI/presentation.
- Separate data definitions from runtime state.
- Use deterministic discrete-event combat so the same starting state and RNG seed can produce the same result.
- Keep documentation close to the code so the project stays teachable.

Files touched:

- `AGENTS.md`
- `ARCHITECTURE.md`
- `LEARNING_LOG.md`
- `ROADMAP.md`
- `DESIGN_NOTES.md`
- `clockwork-company/scenes/.gitkeep`
- `clockwork-company/scripts/.gitkeep`
- `clockwork-company/scripts/combat/.gitkeep`
- `clockwork-company/scripts/data/.gitkeep`
- `clockwork-company/scripts/ui/.gitkeep`
- `clockwork-company/resources/.gitkeep`
- `clockwork-company/resources/units/.gitkeep`
- `clockwork-company/resources/items/.gitkeep`
- `clockwork-company/resources/encounters/.gitkeep`
- `clockwork-company/docs/.gitkeep`

What I should now be able to explain:

- Why the repository root and the Godot project root are different in this checkout.
- What `AGENTS.md` is for.
- What `ARCHITECTURE.md` is for.
- Why learning-first development values small patches, explanations, and manual exercises.
- Why generated Godot editor cache is ignored.

Manual exercise:

- Open the project in Godot, then compare the FileSystem dock with the folders listed above. Identify which folders are for scenes, scripts, data resources, and documentation.

Open questions:

- Should the Godot project folder eventually be renamed or moved so `project.godot` sits at the repository root?
- Should early docs live at the repository root, inside `clockwork-company/docs/`, or both?
