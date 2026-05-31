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

## 2026-05-31 - Godot headless check sandbox note

Feature worked on:

- Documented the Codex-safe Godot command-line check for `combat_test_scene.gd`.
- Explained why `--log-file godot-check.log` avoids the signal 11 crash seen before diagnostics.

Godot concepts introduced:

- `--check-only` parses a script for errors without running the full scene.
- `--log-file` redirects Godot's output log away from the default `user://logs` location.
- `user://` points to Godot's per-user data location, which is not necessarily inside the project folder.

Game architecture concepts introduced:

- None. This was a tooling and workflow documentation change.

Files touched:

- `AGENTS.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why Codex's workspace-write sandbox can block Godot from creating its normal user log directory.
- Why that blocked startup write can crash Godot 4.6 stable on Windows before script diagnostics appear.
- Why writing `godot-check.log` inside the project makes the headless check usable from Codex.

Manual exercise:

- Run the documented `--check-only` command with `--log-file godot-check.log`, confirm it exits cleanly, then delete `clockwork-company/godot-check.log`.

Open questions:

- Should we add a tiny script or PowerShell helper later so the check command is easier to run consistently?

## 2026-05-31 - Interstitial Phase 6.5 live combat log replay

Feature worked on:

- Changed the combat test UI so the simulator still generates the full deterministic log immediately, but the visible combat events reveal one parent action per second.
- Replaced the plain `TextEdit` log display with a `RichTextLabel` so future keyword coloration can be added in one UI helper.
- Split the visible log into static combat conditions and live combat replay panes.
- Updated the combat test scene so static combat conditions appear on open, while the run button starts only the combat replay.
- Changed the visible log panes to a top/bottom split and resized the game window to roughly three quarters of the usable screen area on launch.
- Added default project window dimensions for a larger initial game window.

Godot concepts introduced:

- `RichTextLabel` displays read-only rich text and can parse BBCode-like markup.
- `Timer` emits `timeout` at a fixed interval, which is useful for UI presentation pacing.
- `VSplitContainer` can stack two related UI sections while letting one section receive most of the remaining space.
- `DisplayServer` can inspect the usable screen area and set the game window size and position at runtime.
- A `RichTextLabel` exposes a vertical scrollbar that can be observed to detect manual scrolling.
- A small BBCode escaping helper lets plain log text be appended safely before future color tags are introduced.

Game architecture concepts introduced:

- Presentation timing is separate from combat timing.
- The combat simulator remains deterministic and instant from the UI's point of view.
- The UI can replay an already-produced `Array[String]` without owning combat rules or changing combat outcomes.
- Static setup information can be displayed immediately, while timestamped combat events are replayed separately.

Files touched:

- `clockwork-company/scenes/combat_test_scene.tscn`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why the replay timer belongs to the UI scene instead of the combat simulator.
- Why escaping `[` matters before appending simulator text to a BBCode-enabled `RichTextLabel`.
- How the UI splits the simulator's plain lines into static setup lines and replay event lines.
- How `combat_replay_events` and `replay_event_index` let the UI reveal one parent combat event per second.
- Why `_ready()` now connects signals, sizes the window, and runs a deterministic preview without starting replay.
- Why `_ready()` fills the static conditions pane but does not start replay.
- How `_resize_conditions_pane()` caps the static setup pane at half the available log area.
- Why manual scrolling disables automatic scroll-to-bottom during the current replay.

Manual exercise:

- In `combat_test_scene.gd`, change `SECONDS_BETWEEN_REPLAY_ACTIONS` from `1.0` to `0.25`, run the scene, and explain why combat replay becomes faster without changing the generated combat result.

Open questions:

- Should the next logging pass color whole categories of lines first, or should the simulator eventually return structured log entries with categories?

## 2026-05-31 - Chat handoff guidance

Feature worked on:

- Added repo-level guidance for when an assistant should recommend moving to a clean chat and provide a handoff prompt.

Godot concepts introduced:

- None. This was a collaboration/process documentation change.

Game architecture concepts introduced:

- None. The change supports project continuity, not combat behavior.

Files touched:

- `AGENTS.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why one chat should usually contain work that is relevant as a whole.
- Why a clean chat plus a good handoff prompt can reduce stale assumptions.
- What information a useful handoff prompt should preserve.

Manual exercise:

- At the end of the next focused phase, ask for a handoff prompt and check whether it names the phase, completed work, next goal, files to inspect, non-goals, docs, tests, and the reminder to verify the repo.

Open questions:

- Should future phase wrap-ups include a standard "handoff prompt" section by default, or only when the next task is likely to start in a clean chat?

## 2026-05-30 - Unit loadout Resources

Feature worked on:

- Moved jobs, equipment slots, and tactic assignments out of simulator demo arrays and into editor-editable Resources.

Godot concepts introduced:

- A `UnitLoadoutDefinition` `Resource` can reference other Resources, including jobs, items, and tactic rules.
- A `UnitDefinition` can point to another custom Resource, giving one asset a reusable data dependency.
- Resource arrays can store ordered tactic lists that the simulator reads at runtime.

Game architecture concepts introduced:

- Base unit data and build/loadout data are now separate concepts.
- A loadout is the current archetype layer: it combines a current job, weapon, armor, trinket, and tactics.
- The simulator still owns combat rules, but no longer owns the specific demo jobs, gear, or tactics.
- The fixed 3v3 roster remains in code for now; encounter/party composition can become a Resource later.

Files touched:

- `clockwork-company/scripts/data/unit_definition.gd`
- `clockwork-company/scripts/data/unit_loadout_definition.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/resources/units/*.tres`
- `clockwork-company/resources/loadouts/*.tres`
- `clockwork-company/resources/tactics/*.tres`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why `UnitDefinition` and `UnitLoadoutDefinition` are separate Resources.
- How a loadout can be reused by multiple units with different base stats.
- How weapon, armor, and trinket permissions are checked one item at a time.
- Why tactics can now be edited as `.tres` assets instead of being created in simulator code.

Manual exercise:

- Open `clockwork-company/resources/units/sol_apprentice.tres`, change its `loadout` to `res://resources/loadouts/scout_shortblade.tres`, run combat, and explain which stats, equipment permissions, tactics, and job effect changed.

Open questions:

- Should the fixed 3v3 roster move into a `CombatScenarioDefinition` or `EncounterDefinition` next?
- Should loadouts stay on units permanently, or should a later party editor assign loadouts separately from unit definitions?

## 2026-05-30 - Phase 6 basic jobs

Feature worked on:

- Added basic jobs so current job identity can shape stats, equipment permissions, and one small job effect.

Godot concepts introduced:

- A `JobDefinition` `Resource` uses exported integers, booleans, and an `@export_enum` job-effect label.
- `.tres` job Resources make current-job data inspectable in Godot beside unit, item, and tactic data.
- Multiple Resource definitions can be combined into one runtime combat object without rewriting the source Resources.

Game architecture concepts introduced:

- Jobs are source data, while current job assignment and job effects are copied into `UnitState` for one battle.
- Job stat modifiers affect runtime stats after unit data is copied and before allowed item modifiers are applied.
- Job equipment permissions filter demo gear; skipped gear is logged and does not apply modifiers or triggers.
- A current job effect can change combat behavior without changing the unit's base stats.

Files touched:

- `clockwork-company/scripts/data/job_definition.gd`
- `clockwork-company/resources/jobs/guard.tres`
- `clockwork-company/resources/jobs/scout.tres`
- `clockwork-company/resources/jobs/apprentice.tres`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/resources/items/glass_focus.tres`
- `clockwork-company/scenes/combat_test_scene.tscn`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why `JobDefinition` is data and `UnitState` is the battle copy that actually changes.
- How job stat modifiers, item modifiers, and battle-start effects happen in order.
- Why equipment permissions should skip an item before its stats or triggers apply.
- How a current job effect such as `First Aid` or `Sharpened Edge` changes combat behavior.

Manual exercise:

- In `clockwork-company/resources/jobs/apprentice.tres`, temporarily set `can_equip_trinket` to `false`, run the fight, and explain why Sol's Glass Focus no longer changes stats or triggers on attack.

Open questions:

- Should learned effects eventually come from a unit career/progression Resource once jobs stop acting like simple classes?
- Should equipment permissions live only on jobs, or should future items have additional unit-specific requirements?

## 2026-05-30 - Armor reduction and temporary guard armor

Feature worked on:

- Clarified how Shortblade-style armor reduction interacts with guard's temporary armor.

Godot concepts introduced:

- A small helper method on an inner class can expose derived runtime values such as total armor.

Game architecture concepts introduced:

- Base battle armor and temporary guard armor are now separate pieces of runtime state.
- Damage uses total armor, but armor reduction changes base armor first.
- If base armor is already zero, armor reduction can reduce temporary guard armor.

Files touched:

- `clockwork-company/scripts/combat/combat_simulator.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why temporary armor should not be mixed into the same field as base armor.
- Why damage calculation wants total armor, while armor-reduction effects need to know the armor source.
- How the Shortblade rule behaves against 0 base armor plus temporary armor versus 1 base armor plus temporary armor.

Manual exercise:

- In `combat_simulator.gd`, find `_reduce_target_armor()` and trace what happens when the target has `armor = 0` and `guard_armor = 2`.

Open questions:

- Should future armor buffs identify whether they add base battle armor, temporary armor, or a named status?

## 2026-05-30 - Phase 5 basic tactics

Feature worked on:

- Added priority-ordered tactics so units can choose attack, heal, or guard from small readable rules.

Godot concepts introduced:

- A new `TacticDefinition` `Resource` uses `@export_enum` to constrain condition, action, and target choices.
- Resource objects can be created in code with `.new()` for temporary demo data before `.tres` files are worth adding.
- Typed arrays can hold custom Resource types such as `Array[TacticDefinition]`.

Game architecture concepts introduced:

- Tactics are source rule data, while `UnitState` keeps the runtime list assigned to a combat copy.
- The simulator evaluates tactics in priority order on each turn.
- Conditions, target rules, and action resolution are separate helper steps so the combat log can explain the decision.
- Guard is runtime-only temporary armor and is cleared at the start of that unit's next turn.

Files touched:

- `clockwork-company/scripts/data/tactic_definition.gd`
- `clockwork-company/scripts/data/tactic_definition.gd.uid`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scenes/combat_test_scene.tscn`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How a `condition -> action -> target` tactic becomes a concrete combat action.
- Why tactics are evaluated in order instead of all at once.
- Why healing and guarding modify `UnitState`, not unit or tactic Resources.
- How parent/child log entries show the turn, selected tactic, action, and triggered item effects.

Manual exercise:

- In `combat_simulator.gd`, change Mira Scout's first tactic from `Ally HP Below Half -> Heal -> Lowest HP Ally` to `Always -> Heal -> Lowest HP Ally`, run the fight, and explain why that can make her stop attacking.

Open questions:

- Should tactics eventually live on unit, party, loadout, or encounter Resources?
- Should "Lowest HP Ally" mean lowest raw HP, lowest HP percentage, or most missing HP?
- Should guard remain temporary armor, or become a named status once status effects exist?

## 2026-05-30 - Structured combat log entries

Feature worked on:

- Reworked combat logging from a flat string list into small parent/child log entries that render back to readable text.

Godot concepts introduced:

- Inner helper classes can model plain data structures without becoming scene nodes.
- A function can keep returning `Array[String]` to the UI while using a richer internal representation.
- Integer IDs are enough for temporary runtime relationships when the data only lives for one battle log.

Game architecture concepts introduced:

- `CombatLogEntry` stores one log entry's invisible ID, optional parent ID, optional time, text, and children.
- `CombatLog` owns ID assignment, parent/child relationships, and rendering to plain text lines.
- Parent log entries describe major combat moments, while child entries explain triggered effects and outcomes inside that moment.
- The UI remains decoupled from combat-log structure because it still receives plain strings.

Files touched:

- `clockwork-company/scripts/combat/combat_simulator.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why triggered effects made a flat log harder to read.
- How an invisible log entry ID lets one line become the parent of later explanation lines.
- Why child entries do not need their own visible timestamp.
- Why the simulator can use structured log data internally while the UI still displays simple text.

Manual exercise:

- In `combat_simulator.gd`, find where `attack_entry_id` is created, then point to the child log lines that attach damage and triggered effects to that same parent attack.

Open questions:

- Should battle-start item effects eventually become children of a single timed `t=000` battle-start parent?
- Should a later UI display structured log entries as collapsible groups instead of plain indented text?

## 2026-05-30 - Phase 4 triggered item effects

Feature worked on:

- Added simple item trigger/effect data and combat resolution hooks for triggered item effects.

Godot concepts introduced:

- `@export_enum` can constrain designer-facing Resource fields to a small set of readable string choices.
- Existing `.tres` item Resources can gain new exported fields while keeping their previous stat modifier data.
- A Resource can describe what an item is allowed to do, while a plain script object applies that data during runtime.

Game architecture concepts introduced:

- `ItemDefinition` now owns source data for one optional triggered effect: trigger, effect type, and amount.
- `CombatSimulator` owns when triggers fire and how each narrow effect resolves.
- `UnitState` owns mutable combat stats such as HP and armor, so triggered effects never rewrite source `.tres` definitions.
- Trigger hooks are intentionally small so Phase 4 creates build identity without becoming a full ability system.

Files touched:

- `clockwork-company/scripts/data/item_definition.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/resources/items/reinforced_buckler.tres`
- `clockwork-company/resources/items/glass_focus.tres`
- `clockwork-company/resources/items/shortblade.tres`
- `clockwork-company/scenes/combat_test_scene.tscn`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why trigger and effect choices live on `ItemDefinition`.
- Why battle-start armor and hit-based armor reduction change `UnitState` instead of `.tres` files.
- Where the simulator checks each trigger moment: battle start, attack, hit, kill, and death.
- How a triggered item effect changes the combat log and the later combat result.

Manual exercise:

- Open `clockwork-company/resources/items/glass_focus.tres`, change `effect_amount` from `2` to `0`, run the combat scene, and predict how Sol Apprentice's attack log lines and damage totals change.

Open questions:

- Should future effects be represented as separate effect Resources once one effect per item becomes too limiting?
- Should hit effects trigger only when damage is greater than 0 if future armor rules ever allow fully blocked attacks?

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
