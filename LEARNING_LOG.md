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

## 2026-05-30 - Phase 3 basic gear

Feature worked on:

- Added simple item definitions and equipped demo items that modify combat stats.

Godot concepts introduced:

- A second custom `Resource` type can sit beside `UnitDefinition` to define editable game data.
- `.tres` item files can store exported slot and modifier values in the same data-driven style as units.
- A script can preload both unit Resources and item Resources, then combine them at runtime.

Game architecture concepts introduced:

- `ItemDefinition` is source data: the stable facts about an item before combat starts.
- `UnitState` is still runtime state: it now stores final battle-ready stats after gear modifiers are applied.
- Equipment is currently a fixed demo assignment in the simulator, not an inventory or reward system.
- Gear modifiers are flat and deterministic, so combat remains predictable and readable.

Files touched:

- `clockwork-company/scripts/data/item_definition.gd`
- `clockwork-company/resources/items/reinforced_buckler.tres`
- `clockwork-company/resources/items/shortblade.tres`
- `clockwork-company/resources/items/light_step_boots.tres`
- `clockwork-company/resources/items/glass_focus.tres`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scenes/combat_test_scene.tscn`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why item definitions are data Resources instead of hardcoded stat changes inside attack logic.
- Why final combat stats belong to `UnitState`.
- How one equipped item changes max HP, damage, armor, or action interval before the first action is scheduled.
- How changing an item `.tres` file can alter the combat log without rewriting the simulator rules.

Manual exercise:

- Open `clockwork-company/resources/items/light_step_boots.tres`, change `action_interval_modifier` from `-2` to `0`, run the combat scene, and predict which Mira Scout log lines move later.

Open questions:

- Should equipment assignments eventually live on unit definitions, party definitions, or a separate encounter/loadout definition?

## 2026-05-30 - Phase 2 data-driven units

Feature worked on:

- Moved the demo unit definitions out of the combat simulator and into Godot Resource files.

Godot concepts introduced:

- `Resource` scripts can define editable data types that are not scene nodes.
- `@export` makes a script property visible/editable in the Godot Inspector.
- `@export_enum` constrains a string property to a small set of choices in the Inspector.
- `.tres` files are text Resource assets that can store exported property values.
- `preload()` can load Resource files as well as scripts.

Game architecture concepts introduced:

- `UnitDefinition` is source data: the stable facts about a demo unit before combat starts.
- `UnitState` is runtime state: this specific combat copy, with current HP and next action time.
- The simulator still owns combat rules, but no longer owns the unit stat table directly.
- The current roster is still fixed; only the unit facts moved into data.

Files touched:

- `clockwork-company/scripts/data/unit_definition.gd`
- `clockwork-company/resources/units/alden_guard.tres`
- `clockwork-company/resources/units/mira_scout.tres`
- `clockwork-company/resources/units/sol_apprentice.tres`
- `clockwork-company/resources/units/iron_brute.tres`
- `clockwork-company/resources/units/ash_cutpurse.tres`
- `clockwork-company/resources/units/glass_wisp.tres`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scenes/combat_test_scene.tscn`
- `ARCHITECTURE.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why unit definitions live outside the simulator.
- Why current HP belongs to `UnitState`, not `UnitDefinition`.
- How a `.tres` unit file connects to `unit_definition.gd`.
- Why the combat result stays deterministic even though unit data moved.

Manual exercise:

- Open `clockwork-company/resources/units/mira_scout.tres`, change `action_interval` from `8` to `7`, run the combat scene, and predict which Mira log lines move earlier.

Open questions:

- Should team membership remain on each unit definition, or should a later encounter/party definition decide which side a unit fights for?

## 2026-05-30 - GDScript syntax comments in combat simulator

Feature worked on:

- Added teaching comments to the combat simulator explaining each first use of important GDScript syntax.

Godot concepts introduced:

- `extends`, `class_name`, `RefCounted`, typed variables, typed arrays, typed function parameters, return types, dictionaries, arrays, inner classes, constructor `_init`, and common control-flow syntax.

Game architecture concepts introduced:

- No combat responsibilities changed. The comments reinforce that `UnitState` is runtime combat state and the simulator owns deterministic combat rules.

Files touched:

- `clockwork-company/scripts/combat/combat_simulator.gd`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How to read the first few lines of a Godot script.
- Why `UnitState` is a helper class inside the simulator.
- How arrays and dictionaries are used for the hardcoded demo units.
- How loops, conditions, early returns, and tie-breaking work in this combat file.

Manual exercise:

- Read `run_demo_battle()` from top to bottom and point to the line where combat time advances to the next actor's scheduled action.

Open questions:

- Which syntax still feels mysterious after reading the comments?

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
