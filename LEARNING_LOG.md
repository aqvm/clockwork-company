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

## 2026-06-02 - Ancestries, helmets, and legacy damage cleanup

Feature worked on:

- Added `AncestryDefinition` and `AncestryFeatureDefinition` Resources.
- Added always-on ancestry feature resolution for battle-start, attack, damaged/low-HP, and kill hooks.
- Added a helmet equipment slot to loadouts, runtime equipment checks, run equipment replacement, and JSON content.
- Removed the old single `damage` / `damage_modifier` data path in favor of explicit physical and magic damage fields.
- Added seven ancestry Resources: Minotaur, Redcap, Typhon-born, Stonekin, Emberkin, Hollow, and Brassbound.
- Added five helmet items and assigned ancestry references across the existing unit catalog.

Godot concepts introduced:

- Custom `Resource` scripts can reference other custom Resources, such as a `UnitDefinition` exporting an `AncestryDefinition`.
- `.tres` files can embed subresources, which is how ancestry features live inside ancestry Resources.
- Exported enum strings make the Godot inspector constrain authoring choices without needing editor plugins.

Game architecture concepts introduced:

- Ancestry is now the always-on body/origin layer, while jobs remain the trained-role layer.
- Ancestry baseline growth stacks with job-specific growth when a unit has job levels.
- Helmet equipment is a normal loadout slot; shields are still represented as bundled weapon/armor concepts.

Files touched:

- `clockwork-company/scripts/data/ancestry_definition.gd`
- `clockwork-company/scripts/data/ancestry_feature_definition.gd`
- `clockwork-company/scripts/combat/rules/ancestry_feature_resolver.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/run/run_state.gd`
- `clockwork-company/modding/reference/base_content.options.md`
- `clockwork-company/resources/ancestries/typhon_born.tres`

What I should now be able to explain:

- Why ancestry features are separate from job passives/reactions.
- Why units still have explicit stats even though ancestries now define stat ranges.
- Why the old single `damage` field was removed instead of kept as compatibility glue.

Manual exercise:

- Open `clockwork-company/resources/ancestries/typhon_born.tres` and explain why its notes describe two helmets even though the current implemented feature is battle-start armor.

Open questions:

- Should ancestry features eventually be equipped/locked like job features, or should they always remain immutable?
- When slot capacity is added, should Typhon-born's second helmet be its whole feature or one part of a broader many-headed identity?

## 2026-06-02 - Job leveling and physical/magic damage split

Feature worked on:

- Added per-unit, per-job progress with XP, levels, unlock flags, and future choice scaffolding.
- Added a five-total-job-level cap per unit.
- Added per-level job growth fields for HP, physical damage, magic damage, armor, and action interval.
- Changed runtime combat stats from one damage number to physical and magic damage.
- Updated combat damage resolution so `magic`-tagged damage sources use magic damage; other damage sources use physical damage.
- Added run-loop job XP awards after won fights: each ally gains current-job XP, and one XP currently becomes one job level.

Godot concepts introduced:

- `JobProgressDefinition` is a small Resource used as an inspectable record inside a unit.
- Removing compatibility fields can be cleaner than preserving them when the project is still early and the old model obscures the new rules.
- Resource arrays are useful for editor-visible lists of structured records, such as one unit's job history.

Game architecture concepts introduced:

- Current job, learned abilities, and job history are now separate concepts.
- Permanent stat growth is computed from job progress at combat-state creation time.
- Predetermined unlock tracks are represented with booleans now, while `pending_unlock_choice` leaves a place for future choice UI.
- Physical damage is reduced by armor; magic damage currently ignores armor because no magic-resistance stat exists yet.

Files touched:

- `clockwork-company/scripts/data/job_progress_definition.gd`
- `clockwork-company/scripts/data/unit_definition.gd`
- `clockwork-company/scripts/data/item_definition.gd`
- `clockwork-company/scripts/data/job_definition.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/combat/rules/item_effect_resolver.gd`
- `clockwork-company/scripts/combat/logging/combat_text_formatter.gd`
- `clockwork-company/scripts/modding/json_content_loader.gd`
- `clockwork-company/scripts/run/run_state.gd`
- `clockwork-company/resources/jobs/*.tres`
- `clockwork-company/resources/units/*.tres`
- `clockwork-company/resources/items/*.tres`
- `clockwork-company/modding/reference/base_content.json`
- `clockwork-company/modding/reference/base_content.options.md`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `MODDING.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why job levels are per unit/per job rather than a single global unit level.
- Why `action_interval_growth = -1` means a job makes the unit faster.
- Why a skill or effect with the `magic` tag uses magic damage.
- Why `pending_unlock_choice` exists even though unlocks are automatic right now.

Manual exercise:

- Win one run fight, inspect the run status text, and confirm each ally gained one level in their current job. Then predict which stat growth should apply to that ally's next fight.

Open questions:

- Should job XP eventually depend on survival, actions taken, or fight participation instead of awarding all allies after a win?
- Should magic eventually have a separate resistance/ward stat, or should armor remain the only defense for a while?
- Should unlock choice happen immediately on level-up, between fights, or in a dedicated career screen later?

## 2026-06-02 - Learned ability loadout slots

Feature worked on:

- Added optional equipped skill, passive, and reaction slots to `UnitLoadoutDefinition`.
- Updated combat runtime so a loadout can override the current job's granted skill/passive/reaction.
- Added `Roger Spellsword` and `Cast Sparkblade` as a small authored example of current-job frame plus learned ability overrides.
- Updated JSON loading, run-state cloning, and docs for the new loadout ability fields.
- Synced ability `display_name` values into `resource_name` so the Godot Inspector can show useful names for equipped skill/passive/reaction Resources.

Godot concepts introduced:

- A Resource can hold optional typed references that act as overrides only when assigned.
- A `.tres` loadout can contain inline subresources for learned abilities without needing a separate global ability file yet.
- `resource_name` is the editor-facing Resource label; syncing it from `display_name` makes nested Resources easier to read in the Inspector.

Game architecture concepts introduced:

- Current job and learned abilities are now separate ideas in the data model.
- Loadouts are the first build-level place where a unit biography can be assembled.
- The current implementation still avoids progression UI: it directly authors the equipped ability combination for testing.

Files touched:

- `clockwork-company/scripts/data/unit_loadout_definition.gd`
- `clockwork-company/scripts/data/skill_definition.gd`
- `clockwork-company/scripts/data/passive_definition.gd`
- `clockwork-company/scripts/data/reaction_definition.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/modding/json_content_loader.gd`
- `clockwork-company/scripts/run/run_state.gd`
- `clockwork-company/resources/loadouts/roger_spellsword.tres`
- `clockwork-company/resources/tactics/cast_sparkblade.tres`
- `clockwork-company/resources/units/roger_spellsword.tres`
- `clockwork-company/modding/reference/base_content.options.md`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `MODDING.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How a loadout can equip a skill/passive/reaction that differs from the current job.
- Why the current job still provides fallback abilities when the loadout override slots are empty.
- Why a hybrid loadout should usually author an explicit `Job Skill` tactic with a target that fits the equipped skill.
- Why file-backed tactic Resources fit the current JSON bridge better than inline tactic subresources inside loadouts.
- Why `resource_name` and `display_name` are related but not the same thing.

Manual exercise:

- Open `clockwork-company/resources/loadouts/roger_spellsword.tres` and identify which parts come from the current Guard job versus which parts are equipped learned ability overrides.

Open questions:

- Should learned abilities eventually be referenced by id from a global ability library, or remain embedded in jobs/loadouts as subresources?
- Should loadouts allow multiple learned skills with tactics choosing among them, or keep one equipped skill for now?

## 2026-06-01 - FFT-shaped job ability foundation

Feature worked on:

- Moved jobs from mostly stat/proficiency packages toward a skill/passive/reaction model.
- Added `SkillDefinition`, `PassiveDefinition`, and `ReactionDefinition` Resources.
- Updated jobs so each current job grants one skill, one passive, one reaction, and one appended default tactic.
- Changed equipment rules so weapon/armor/trinket slots are allowed by default, with optional `forbid_weapon`, `forbid_armor`, and `forbid_trinket` flags for special jobs.
- Added passive and reaction cooldown tracking as combat-only unit-turn counters.

Godot concepts introduced:

- A Resource can contain other Resource subresources, which keeps a job inspectable while still making it richer than a few strings.
- Exported Resource references such as `skill: SkillDefinition` give the Inspector a typed authoring slot.
- JSON mod data can mirror nested Resource data by converting dictionaries into Resource objects at load time.

Game architecture concepts introduced:

- Jobs can grant active, passive, and reaction vocabulary without owning simulator code.
- `Job Skill` is a tactic action that asks the simulator to resolve the current job's active skill.
- Passives and reactions are runtime effects on `UnitState`; they do not mutate source job or unit Resources.
- Cooldowns live in runtime state, not in the data Resources, because cooldowns are per combat copy.
- Equipment forbids are now exceptions, not the central identity of a job.

Files touched:

- `clockwork-company/scripts/data/skill_definition.gd`
- `clockwork-company/scripts/data/passive_definition.gd`
- `clockwork-company/scripts/data/reaction_definition.gd`
- `clockwork-company/scripts/data/job_definition.gd`
- `clockwork-company/scripts/data/tactic_definition.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/combat/rules/job_effect_resolver.gd`
- `clockwork-company/scripts/combat/combat_constants.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/modding/json_content_loader.gd`
- `clockwork-company/scripts/run/run_state.gd`
- `clockwork-company/resources/jobs/*.tres`
- `clockwork-company/modding/reference/base_content.json`
- `clockwork-company/modding/reference/base_content.options.md`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `MODDING.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why a job skill is different from a tactic: the skill defines what can be done, while the tactic defines when and who to target.
- Why a job's default tactic is appended after loadout tactics, so explicit loadout behavior can override the generic job behavior.
- Why passive/reaction cooldown counters belong on `UnitState`.
- Why forbidding equipment is now a special job rule instead of the default way jobs are differentiated.

Manual exercise:

- Open `clockwork-company/resources/jobs/debt_knight.tres`, inspect its skill, passive, reaction, and default tactic subresources, then predict how `Payment Due` behaves when the unit drops below half HP after being attacked.

Open questions:

- Should learned/equipped skill/passive/reaction slots live on `UnitLoadoutDefinition`, a future progression Resource, or a separate unit-history Resource?
- Should cooldowns count owner turns, global actions, or simulation ticks once more timing systems exist?

## 2026-06-01 - Phase 8 content catalog slice

Feature worked on:

- Added a broad first content catalog slice for future run-loop/reward pulls: 32 items, 12 jobs, 9 named tactics, 18 loadouts, 18 units, 3 optional catalog encounters, and 3 optional catalog rewards.
- Added `display_name` to `TacticDefinition` so tactics can be recognizable in setup and combat logs.
- Kept the new catalog declarative and did not wire it into the current five-fight run.

Godot concepts introduced:

- `.tres` Resources can reference other Resources to form inspectable content graphs: units point to loadouts, loadouts point to jobs/items/tactics, and encounters/rewards point back to normal units/items.
- Exported fields added to a Resource script become editable fields in the Inspector and can be mirrored through JSON mod loading.

Game architecture concepts introduced:

- A content library can be larger than the active run loop as long as the active selector stays explicit.
- Tags are useful authoring vocabulary for future filters and for current item conditions such as `Target Has Tag`.
- Content expansion is safest when it stays inside currently implemented simulator behavior instead of relying on reserved effect combinations.

Files touched:

- `clockwork-company/scripts/data/tactic_definition.gd`
- `clockwork-company/scripts/combat/logging/combat_text_formatter.gd`
- `clockwork-company/scripts/combat/rules/tactic_resolver.gd`
- `clockwork-company/scripts/modding/json_content_loader.gd`
- `clockwork-company/resources/items/*.tres`
- `clockwork-company/resources/jobs/*.tres`
- `clockwork-company/resources/tactics/*.tres`
- `clockwork-company/resources/loadouts/*.tres`
- `clockwork-company/resources/units/*.tres`
- `clockwork-company/resources/encounters/catalog_test_*.tres`
- `clockwork-company/resources/rewards/catalog_reward_*.tres`
- `clockwork-company/modding/reference/base_content.json`
- `clockwork-company/modding/reference/base_content.options.md`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `MODDING.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How an item effect stays declarative even when it has trigger, condition, target, and amount fields.
- Why a loadout is the reusable build package between a unit body and combat runtime state.
- Why the catalog can contain enemy builds without creating enemy-only mechanics.
- Why tactic display names improve authoring without changing tactic logic.

Manual exercise:

- Open `clockwork-company/resources/loadouts/debt_knight_tollhook.tres`, follow each Resource reference in the Inspector, and predict which item effects should appear if that build fights an `armored` target.

Open questions:

- Which catalog units should become player recruit candidates versus enemy-only encounter examples later?
- Should the next content pass add new tactic conditions/actions, or should balance exploration happen first using the current small tactic grammar?

## 2026-06-01 - Phase 8-ish Godot verification cleanup

Feature worked on:

- Ran the required headless Godot script check after the Phase 7/8 handoff.
- Fixed compile errors caused by a missing script UID for the new effect Resource and a few ambiguous inferred locals.

Godot concepts introduced:

- Custom `class_name` Resource scripts need their `.gd.uid` sidecar kept with the script so Godot can reliably resolve typed exported properties.
- `:=` asks Godot to infer a type; when a helper returns an untyped value, an explicit `var name: String` or plain `var encounter = ...` can be clearer and compile reliably.

Game architecture concepts introduced:

- The item-effect authoring model should keep a strict `Array[EffectDefinition]` boundary so the Inspector prevents authors from putting the wrong Resource type into an item effect list.
- Parser fixes should avoid changing combat behavior when the failure is at the type-boundary level.

Files touched:

- `clockwork-company/scripts/data/item_definition.gd`
- `clockwork-company/scripts/data/effect_definition.gd.uid`
- `clockwork-company/scripts/modding/json_content_loader.gd`
- `clockwork-company/scripts/combat/rules/item_effect_resolver.gd`
- `clockwork-company/scripts/run/run_state.gd`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why `ItemDefinition.effects` should be typed as `Array[EffectDefinition]` for safer authoring.
- Why the JSON loader still creates `EffectDefinitionScript.new()` objects.
- Why Godot sometimes needs explicit local typing instead of relying on `:=`.

Manual exercise:

- Open `run_focus_lens.tres` or another item with authored effects and confirm the Inspector only accepts `EffectDefinition` subresources under the `effects` array.

Open questions:

- Should any future effect-like data types share a base Resource class, or should item effects stay pinned directly to `EffectDefinition`?

## 2026-06-01 - Phase 7 short run-loop kickoff

Feature worked on:

- Added a tiny five-fight roguelite run loop on top of the existing deterministic combat simulator.
- Added reward buttons between fights that immediately equip a selected reward item onto a named ally.
- Added visible run terminal states: normal five-fight win and a `Start Loss Test` path for checking loss.

Godot concepts introduced:

- A `RefCounted` model (`RunState`) can hold non-visual game flow state outside the scene tree.
- UI buttons can be created dynamically from script and connected with `pressed.connect(...)`.
- Resource instances can be cloned at runtime so run rewards can mutate this run's party without rewriting source `.tres` files.

Game architecture concepts introduced:

- Run flow is separate from combat rules: `RunState` decides which roster to fight and what reward was applied, while `CombatSimulator` still decides how a battle resolves.
- A battle report can include machine-readable summary fields like `winner` and `actions_taken` without changing the human-readable combat log.
- A first inventory/equipment slice can be button-driven and immediate while still preserving the later option to build a fuller equipment screen.

Files touched:

- `clockwork-company/scripts/run/run_state.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/combat/scenarios/demo_battle_factory.gd`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why `RunState` owns fight index, reward state, and cloned party definitions instead of putting those rules inside `CombatSimulator`.
- Why rewards clone and replace runtime loadout items rather than editing the original `.tres` Resources.
- How the UI knows whether to show `Run Fight`, reward choices, `Run Won`, or `Run Lost`.
- Why the loss-test button is useful while the normal run path is tuned to be winnable.

Manual exercise:

- Change one reward in `run_state.gd` by 1 stat point, then predict which later fight roster summary line should change before pressing Play.

Open questions:

- Should the next run-loop pass add a true inventory screen, or first add authored encounter definitions as Resources?
- Should rewards eventually be random from a seeded table, fixed by fight number, or selected from encounter-specific pools?

## 2026-06-01 - Phase 7.1 data-driven encounters

Feature worked on:

- Added an `EncounterDefinition` Resource for authored enemy-party fights.
- Added five Phase 7 encounter `.tres` files.
- Added a small set of enemy unit variants that still use normal unit/loadout/job/item/tactic building blocks.
- Updated `RunState` to load the fixed encounter sequence instead of scaling cloned demo enemies in code.

Godot concepts introduced:

- Resource arrays can reference other Resources, such as an encounter pointing to multiple unit definitions.
- New data Resources can unlock content authoring without adding new combat rules.

Game architecture concepts introduced:

- Encounters are opposing party compositions, not bespoke monster scripts.
- This keeps the eventual async-multiplayer path cleaner because enemies and players remain expressible through the same build vocabulary.

Files touched:

- `clockwork-company/scripts/data/encounter_definition.gd`
- `clockwork-company/scripts/run/run_state.gd`
- `clockwork-company/resources/encounters/*.tres`
- `clockwork-company/resources/units/training_brute.tres`
- `clockwork-company/resources/units/lane_knifer.tres`
- `clockwork-company/resources/units/backroom_mender.tres`
- `clockwork-company/resources/units/union_shield.tres`
- `clockwork-company/resources/units/roofline_duelist.tres`
- `clockwork-company/resources/units/glass_adept.tres`
- `clockwork-company/resources/units/vault_bulwark.tres`
- `clockwork-company/resources/units/clockwork_runner.tres`
- `clockwork-company/resources/units/mercy_engine.tres`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why an encounter is an array of enemy `UnitDefinition` Resources.
- Why enemy variants should use the same jobs, items, loadouts, and tactics as player units.
- Why `RunState` still owns the fixed encounter order while each encounter owns its enemy party content.

Manual exercise:

- Open one `phase7_fight_*.tres` encounter and swap one enemy reference for another enemy `UnitDefinition`, then predict how the fight setup summary should change.

Open questions:

- Should encounter order eventually live in a `RunDefinition` Resource instead of a constant list in `RunState`?
- Should encounter Resources later own reward pools, scout notes, and difficulty labels?

## 2026-06-01 - Phase 7.2 data-driven rewards

Feature worked on:

- Added a `RewardDefinition` Resource for run reward offers.
- Added three reward item Resources.
- Added three reward Resources for Alden, Mira, and Sol.
- Updated `RunState` to load reward choices from `.tres` files instead of hardcoded stat dictionaries.

Godot concepts introduced:

- A Resource can reference another Resource as its payload.
- Content files can separate an offer (`RewardDefinition`) from the item it grants (`ItemDefinition`).

Game architecture concepts introduced:

- Rewards now produce normal items, which keeps build rewards aligned with the same equipment system used by loadouts.
- Immediate equip is still a temporary run-loop shortcut; the next step is a small inventory/equipment UI that can hold these item rewards before equipping.

Files touched:

- `clockwork-company/scripts/data/reward_definition.gd`
- `clockwork-company/scripts/run/run_state.gd`
- `clockwork-company/resources/items/run_guardplate.tres`
- `clockwork-company/resources/items/run_honed_blade.tres`
- `clockwork-company/resources/items/run_focus_lens.tres`
- `clockwork-company/resources/rewards/guardplate_for_alden.tres`
- `clockwork-company/resources/rewards/honed_blade_for_mira.tres`
- `clockwork-company/resources/rewards/focus_lens_for_sol.tres`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why a reward references an item Resource instead of duplicating item stat fields.
- Why the reward still has a suggested target unit while the item itself stays target-agnostic.
- Why cloning the item before equipping prevents the run from mutating the source `.tres` item.

Manual exercise:

- Open `run_honed_blade.tres`, change its damage modifier by 1, then predict which setup line should change after picking Honed Blade.

Open questions:

- Should reward offers later be encounter-specific, generated from a pool, or fixed by run position?
- Should rewards target a suggested unit, or should the player always choose the recipient from inventory?

## 2026-06-01 - Phase 7.3 minimal inventory/equipment decisions

Feature worked on:

- Added a between-fight `equipment` run state.
- Changed reward choice so it adds the reward item to inventory instead of immediately equipping it.
- Added valid equip-option generation based on each ally's current job permissions.
- Added dynamic equipment buttons and a `Continue to Next Fight` button to the combat test scene.
- Returning replaced gear to inventory prevents silent item loss.

Godot concepts introduced:

- Dynamic UI can mirror game state without requiring a new scene file for every prototype screen.
- Resource references can move through runtime inventory and equipment slots as normal objects.

Game architecture concepts introduced:

- Inventory is run state, not combat state.
- Equipment permission checks can be shared conceptually with combat setup so the player cannot equip illegal gear between fights.
- A crude button list is enough to validate the loop before building a polished party management screen.

Files touched:

- `clockwork-company/scripts/run/run_state.gd`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why reward choice and equipment choice are separate states.
- Why replaced items return to inventory.
- Why the UI asks `RunState` for valid equip options instead of deciding equipment legality itself.

Manual exercise:

- Pick a reward after fight 1, equip it on the suggested unit, then equip the returned old item somewhere legal if an option appears. Predict which unit's setup stats should change.

Open questions:

- Should the inventory eventually become a dedicated scene/panel instead of temporary buttons in the combat test scene?
- Should equipment changes be reversible with an explicit undo, or is returned-to-inventory enough for now?

## 2026-06-01 - Phase 8-ish declarative item effect foundation

Feature worked on:

- Added `EffectDefinition` as a declarative effect Resource.
- Added freeform `tags` to units, items, jobs, tactics, and effects.
- Added `effects: Array[EffectDefinition]` to items while keeping legacy `trigger/effect/effect_amount` fallback fields.
- Updated item effect resolution to read authored effect Resources for current supported item triggers.
- Added damaged/low-HP effect handling for item effects such as once-per-battle max HP increases.
- Added `Stubborn Heart Charm` as an authoring example for low-HP max HP growth.
- Updated the JSON/modding bridge and schema docs for tags and item effects.

Godot concepts introduced:

- Resource arrays can hold typed effect Resources.
- Subresources inside `.tres` files can define item-specific effects without requiring separate files for every effect.
- Exported `Array[String]` fields are a lightweight tag authoring surface.

Game architecture concepts introduced:

- Declarative effects keep content deterministic and inspectable, which is important for eventual async multiplayer.
- The simulator still interprets a known vocabulary; items do not run arbitrary scripts.
- Reserved vocabulary can point toward future systems, but docs must distinguish implemented behavior from future hooks.

Files touched:

- `clockwork-company/scripts/data/effect_definition.gd`
- `clockwork-company/scripts/data/item_definition.gd`
- `clockwork-company/scripts/data/unit_definition.gd`
- `clockwork-company/scripts/data/job_definition.gd`
- `clockwork-company/scripts/data/tactic_definition.gd`
- `clockwork-company/scripts/combat/rules/item_effect_resolver.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/modding/json_content_loader.gd`
- `clockwork-company/resources/items/*.tres`
- `MODDING.md`
- `clockwork-company/modding/reference/base_content.json`
- `clockwork-company/modding/reference/base_content.options.md`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why item effects are now Resources instead of only three flat fields on `ItemDefinition`.
- Why legacy item effect fields still exist during the transition.
- Which effect trigger/type combinations are actually implemented today.
- Why periodic and adjacency effects need scheduler/formation support before they can be honest content tools.

Manual exercise:

- Equip `Stubborn Heart Charm` on a unit that can use trinkets, then predict when its once-per-battle max HP effect should trigger.

Open questions:

- Should the next pass add periodic scheduler hooks or formation/adjacency first?
- Should jobs move from hardcoded job effect labels to `EffectDefinition` arrays next?
- Should actions/skills become Resources that contain effects, so tactics choose authored actions instead of fixed strings?

## 2026-05-31 - Interstitial Phase 6.5.5.5 combat replay visualization effects pass

## 2026-06-01 - Interstitial Phase 6.5.5.5 mod-pack toggle UI pass

Feature worked on:

- Added a dropdown mod menu with checkable entries in the combat test scene.
- Added enable/disable behavior per mod JSON pack before running simulation.
- Added persistence of enabled mod ids to `user://mod_settings.cfg`.
- Updated preview loading so toggling mods immediately refreshes setup/replay source data.
- Threaded enabled-pack filtering from UI -> simulator -> demo battle factory -> JSON content loader.

Godot concepts introduced:

- `MenuButton` + `PopupMenu` check items can serve as a compact multi-select dropdown.
- `ConfigFile` can persist lightweight UI state in `user://`.
- UI can re-run deterministic preview generation safely when content selection changes.

Game architecture concepts introduced:

- Mod selection remains a presentation/config concern; simulator rules stay unchanged.
- Content pipeline selection is explicit input to scenario/unit construction.

Files touched:

- `clockwork-company/scenes/combat_test_scene.tscn`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/combat/scenarios/demo_battle_factory.gd`
- `clockwork-company/scripts/modding/json_content_loader.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How the mod checkbox dropdown maps to an enabled id array used by the content loader.
- Why toggling mods does not require simulator logic changes.
- How persisted mod selection in `user://` affects next launch behavior.

Manual exercise:

- Disable all mods from the dropdown, run once, then enable one mod and run again; compare setup lines and any loadout/stat differences.

Open questions:

- Should the mod list include an explicit `Enable All / Disable All` quick action row?

## 2026-06-01 - Interstitial Phase 6.5.5.5 integration test mod-pack coverage pass

Feature worked on:

- Added a dedicated integration test mod pack JSON that intentionally covers add/override behavior for every major content collection.
- Added sidecar markdown coverage matrix and expected-observation checklist for quick manual verification.
- Added modding guide note pointing to the integration test pack as a regression/debug tool.

Godot concepts introduced:

- None new at API level; this is data-contract and verification coverage content.

Game architecture concepts introduced:

- A single pack can be used as a repeatable wiring test for loader merge paths, id references, and UI mod-toggle behavior.
- Mod validation confidence improves when one pack touches all content layers (items/jobs/tactics/loadouts/units/roster).

Files touched:

- `clockwork-company/modding/reference/integration_test_mod_pack.json`
- `clockwork-company/modding/reference/integration_test_mod_pack.options.md`
- `MODDING.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How this integration pack tests both new-id add and existing-id override paths.
- Which visible setup/replay signals confirm each data layer is actually wired.

Manual exercise:

- Enable only `Integration Test Mod Pack [ref]`, run once, and verify Mira's interval, Borin's presence, patched loadout names, and trigger/tactic lines.

Open questions:

- Should we add a lightweight automated text assertion script that checks key setup lines from this integration pack?

## 2026-06-01 - Interstitial Phase 6.5.5.5 mod UI usability and result replay fix pass

Feature worked on:

- Replaced modal `PopupMenu` mod toggles with a non-modal inline checkbox panel so other UI interactions (like log scrolling) remain usable while selecting mods.
- Fixed replay event grouping so non-turn root events (including final `Result:`) are replayed again instead of being dropped.

Godot concepts introduced:

- `CheckBox` controls in a standard `PanelContainer` avoid modal popup input capture behavior.
- Structured event replay grouping should include untimed root events, not only timed turn-start roots.

Game architecture concepts introduced:

- None at combat-rule level; this is UI behavior and replay presentation correctness.

Files touched:

- `clockwork-company/scenes/combat_test_scene.tscn`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why modal popup menus can interfere with unrelated interactions in dense UI views.
- Why replay pipelines should preserve terminal summary events even when they are untimed.

Manual exercise:

- Open the mod list panel, leave it open, scroll the replay text pane, then run a fight and confirm the final `Result:` line appears.

Open questions:

- Should we cap the inline mod panel height differently when many packs exist?

## 2026-05-31 - Interstitial Phase 6.5.5.5 structured logging hardening pass

Feature worked on:

- Hardened structured combat logging with an explicit event schema and validation checks.
- Added typed event builder helpers so event payloads are created through named constructors, not ad hoc dictionaries.
- Added stable `unit_id` fields to runtime units and structured event payloads.
- Added `log_version` to simulator report output for forward-compatible format evolution.
- Expanded structured event coverage beyond basics (turn start, tactic decisions, attack, damage, heal, guard, guard expire, defeat, job effects, item triggers, result).
- Updated replay UI consumption to prefer unit IDs from payloads and only fall back to names.

Godot concepts introduced:

- Contract-style validation using `assert()` at event write time catches schema drift early in deterministic workflows.
- Static helper scripts can act as typed-ish event factories in GDScript without requiring a full custom class hierarchy.
- Runtime IDs can be derived deterministically from team + slot + display name for stable short-term identity.

Game architecture concepts introduced:

- Structured logs now have a formal contract (`event_type` + required payload keys) rather than a loose convention.
- Human-readable lines remain a view representation; machine consumers should rely on structured payloads.
- Replay and visualization become less brittle against text phrasing changes and unit display-name edits.

Files touched:

- `clockwork-company/scripts/combat/logging/combat_event_schema.gd`
- `clockwork-company/scripts/combat/logging/combat_events.gd`
- `clockwork-company/scripts/combat/logging/combat_log.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/combat/rules/tactic_resolver.gd`
- `clockwork-company/scripts/combat/rules/job_effect_resolver.gd`
- `clockwork-company/scripts/combat/rules/item_effect_resolver.gd`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How `CombatEventSchema` and `CombatLog.add_event()` validation work together to prevent malformed replay events.
- Why `CombatEvents` helpers reduce typo/regression risk compared to inline payload dictionaries.
- How `unit_id` is used in structured events and replay lookup, and why names remain a fallback only.

Manual exercise:

- In `combat_event_schema.gd`, temporarily add one required key to `EVENT_HEAL`, run the headless check, and observe where schema validation catches missing payload data.

Open questions:

- Should unit IDs eventually come from immutable data resources (GUID-like) rather than generated runtime strings?

## 2026-05-31 - Interstitial Phase 6.5.5.5 JSON modding bridge foundation

Feature worked on:

- Added a JSON content loader that preserves `.tres` authoring ergonomics while enabling mod overrides from `res://mods/*.json`.
- Implemented load/merge/validate/build flow for items, jobs, tactics, loadouts, units, and optional demo roster order.
- Switched demo battle unit sourcing from fixed preloaded unit list to loader-built unit definitions.
- Added reference JSON packs and sidecar options docs in `res://modding/reference/`.
- Added repository-level instruction updates requiring sidecar options docs to stay in sync with JSON/schema changes.

Godot concepts introduced:

- Runtime `Resource` reconstruction from JSON dictionaries can coexist with editor-authored `.tres` source assets.
- `DirAccess` + `FileAccess` + `JSON.parse_string` provide a lightweight pack loader pipeline.
- Deterministic mod merge by stable ids enables patch-style overrides without editing base assets.

Game architecture concepts introduced:

- Base content and modded content now share one runtime pipeline.
- `.tres` remains first-party authoring UX; JSON is an extensibility/interchange layer.
- Validation constraints centralize enum/reference safety before simulation begins.

Files touched:

- `clockwork-company/scripts/modding/json_content_loader.gd`
- `clockwork-company/scripts/combat/scenarios/demo_battle_factory.gd`
- `clockwork-company/modding/reference/base_content.json`
- `clockwork-company/modding/reference/base_content.options.md`
- `clockwork-company/modding/reference/example_mod_pack.json`
- `clockwork-company/modding/reference/example_mod_pack.options.md`
- `clockwork-company/mods/README.md`
- `AGENTS.md`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How base `.tres` content is converted into merged dictionaries, then rebuilt as runtime Resources.
- How id-based JSON patching works for adding or overriding content definitions.
- Why sidecar options docs are required for every modding JSON file.

Manual exercise:

- Copy `res://modding/reference/example_mod_pack.json` into `res://mods/`, run the fight, and verify the modified loadout/unit values show up in setup and combat pacing.

Open questions:

- Should we add an in-editor exporter button/script that regenerates `base_content.json` from `.tres` automatically to avoid manual drift?

## 2026-05-31 - Interstitial Phase 6.5.5.5 structured combat log event pass

Feature worked on:

- Added structured event metadata to combat log entries while preserving readable rendered text lines.
- Added a simulator report API (`run_demo_battle_report`) that returns plain lines, structured events, and roster snapshots.
- Migrated replay visualization to consume structured event payloads (`turn_start`, `damage`, `heal`, `defeat`) instead of parsing combat line phrasing.
- Kept text replay rendering unchanged so existing readability and highlight behavior remains intact.

Godot concepts introduced:

- Dictionary-first report APIs can be used as lightweight JSON-like contracts between simulation and UI layers.
- Hierarchical log entries can carry both human text and machine-friendly metadata simultaneously.
- UI replay grouping can follow parent/child event IDs and event types instead of string parsing.

Game architecture concepts introduced:

- Combat log now serves two consumers: human-readable text rendering and systems-facing structured replay data.
- Presentation systems no longer depend on simulator prose phrasing for core replay state changes.
- Roster snapshots are explicitly exported for UI bootstrap instead of being reconstructed from setup text lines.

Files touched:

- `clockwork-company/scripts/combat/logging/combat_log.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why structured event metadata is safer than parsing text phrases for replay behavior.
- How `run_demo_battle_report()` creates a compatibility bridge while we still keep `run_demo_battle()`.
- How replay VFX now keys off `event_type` and payload fields instead of fragile string matching.

Manual exercise:

- In `combat_simulator.gd`, find where `"damage"` events are emitted and trace how `previous_hp`/`new_hp` flow into floating text in `combat_test_scene.gd`.

Open questions:

- Should item/job/tactic child lines also gain explicit structured event types for richer future replay overlays?

Feature worked on:

- Added a focused polish pass for right-pane unit replay visuals without changing simulator logic.
- Added an action pulse ring when a unit takes a turn.
- Added floating HP delta text (`+X` / `-X`) when a unit is healed or damaged.
- Added defeat-state fade/desaturation so dead units remain visible but visually de-emphasized.
- Kept all effect triggering in UI-side replay parsing based on existing deterministic log lines.

Godot concepts introduced:

- Custom `Control` drawing can layer multiple lightweight effects (`draw_arc`, `draw_string`, alpha fades) in one `_draw()` pass.
- Replay-time metadata can be carried as dictionary snapshot fields and consumed by per-unit controls via `configure()`.
- Time-windowed effects can be implemented with simple `display_time - effect_start_time` checks, avoiding animation systems.

Game architecture concepts introduced:

- Visual effects remain presentation-only and are derived from replay/log data in `combat_test_scene.gd`.
- Combat rules, scheduler behavior, and deterministic outcomes remain unchanged in simulator modules.
- UI replay model now carries transient effect state (`turn_pulse_started_at`, `floating_text`, `defeat_time`) separate from combat state authority.

Files touched:

- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scripts/ui/unit_status_dot.gd`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How the action pulse and floating text are timestamped from replay events rather than from combat internals.
- Why defeat fade belongs in the draw layer and not in simulator data.
- How parser assumptions around `"takes a turn"`, `"HP: A -> B"`, and `"is defeated"` drive visual effects.

Manual exercise:

- In `unit_status_dot.gd`, set `PULSE_DURATION` from `0.45` to `0.2`, run replay, and compare readability of turn ownership.

Open questions:

- Should cooldown shimmer be added as a fourth effect now, or delayed until parser fragility is reduced with structured replay snapshots?

## 2026-05-31 - Interstitial Phase 6.5.5.5 combat simulator modularization pass

Feature worked on:

- Refactored `combat_simulator.gd` from a single large file into dedicated combat modules.
- Kept `CombatSimulator` as orchestration, while moving logging, runtime state, scheduler, targeting, tactics, job effects, item effects, text formatting, and demo roster setup into separate scripts.
- Preserved deterministic battle behavior and log style while improving file-level responsibility clarity.

Godot concepts introduced:

- `preload()`-based composition between plain `RefCounted` utility scripts.
- `static func` helper modules for deterministic rule utilities.
- Thin orchestrator pattern: one script coordinates specialized modules.

Game architecture concepts introduced:

- Separation of concerns inside combat simulation now mirrors the project’s broader architecture principles.
- Rules, runtime state, and text/log presentation helpers are explicitly separated even before adding more features.
- Scenario construction (demo roster) is now isolated from rule execution.

Files touched:

- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/combat/combat_constants.gd`
- `clockwork-company/scripts/combat/logging/combat_log.gd`
- `clockwork-company/scripts/combat/logging/combat_text_formatter.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/combat/runtime/turn_scheduler.gd`
- `clockwork-company/scripts/combat/rules/targeting_rules.gd`
- `clockwork-company/scripts/combat/rules/tactic_resolver.gd`
- `clockwork-company/scripts/combat/rules/job_effect_resolver.gd`
- `clockwork-company/scripts/combat/rules/item_effect_resolver.gd`
- `clockwork-company/scripts/combat/scenarios/demo_battle_factory.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Which script now owns each major combat responsibility by name alone.
- Why `CombatSimulator` is now easier to read as a battle flow controller.
- How deterministic behavior can be preserved through refactoring when responsibilities are moved, not redesigned.

Manual exercise:

- Open `combat_simulator.gd` and trace one attack turn end-to-end, listing each helper script called in order (scheduler, tactic resolver, job/item effect resolvers, formatter/log output).

Open questions:

- Should the next refactor replace UI-side log parsing with structured replay snapshots from these new combat modules?

## 2026-05-31 - Interstitial Phase 6.5.5.5 replay bugfix cleanup

Feature worked on:

- Fixed an empty Unit Replay panel bug by reading roster/setup data from cached simulator output lines instead of `RichTextLabel.text`.
- Changed replay pacing from fixed one-event-per-second to a simulation-time-scaled delay with a minimum clamp.
- Removed an unused scene template node used during early UI prototyping.

Godot concepts introduced:

- `RichTextLabel.append_text()` content should not be treated as a reliable data source for downstream parsing in this flow.
- Replay pacing can map from simulation deltas to wall-clock delay via a simple scale constant plus a minimum wait guard.
- Cleaning unused scene nodes reduces editor noise and makes ownership clearer.

Game architecture concepts introduced:

- Presentation parsers should read from source-of-truth cached simulation lines, not rendered UI state.
- Time readability in replay is a UX transform, not a combat-rule change.

Files touched:

- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scenes/combat_test_scene.tscn`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why the Unit Replay pane failed to render despite replay logs still working.
- Why variable replay pacing better reflects action timing than a fixed one-second step.
- Why removing temporary scene scaffolding helps future refactors.

Manual exercise:

- In `combat_test_scene.gd`, temporarily set `SECONDS_PER_SIM_SECOND` to `1.0`, run replay, then set it to `0.1` and compare readability versus speed.

Open questions:

- Should replay speed scaling become an exposed inspector setting (or runtime slider) once we add more visual effects?

## 2026-05-31 - Interstitial Phase 6.5.5.5 replay pane split and unit dots

Feature worked on:

- Split the Combat Replay area into two columns with a vertical divider.
- Kept the left column as the highlighted text replay log.
- Added a right-column prototype visual replay panel that shows one dot per unit, with name, HP arc, and cooldown bar.
- Made cooldown bars deplete against interpolated simulation time between timestamped events so the acting unit reaches empty when its turn line appears.
- Kept combat simulation unchanged by parsing existing roster and replay log text into a UI-only replay model.

Godot concepts introduced:

- `HBoxContainer` plus `VSeparator` can create an explicit left/right pane split inside an existing replay area.
- A custom `Control` script with `_draw()` (`UnitStatusDot`) can render circles, arcs, bars, and labels without textures.
- `_process(delta)` can drive smooth interpolation between replay keyframes while `Timer` still controls event cadence.
- UI code can create scripted controls at runtime (`UnitStatusDotScript.new()`) from parsed replay data.

Game architecture concepts introduced:

- This is still presentation-only; simulator determinism and combat rules are untouched.
- Replay state can be reconstructed from plain text logs when the parser remains narrow and intentional.
- Visual replay timing should map to simulation time, not wall-clock frame logic in combat rules.

Files touched:

- `clockwork-company/scenes/combat_test_scene.tscn`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scripts/ui/unit_status_dot.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why the new replay split belongs in UI scene structure, not simulator code.
- How `combat_test_scene.gd` parses roster and HP lines into a visual replay model.
- How `displayed_sim_time` interpolation makes cooldown depletion line up with action events.
- What `UnitStatusDot` owns versus what `combat_test_scene.gd` owns.

Manual exercise:

- In `unit_status_dot.gd`, temporarily invert `_cooldown_ratio()` to `1.0 - ratio`, run replay, and explain why that no longer matches the action timing shown in text.

Open questions:

- Should the visual replay panel eventually read structured simulator snapshots instead of parsing text lines once we need richer effects (portraits, statuses, cast bars)?

## 2026-05-31 - Interstitial Phase 6.5 log readability background pass

Feature worked on:

- Replaced the default gray scene backdrop with an intentional dark neutral background for better text contrast.
- Kept this as a scene-level presentation change so combat logic and replay behavior remain unchanged.

Godot concepts introduced:

- `ColorRect` can act as a full-viewport background layer in `Control`-based UI scenes.
- `mouse_filter = Ignore` on the background prevents it from intercepting button/scroll input.

Game architecture concepts introduced:

- None at the combat-system level. This is purely a readability and UX presentation adjustment.

Files touched:

- `clockwork-company/scenes/combat_test_scene.tscn`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why a stable background tone matters when category colors are semantically meaningful.
- How to add a non-interactive background layer in a Godot UI scene.
- Why this does not affect simulator determinism or replay timing.

Manual exercise:

- In `combat_test_scene.tscn`, tweak the `Background` `ColorRect` color slightly lighter and darker, run replay, and compare readability of `guard`, `takes a turn`, and `is defeated` lines.

Open questions:

- Should we expose the background color in the same palette Resource so contrast tuning happens in one place?

## 2026-05-31 - Interstitial Phase 6.5 intentional color-system pass

Feature worked on:

- Reworked the default combat log highlight palette to a deliberate hue map so categories are instantly distinguishable.
- Avoided clustering semantically different categories into nearby blue shades.
- Kept the same category set and UI behavior, changing only color assignments in the palette Resource.

Godot concepts introduced:

- A `Resource`-backed palette supports iterative visual design without touching control-flow logic.
- Color tuning can happen directly in the Inspector while preserving script stability.

Game architecture concepts introduced:

- This is a pure presentation pass: simulator output and deterministic combat resolution stay unchanged.
- Semantic categories can map to a stable visual language that improves log scannability.

Files touched:

- `clockwork-company/scripts/ui/combat_log_highlight_palette.gd`
- `clockwork-company/resources/ui/combat_log_highlight_palette_default.tres`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why separating category logic from color values makes balancing readability easier.
- How to tune palette cohesion while still keeping category contrast high.
- Why this kind of UX pass belongs in UI data, not combat systems.

Manual exercise:

- In Godot, open `combat_log_highlight_palette_default.tres`, adjust only `attack_color` and `item_trigger_color` to be intentionally too similar, run replay, then separate them again and compare scan speed.

Open questions:

- Should we eventually ship two built-in palettes (default and color-blind-friendly) and expose a runtime toggle?

## 2026-05-31 - Interstitial Phase 6.5 highlight palette Resource

Feature worked on:

- Refactored combat-log category colors out of script constants into a dedicated `CombatLogHighlightPalette` Resource.
- Added a default palette `.tres` asset and wired `combat_test_scene.gd` to use it via an exported field.
- Kept line categorization logic in UI code, but now each category resolves to a `Color` from the Resource.

Godot concepts introduced:

- Custom `Resource` scripts can hold grouped editor-tunable values such as `Color` fields.
- Exported Resource references on a node script let the Inspector swap presets without code edits.
- `Color.to_html(false)` can convert an inspector-selected color into a BBCode color string.

Game architecture concepts introduced:

- Presentation configuration can be data-driven independently from simulator rules.
- Combat readability tuning now lives as editable UI data, while simulator determinism and output text stay unchanged.

Files touched:

- `clockwork-company/scripts/ui/combat_log_highlight_palette.gd`
- `clockwork-company/resources/ui/combat_log_highlight_palette_default.tres`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why moving colors to a Resource improves manual tuning workflow.
- How `log_highlight_palette` on `combat_test_scene.gd` separates category logic from specific color choices.
- Why this refactor changes UX/editor ergonomics without changing combat simulation behavior.

Manual exercise:

- Duplicate `combat_log_highlight_palette_default.tres`, change three category colors in the Inspector, assign the duplicate palette on the `CombatTestScene` node, and verify replay colors change while fight outcomes remain identical.

Open questions:

- Should we later support multiple palette presets (for contrast/accessibility themes) switchable from the UI at runtime?

## 2026-05-31 - Interstitial Phase 6.5 combat log keyword highlighting

Feature worked on:

- Added UI-layer keyword/category highlighting for combat log readability now that both panes use `RichTextLabel`.
- Kept simulator output as plain deterministic strings and applied color tags only in `combat_test_scene.gd`.
- Preserved BBCode safety by escaping line text before adding any color wrapper tags.

Godot concepts introduced:

- `RichTextLabel` BBCode color tags can be applied per appended line.
- A small line-categorization helper can map text patterns to visual styles without changing source combat data.
- Escaping user/content text before adding BBCode tags prevents accidental markup parsing.

Game architecture concepts introduced:

- Log semantics still belong to the simulator; readability styling belongs to UI presentation.
- Visual emphasis can be added as a non-deterministic-neutral post-process over already-generated log text.

Files touched:

- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `ARCHITECTURE.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why highlighting was added in the UI script instead of combat simulator logic.
- How `_format_log_line_with_highlighting()` and `_log_highlight_color_for_line()` separate styling from replay timing.
- Why escaping `[` is still required before wrapping text in BBCode color tags.

Manual exercise:

- In `combat_test_scene.gd`, change one category color constant (for example `LOG_COLOR_DAMAGE`), run replay, and explain which lines changed and why the combat result did not.

Open questions:

- Should we keep whole-line coloring only, or add a second small pass later for phrase-level emphasis inside mixed lines?

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

- Run the documented `--check-only` command with `--log-file godot-check.log`, confirm it exits cleanly, then run it again and confirm the same git-ignored scratch log path can be reused.

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

- In `clockwork-company/resources/jobs/apprentice.tres`, temporarily set `forbid_trinket` to `true`, run the fight, and explain why Sol's Glass Focus no longer changes stats or triggers on attack.

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

- Open `clockwork-company/resources/items/glass_focus.tres`, change the `Glass Focus Attack Burst` effect `amount` from `2` to `0`, run the combat scene, and predict how Sol Apprentice's attack log lines and damage totals change.

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
## 2026-06-03 - Scenario and campaign vertical slice

## What changed

- Added data Resources for scenarios, scenario rules, campaigns, and campaign scenario nodes.
- Added in-memory progress wrappers for scenario and campaign state.
- Updated `RunState` so it can run either the existing Phase 7 five-fight sequence or a scenario-provided encounter list.
- Added `The First Road`, a tiny three-scenario sample campaign.
- Updated the combat test scene so available campaign scenarios can be started from the existing UI.

## Godot concepts involved

- A Resource/data definition is inspectable source data. `ScenarioDefinition` says what a scenario is supposed to contain.
- Runtime progress is mutable state. `ScenarioProgress` and `CampaignProgress` say where this playthrough currently is.
- Resource references let a scenario point to normal encounter and reward Resources instead of duplicating enemy or item data.

## Why campaign wraps scenarios

The campaign layer should decide which scenarios are available and complete. It should not decide combat rules. Real battles still go through `CombatSimulator`, while `RunState` still owns between-fight reward, equipment, and job XP state.

## Manual test

- Open the Godot project in `clockwork-company/`.
- Press Play.
- Start `Roadside Ambush`.
- Complete its three encounters.
- Confirm `Burned Chapel` unlocks, then complete it.
- Confirm `Iron Tollgate` unlocks, then complete it.
- Confirm the campaign summary marks the campaign complete.

## Files to inspect

- `clockwork-company/scripts/data/scenario_definition.gd`
- `clockwork-company/scripts/campaign/campaign_manager.gd`
- `clockwork-company/resources/campaigns/first_road_campaign.tres`

## Exercise

Add a fourth scenario Resource and make `Iron Tollgate` unlock it instead of completing the campaign. Predict which campaign node field needs to change before editing.

## Tradeoffs and risks

- Scenario rules are data-only placeholders for now. That is intentional, but the UI must keep making that clear.
- Campaign progress is in-memory only. Save/load should wait until roster persistence is better defined.
- `RunState` now supports two sources of encounter order, so future changes should keep the default Phase 7 path and scenario-backed path both checked.

## 2026-06-03 - Scenario planning UI and item effect cleanup

What changed:

- The scene now opens on authored scenario and party planning data instead of pre-running a combat report.
- Added a planning panel with scenario buttons, selected scenario details, party summaries, selected-unit details, and simple equipment cycling before a scenario starts.
- `RunState` can start a scenario from the edited planning party.
- Removed legacy top-level item effect fields: `trigger`, `effect`, and `effect_amount`.
- JSON modding examples now use `effects[]` for item effects.

Godot concepts introduced:

- Dynamic UI containers can be built in script with normal `Control` nodes when a prototype layout is changing quickly.
- A planning UI can edit Resource instances created for this run without mutating the source `.tres` files.
- `EffectDefinition` subresources are now the single item-effect authoring path.

What I should now be able to explain:

- Why scenario selection should not run the combat simulator.
- How selected planning-party Resources flow into `RunState.start_scenario(...)`.
- Why item effects live in `effects[]` instead of duplicated one-effect fields.
- Why physical damage uses armor and magic damage does not.

Manual exercise:

- Select `Roadside Ambush`, pick Mira, cycle her weapon once, then start the scenario. Before pressing `Run Fight`, predict which gear line should differ in the static fight setup.

Tradeoffs and risks:

- Equipment editing is intentionally a simple cycle-button prototype, not a full inventory browser yet.
- The old Phase 7 run path remains available as a debug fallback, so future UI work should avoid letting it dominate the main scenario flow again.

## 2026-06-03 - Scenario list and replay cleanup follow-up

What changed:

- Scenario list buttons now select scenarios by name instead of pretending to start them.
- The list shows all campaign scenarios, with locked and completed states labeled.
- The separate start button starts only the selected unlocked scenario.
- The old `Combat Conditions` pane is hidden because the planning UI now owns scenario, party, and unit context.
- Combat replay now filters structured events so setup/context lines do not replay as combat.
- The game window no longer forces itself to a scripted size on startup, so normal resizing is left to the user/window manager.

What I should now be able to explain:

- Why selection and starting are separate UI actions.
- Why locked scenarios can still be inspectable.
- Why structured replay should filter by timed combat roots and the final result.

Manual exercise:

- Select each scenario in the list and compare its encounters, rules, tags, rewards, and unlocks. Then start only the available one and confirm the replay begins with actual combat events.

## 2026-06-03 - Resource tooltip foundation

What changed:

- Added a shared custom tooltip presenter that follows the mouse and clamps to the window.
- Added a Resource tooltip builder that formats units, loadouts, items, effects, jobs, skills, passives, reactions, tactics, encounters, rewards, and generic Resources.
- Wired scenario list entries, scenario detail Resources, party units, unit detail Resources, reward choices, and replay unit dots into the tooltip system.

Godot concepts introduced:

- A single overlay `Control` can present tooltip content for many different hovered controls.
- Hover signals can store the hovered Resource in control metadata so refreshable UI controls do not accumulate duplicate signal connections.
- Custom tooltips are more work than native `tooltip_text`, but they give the project a path toward locked/nested tooltips later.

Manual exercise:

- Hover a scenario, an encounter, a unit, an item, an item effect, and a replay unit dot. For each one, explain whether the tooltip is showing source Resource data or runtime combat state.

## 2026-06-03 - Godot Best Practices Audit

We added `GODOT_BEST_PRACTICES_AUDIT.md`, a research-backed audit of Godot practices against the current project. The point is not to obey every guideline immediately; it is to make our decisions visible.

Key lesson: best practices are context tools. Godot's guidance strongly supports our use of Resources for authored data and our separation of combat simulation from UI. It also points at the next cleanup pressure: `combat_test_scene.gd` is now doing too much and should be split into focused Control scenes/scripts.

Godot concepts involved:

- Resources as inspectable data containers.
- Control scenes, Containers, anchors, and size flags for UI.
- Signals for panel-to-parent communication.
- Autoloads as broad-scope services that should be used sparingly.
- Static typing as a readability and editor-support tool.

Manual test:

1. Read `GODOT_BEST_PRACTICES_AUDIT.md`.
2. Open `clockwork-company/scripts/ui/combat_test_scene.gd`.
3. Pick one UI responsibility and decide whether it matches one of the proposed future panels.

Small exercise: sketch the public methods and signals for a future `ScenarioListPanel` without implementing it.

Tradeoff: adding an audit document creates one more doc to maintain, but it should prevent best-practice conversations from becoming vague or repetitive.

## 2026-06-04 - Scenario workbench panel extraction

Feature worked on:

- Extracted the scenario list, scenario detail, party list, and unit detail areas out of `combat_test_scene.gd`.
- Added small Control scenes/scripts for those panels.
- Kept `combat_test_scene.gd` as the coordinator for campaign/run state, selected scenario/unit state, equipment mutation, tooltips, and combat replay.

Godot concepts introduced:

- A `.tscn` scene can wrap one focused `Control` script and be instantiated by a parent scene.
- Child UI panels can emit custom signals such as `scenario_selected` and `unit_selected` instead of directly changing parent state.
- The parent can pass current Resource/runtime data into child panels through public render methods.
- A shared tooltip presenter can stay parent-owned while children request tooltip display through signals.

Game architecture concepts introduced:

- UI ownership can be split without changing combat authority.
- Read-only panels are a lower-risk extraction target than panels that mutate run state.
- Scenario/campaign managers remain thin: they still decide availability and completion, not UI rendering details or combat rules.

Files touched:

- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scripts/ui/scenario_list_panel.gd`
- `clockwork-company/scripts/ui/scenario_detail_panel.gd`
- `clockwork-company/scripts/ui/party_panel.gd`
- `clockwork-company/scripts/ui/unit_detail_panel.gd`
- `clockwork-company/scenes/scenario_list_panel.tscn`
- `clockwork-company/scenes/scenario_detail_panel.tscn`
- `clockwork-company/scenes/party_panel.tscn`
- `clockwork-company/scenes/unit_detail_panel.tscn`
- `ARCHITECTURE.md`
- `TODO.md`
- `GODOT_BEST_PRACTICES_AUDIT.md`

What I should now be able to explain:

- Which panel owns scenario list rendering versus selected scenario detail rendering.
- Why `combat_test_scene.gd` still owns starting scenarios and cycling equipment.
- How a child signal reaches the parent without the child knowing about `CampaignManager` or `RunState`.

Manual exercise:

- Open `scenario_list_panel.gd` and trace what happens after pressing a scenario button: identify the signal it emits, then find the parent callback that updates `selected_scenario`.

Open questions:

- Should the next extraction be the unit action/equipment controls or the combat replay panel?
- Should repeated tooltip signal wiring eventually move into a tiny helper, or is the current duplication clearer for learning?

## 2026-06-04 - Unit action panel extraction

Feature worked on:

- Extracted the selected-unit action area from `combat_test_scene.gd` into `UnitActionPanel`.
- The panel now renders start-scenario, planning equipment cycle, and between-fight equipment option buttons.
- The parent scene still owns the actual state changes: starting scenarios, mutating planning loadouts, and applying run equipment.

Godot concepts introduced:

- A child `Control` can emit request signals for actions it should not perform itself.
- The parent can keep authority over game state while a child scene owns button layout.
- Passing booleans and option dictionaries into a panel is a simple bridge before a fuller view model exists.

Game architecture concepts introduced:

- Rendering a button and executing the game command behind that button are separate responsibilities.
- Equipment changes still flow through `RunState` or planning-party Resource copies; the UI panel is not inventory authority.

Files touched:

- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scripts/ui/unit_action_panel.gd`
- `clockwork-company/scenes/unit_action_panel.tscn`
- `ARCHITECTURE.md`
- `TODO.md`
- `GODOT_BEST_PRACTICES_AUDIT.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why `UnitActionPanel` emits `cycle_equipment_requested` instead of changing a loadout directly.
- Why `combat_test_scene.gd` still owns `_on_cycle_equipment_pressed` and `_on_planning_equip_pressed`.
- How the panel knows which buttons to show without knowing what `RunState` is.

Manual exercise:

- Select a unit before starting a scenario, press `Cycle Weapon`, and trace the signal from `UnitActionPanel` to the parent callback that changes the planning loadout.

Open questions:

- Should combat replay be extracted as one panel next, or should replay text and replay visualization become separate child panels?

## 2026-06-04 - Combat replay panel extraction

Feature worked on:

- Extracted combat replay behavior from `combat_test_scene.gd` into `CombatReplayPanel`.
- The replay panel now owns timed replay playback, combat replay text autoscroll, structured event grouping, visual unit dot state, and runtime unit tooltip requests.
- The parent scene still owns combat report generation, run completion, campaign scenario completion, and summary/status panel refreshes.

Godot concepts introduced:

- A script can be attached to an existing scene node to give an already-authored UI subtree focused behavior.
- A child panel can own a `Timer` connection and emit `replay_finished` when its presentation work is complete.
- Signals can keep presentation completion separate from game-state advancement.

Game architecture concepts introduced:

- Combat simulation still finishes before replay starts; replay is presentation, not combat authority.
- Structured combat events are now consumed by a replay panel instead of being managed by the scenario workbench parent.
- Runtime unit snapshots shown in tooltips are presentation state derived from simulator reports, not mutable combat rules.

Files touched:

- `clockwork-company/scripts/ui/combat_replay_panel.gd`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scenes/combat_test_scene.tscn`
- `ARCHITECTURE.md`
- `TODO.md`
- `GODOT_BEST_PRACTICES_AUDIT.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why `CombatReplayPanel` emits `replay_finished` instead of calling `RunState.complete_fight(...)`.
- Why replay can update unit dots from structured event payloads without changing combat rules.
- Why the existing replay UI subtree stayed in `combat_test_scene.tscn` while behavior moved into a focused script.

Manual exercise:

- Start a fight and watch for the moment replay ends. Then find `_on_replay_finished` in `combat_test_scene.gd` and explain why campaign completion happens there rather than inside `CombatReplayPanel`.

Open questions:

- Should future replay work split text replay and unit-dot visualization into separate child panels, or is one replay panel still the clearest ownership boundary?

## 2026-06-04 - Shared combat log rich text formatter

Feature worked on:

- Moved duplicated BBCode escaping and combat-line color highlighting out of `combat_test_scene.gd` and `CombatReplayPanel`.
- Added `CombatLogRichTextFormatter` as the shared UI helper for setup/status text and replay text.

Godot concepts introduced:

- A `RefCounted` script with static functions is useful for shared formatting logic that does not need to be a scene node.
- `RichTextLabel` display rules can stay in UI code while combat simulation continues to emit plain readable lines and structured events.

Game architecture concepts introduced:

- Formatting is presentation logic, not combat logic.
- A small helper is justified when two UI owners need exactly the same escaping and highlighting behavior.

Files touched:

- `clockwork-company/scripts/ui/combat_log_rich_text_formatter.gd`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scripts/ui/combat_replay_panel.gd`
- `ARCHITECTURE.md`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why setup/status text and replay text should share highlighting rules.
- Why the formatter does not know about `RunState`, `CampaignManager`, or replay timing.

Manual exercise:

- Change one highlight color in `combat_log_highlight_palette_default.tres`, run a fight, and confirm both setup/status lines and replay lines use the same palette rule where applicable.

Open questions:

- Should highlighting remain whole-line, or should a later pass highlight only keywords and values inside each line?

## 2026-06-04 - Replay cache cleanup and architecture wording

Feature worked on:

- Removed the old cached replay-line array from `combat_test_scene.gd`.
- Renamed the log split helper so it now describes its actual job: collecting static setup/context lines before `Combat log:`.
- Updated architecture wording so replay timing and visualization are documented as `CombatReplayPanel` responsibilities.

Godot concepts introduced:

- After moving behavior into a child panel, old parent caches should be removed if they no longer feed UI state.
- A helper name should describe the current data flow, not the older implementation it replaced.

Game architecture concepts introduced:

- The parent workbench now keeps only static setup/context lines from simulator output.
- Timed replay uses structured combat events, which keeps replay presentation separate from plain setup text.

Files touched:

- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `ARCHITECTURE.md`
- `GODOT_BEST_PRACTICES_AUDIT.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why `CombatReplayPanel` does not need the old plain replay-line cache.
- Why `combat_test_scene.gd` still splits simulator output at `Combat log:` for the setup pane.

Manual exercise:

- Find `_collect_static_log_lines` and explain why it stops collecting after `Combat log:` appears.

Open questions:

- Should the setup/context summary eventually become its own `FightSummaryPanel`, or is it small enough to stay parent-owned for now?

## 2026-06-04 - Named item effect Resources in the Inspector

Feature worked on:

- Synced `EffectDefinition.display_name` into `resource_name` so item effect subresources can show their authored names in the Godot Inspector.
- Added a `_to_string()` fallback for effect Resources, matching the existing skill/passive/reaction data Resource pattern.

Godot concepts introduced:

- `@tool` lets a Resource script run setter logic while edited in the editor.
- `resource_name` is the editor-facing label Godot can use for nested Resource entries.
- `_to_string()` gives Resources a readable fallback when Godot or debug output asks for their string form.

Game architecture concepts introduced:

- This is an authoring ergonomics change, not combat behavior. Effects still resolve through `EffectDefinition` data and `ItemEffectResolver`.
- Better Resource labels make data-driven content easier to inspect without adding editor plugins.

Files touched:

- `clockwork-company/scripts/data/effect_definition.gd`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why syncing `display_name` to `resource_name` helps nested item effects in the Inspector.
- Why the effect still needs explicit fields such as trigger, condition, target selector, and effect type even when it has a readable name.

Manual exercise:

- Open `clockwork-company/resources/items/glass_focus.tres`, expand its `effects` array, and confirm the subresource presents as `Glass Focus Attack Burst` instead of only `EffectDefinition`.

Open questions:

- Should other older data Resources without `resource_name` setters get the same Inspector-label treatment during a future authoring cleanup pass?

## 2026-06-04 - Fourth sample campaign scenario

Feature worked on:

- Added `Clocktower Claim` as a fourth sample scenario Resource.
- Updated `The First Road` campaign so `Iron Tollgate` unlocks `Clocktower Claim`, and `Clocktower Claim` is now the campaign-completing node.
- Removed the completed fourth-scenario TODO and updated roadmap/design wording.

Godot concepts introduced:

- A `.tres` Resource can reuse existing encounter and reward Resources to create new authored content without new code.
- A campaign node Resource controls unlock chaining by naming scenario ids to unlock on completion.

Game architecture concepts introduced:

- Scenario content can validate campaign flow before new mechanics exist.
- Campaign completion belongs to the campaign node, not the scenario itself, so the same scenario could theoretically sit in a different campaign position later.

Files touched:

- `clockwork-company/resources/scenarios/clocktower_claim.tres`
- `clockwork-company/resources/campaigns/first_road_campaign.tres`
- `TODO.md`
- `ROADMAP.md`
- `DESIGN_NOTES.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why `Iron Tollgate` now unlocks `clocktower_claim` instead of setting `completes_campaign`.
- Why the new scenario reuses existing encounters and rewards instead of adding a new content set.

Manual exercise:

- Complete `Roadside Ambush`, `Burned Chapel`, and `Iron Tollgate`, then confirm `Clocktower Claim` unlocks and only completing it marks the campaign complete.

Open questions:

- Should the next campaign content pass make later scenarios mechanically distinct through implemented scenario rules, or keep using content composition until the UI explains rules better?

## 2026-06-04 - Planning computed stat preview

Feature worked on:

- Added a planning stat preview helper that builds `UnitState` objects from the current planning party without running combat turns.
- Updated the party panel to show computed planning combat stats instead of raw authored base stats.
- Updated the unit detail panel to show base stats, computed stats, battle-start preview stats when they differ, and skipped equipment.

Godot concepts introduced:

- A `RefCounted` helper can hold shared UI calculations without becoming a scene node.
- UI panels can render derived runtime previews while still leaving combat authority in the simulator.

Game architecture concepts introduced:

- `UnitDefinition` is source data; `UnitState` is the runtime combat copy that applies growth, equipment permissions, and stat modifiers.
- Battle-start hooks can be previewed by using resolver functions on temporary `UnitState` copies without advancing the turn scheduler.

Files touched:

- `clockwork-company/scripts/ui/planning_stat_preview.gd`
- `clockwork-company/scripts/ui/party_panel.gd`
- `clockwork-company/scripts/ui/unit_detail_panel.gd`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `ARCHITECTURE.md`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why base stats and computed combat stats can differ.
- Why the preview uses temporary `UnitState` objects instead of running a battle report.
- Why skipped equipment belongs in the planning view before a fight starts.

Manual exercise:

- Select a unit, cycle one equipment slot, and predict which computed stat should change before pressing `Start Selected Scenario`.

Open questions:

- Should future scenario enemy previews use the same helper, or wait for a dedicated fight-preview panel?

## 2026-06-04 - Clearer scenario selection states

Feature worked on:

- Scenario list entries now label scenarios as available, locked, complete, or active.
- The scenario list remains visible while a scenario is active so the active state can be inspected.
- Scenario detail text now explains what each status means, including that completed-scenario replay is not implemented yet.
- The start button now changes its label for locked, complete, and active scenarios instead of only disabling itself.

Godot concepts introduced:

- UI state can be expressed through button labels and disabled states without changing underlying game rules.
- Child panels can receive a plain status string from the parent rather than depending directly on `CampaignManager`.

Game architecture concepts introduced:

- Selection, starting, active play, completion, and replay are separate states.
- Completed campaign scenarios are inspectable but not replayable until standalone/replay mode is deliberately implemented.

Files touched:

- `clockwork-company/scripts/ui/scenario_list_panel.gd`
- `clockwork-company/scripts/ui/scenario_detail_panel.gd`
- `clockwork-company/scripts/ui/unit_action_panel.gd`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scripts/ui/scenario_list_panel.gd`
- `clockwork-company/scripts/ui/scenario_detail_panel.gd`
- `ARCHITECTURE.md`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why locked scenarios are still selectable for inspection.
- Why a completed scenario being visible is not the same thing as being replayable.
- Why `combat_test_scene.gd` still computes status while child panels only render it.

Manual exercise:

- Start `Roadside Ambush`, then select each scenario in the list and explain why its start button label is enabled or disabled.

Open questions:

- Should completed scenarios eventually launch a standalone replay run, or should replay wait until campaign save/load exists?

## 2026-06-04 - Subordinate debug harness controls

Feature worked on:

- Labeled the old Phase 7/loss-test controls as a debug harness.
- Shortened and visually softened the debug buttons so the main scenario flow remains the primary UI path.
- Kept the debug paths available for testing instead of deleting them.

Godot concepts introduced:

- Buttons can be made flatter and quieter with `flat`, `modulate`, and font-size overrides.
- Prototype controls can remain in the scene while being visually deprioritized.

Game architecture concepts introduced:

- A debug harness is useful while the scenario flow matures, but it should not look like the main player path.

Files touched:

- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why the Phase 7 run path still exists.
- Why visual hierarchy matters even in a prototype UI.

Manual exercise:

- Open the scene and identify which controls belong to the main scenario flow versus the debug harness before pressing any buttons.

Open questions:

- Should the debug harness eventually move behind a collapsible advanced section, or is the small subdued label enough for now?

## 2026-06-04 - Richer unit detail presentation

Feature worked on:

- Added ancestry feature display to the unit detail panel.
- Labeled skill, passive, and reaction sources as current-job abilities or equipped learned overrides.
- Numbered tactic order and included the current job's appended default tactic.
- Removed the completed unit-detail presentation TODO.

Godot concepts introduced:

- A UI panel can show Resource relationships directly by rendering hoverable rows for nested Resource references.
- Ordered arrays such as tactics can be displayed as priority lists without changing the underlying data.

Game architecture concepts introduced:

- Current-job abilities and equipped learned overrides are different sources even when combat only sees the resolved ability.
- Job default tactics are appended after loadout tactics, so explicit loadout tactics keep priority.
- An ancestry feature is part of the unit's body/origin layer, not its job or gear.

Files touched:

- `clockwork-company/scripts/ui/unit_detail_panel.gd`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How a unit's selected skill/passive/reaction is resolved from loadout override versus current job fallback.
- Why tactic order matters before combat starts.
- Why ancestry feature appears near ancestry instead of under equipment or jobs.

Manual exercise:

- Open Roger Spellsword in the party detail panel and identify which ability line comes from an equipped learned override rather than the current job.

Open questions:

- Should future unit detail UI group this information into collapsible sections once the panel becomes visually dense?

## 2026-06-04 - Godot check helper script

Feature worked on:

- Added `tools/check_godot.ps1` as a small wrapper around the repeated headless Godot `--check-only` command.
- Kept the project-local `--log-file godot-check.log` behavior so sandboxed checks avoid Godot's normal per-user log directory.
- Removed the completed helper-script TODO.

Godot concepts introduced:

- Godot can run script checks from the command line with `--headless`, `--path`, `--check-only`, and `--script`.
- `--log-file` can redirect Godot logs into the project folder.

Game architecture concepts introduced:

- A project helper script is not game architecture, but it protects the learning loop by making checks easy and consistent.

Files touched:

- `tools/check_godot.ps1`
- `TODO.md`
- `GODOT_BEST_PRACTICES_AUDIT.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why the helper writes `godot-check.log` into the Godot project folder.
- How to point the helper at a different script with the `-Script` argument.

Manual exercise:

- Run `powershell -ExecutionPolicy Bypass -File tools/check_godot.ps1` from the repository root and confirm it prints the Godot version without script errors.

Open questions:

- Should future validation scripts live in `tools/` too, or inside the Godot project if they need `res://` paths?

## 2026-06-04 - Tooltip visual polish

Feature worked on:

- Improved custom tooltip spacing, border color, text color, width, and font sizing.
- Enabled BBCode in `TooltipPresenter` and added presenter-owned formatting for title lines, section headings, and bullet rows.
- Kept tooltip content builders plain-text so Resource-specific tooltip logic does not need to know presentation markup.

Godot concepts introduced:

- `RichTextLabel` can use BBCode for lightweight text hierarchy.
- User-provided or data-provided text should be escaped before it is inserted into BBCode.
- `StyleBoxFlat` controls panel padding, background, border, and corner radius.

Game architecture concepts introduced:

- Tooltip content and tooltip presentation are separate responsibilities.
- Visual polish can improve inspectability without changing Resource data or combat rules.

Files touched:

- `clockwork-company/scripts/ui/tooltip_presenter.gd`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why the tooltip builder still returns plain text.
- Why `TooltipPresenter` escapes text before applying BBCode.

Manual exercise:

- Hover a unit, item, effect, and encounter, then identify the title line and any section-style lines in the tooltip.

Open questions:

- Should locked/nested tooltips keep using this one presenter, or split pinned tooltip windows into a separate scene?

## 2026-06-04 - Tooltip source notes

Feature worked on:

- Resource tooltips now end with a source note that marks them as authored Resource data.
- Runtime unit tooltips now mark themselves as runtime combat state.
- Removed the completed tooltip-source TODO.

Godot concepts introduced:

- Tooltip text can carry small teaching notes without changing the controls that request tooltips.

Game architecture concepts introduced:

- Source definitions and runtime combat state are intentionally different layers.
- The same visible unit can have authored Resource data in planning and mutable runtime state during replay.

Files touched:

- `clockwork-company/scripts/ui/resource_tooltip_builder.gd`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why a unit tooltip during planning is not the same kind of data as a replay unit-dot tooltip.
- Why the source note belongs in the tooltip builder instead of every panel.

Manual exercise:

- Hover a party unit before combat, then hover that unit's replay dot during combat, and compare the source note at the bottom.

Open questions:

- Should future glossary tooltips have a third source label such as `Source: rules glossary`?

## 2026-06-04 - Replay speed control

Feature worked on:

- Added 0.5x, 1x, 2x, and 4x replay speed buttons to `CombatReplayPanel`.
- Replay speed now changes the timer delay between subsequent replay events.
- Removed the completed replay speed TODO.

Godot concepts introduced:

- UI controls can be created dynamically by a focused panel script when the scene structure is still evolving.
- Toggle buttons can act like a segmented control when the panel keeps their pressed states synchronized.
- A `Timer` can pace presentation without becoming combat authority.

Game architecture concepts introduced:

- Replay speed changes how quickly already-generated events are revealed; it does not rerun or alter combat simulation.
- Presentation timing belongs to `CombatReplayPanel`, not `CombatSimulator`.

Files touched:

- `clockwork-company/scripts/ui/combat_replay_panel.gd`
- `ARCHITECTURE.md`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why changing replay speed cannot change the fight winner.
- Why the speed control lives in the replay panel instead of the parent scene.

Manual exercise:

- Start a fight, switch to 4x for a few events, then switch to 0.5x and confirm only reveal pacing changes.

Open questions:

- Should speed changes reschedule the currently waiting event immediately, or is applying the speed to subsequent events enough for this prototype?

## 2026-06-04 - Standalone scenario practice mode

Feature worked on:

- Added a `Practice Scenario` action for unlocked scenarios.
- Practice starts a scenario through `RunState` without marking campaign progress current, complete, or unlocked.
- Campaign scenario starts still use `CampaignManager.start_scenario(...)` and still mutate campaign progress on completion.
- Removed the completed standalone scenario mode TODO.

Godot concepts introduced:

- A child panel can emit a second action signal for a similar button while the parent decides which game-state path to run.
- Optional function parameters can keep one start helper shared while preserving the important campaign/practice distinction.

Game architecture concepts introduced:

- A scenario definition can be played in different contexts: campaign progression or standalone practice.
- Campaign mutation belongs to `CampaignManager`; a practice run should not touch it.
- `RunState` can run scenario encounters without being the owner of campaign unlock logic.

Files touched:

- `clockwork-company/scripts/ui/unit_action_panel.gd`
- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `ARCHITECTURE.md`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why `Practice Scenario` does not call `CampaignManager.start_scenario(...)`.
- Why campaign completion still happens only when `active_campaign_scenario_id` is set.
- Why `RunState` is enough to run scenario encounters but not enough to unlock campaign nodes.

Manual exercise:

- Select an unlocked scenario, click `Practice`, finish it, and confirm the campaign completed/unlocked scenario lists did not change.

Open questions:

- Should locked scenarios ever be practice-playable for testing, or should practice stay limited to unlocked scenarios?

## 2026-06-04 - Lightweight content validation check

Feature worked on:

- Added a Godot-driven content validation script for scenario and campaign references.
- Added `tools/check_content.ps1` as a wrapper for running that validation from the repository root.
- The validator checks scenario ids, display names, encounters, rewards, campaign starting ids, duplicate campaign nodes, and unlock references.
- Removed the completed lightweight content validation TODO.

Godot concepts introduced:

- A command-line script can extend `SceneTree`, run project-aware `res://` loading, print results, and quit with a process code.
- `DirAccess` can scan Resource folders from inside Godot.

Game architecture concepts introduced:

- Content validation is a safety net for authored data, not a replacement for combat tests.
- Campaign unlock ids should be checked against actual scenario ids before a player discovers a broken chain.

Files touched:

- `clockwork-company/scripts/tools/content_validation_check.gd`
- `tools/check_content.ps1`
- `TODO.md`
- `GODOT_BEST_PRACTICES_AUDIT.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why validating scenario references is useful now that the campaign has four nodes.
- Why this script uses Godot loading instead of parsing `.tres` text manually.

Manual exercise:

- Run `powershell -ExecutionPolicy Bypass -File tools/check_content.ps1`, then temporarily typo one unlock id in `first_road_campaign.tres` and predict the validation error before reverting your typo.

Open questions:

- Should the validator eventually include item/loadout/unit reference checks, or stay scenario/campaign focused until content authoring expands again?

## 2026-06-04 - Timed battle-start replay event

Feature worked on:

- Added a structured `battle_start` event type.
- Moved battle-start item and ancestry effect log lines under a timed `t=000` battle-start event in combat reports.
- Kept planning stat preview compatibility by letting battle-start resolvers create their old root entry when no parent id is supplied.
- Removed the completed battle-start log TODO.

Godot concepts introduced:

- Optional function parameters can preserve existing call sites while adding a richer call path.

Game architecture concepts introduced:

- Setup summaries and timed replay events are different layers of the combat report.
- Battle-start effects are still deterministic combat rules, but grouping them under `t=000` makes their timing visible.
- Structured event schemas need explicit event types before replay/UI code can rely on them.

Files touched:

- `clockwork-company/scripts/combat/logging/combat_event_schema.gd`
- `clockwork-company/scripts/combat/logging/combat_events.gd`
- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/combat/rules/item_effect_resolver.gd`
- `clockwork-company/scripts/combat/rules/ancestry_feature_resolver.gd`
- `ARCHITECTURE.md`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why battle-start effects appear after `Combat log:` but before the first unit turn.
- Why the replay can group child lines under a parent event without changing combat outcomes.
- Why the planning stat preview still does not need a timed event.

Manual exercise:

- Run a fight and confirm the replay begins with `t=000 | Battle starts.` before the first turn.

Open questions:

- Should future battle-start roster snapshots also become structured event payloads, or is the current roster summary enough for now?

## 2026-06-04 - Small combat rule decisions

Feature worked on:

- Recorded decisions for future fully blocked hit effects, armor-buff vocabulary, and deterministic tie-breaks.
- Removed the resolved decision TODOs.

Godot concepts introduced:

- No new Godot concepts; this was a design documentation pass.

Game architecture concepts introduced:

- Future zero-damage blocks should not trigger normal hit effects unless an effect explicitly says it triggers on contact.
- Armor buffs should use base battle armor or temporary guard armor until a real status system exists.
- Roster order remains the deterministic tie-break until a visible tiebreak stat is worth the extra surface area.

Files touched:

- `DESIGN_NOTES.md`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why future zero-damage blocks are different from current minimum-1-damage hits.
- Why named armor statuses are deferred.
- Why roster order is still acceptable for deterministic ties.

Manual exercise:

- Read the new combat-rule notes in `DESIGN_NOTES.md`, then explain one future mechanic that would force revisiting each decision.

Open questions:

- What specific item or scenario would justify adding a contact-triggered hit effect?

## 2026-06-04 - Item effect tooltip support notes

Feature worked on:

- Effect tooltips now say whether the current trigger/effect pair is supported by the item resolver.
- Unsupported combinations explicitly warn that combat logs will call them out if triggered.
- Removed the completed unsupported-effect tooltip TODO.

Godot concepts introduced:

- No new Godot concepts; this reused the existing Resource tooltip builder.

Game architecture concepts introduced:

- Declarative effect data can exist before every combination has resolver behavior.
- Authoring UI should make unsupported combinations obvious before they surprise the player in combat.

Files touched:

- `clockwork-company/scripts/ui/resource_tooltip_builder.gd`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Which item trigger/effect combinations are currently supported.
- Why unsupported combinations are still allowed as readable placeholders.

Manual exercise:

- Hover an item effect Resource and explain whether its resolver note says supported or not implemented.

Open questions:

- Should the content validator eventually fail live scenario-facing items that use unsupported effect combinations?

## 2026-06-04 - Gear and project-structure deferral decisions

Feature worked on:

- Recorded that shields stay bundled into weapon/armor concepts until offhand choices create real player decisions.
- Reaffirmed that procedural items do not belong in the current learning-first prototype.
- Recorded that `project.godot` should remain nested in `clockwork-company/` during active feature work.
- Removed the resolved decision TODOs.

Godot concepts introduced:

- `project.godot` marks the project root; moving it is a project-structure migration, not a gameplay feature.

Game architecture concepts introduced:

- Avoiding a handedness system keeps gear tradeoffs understandable until content needs the extra slot model.
- Hand-authored items are better than procedural items while the combat vocabulary is still being taught.

Files touched:

- `DESIGN_NOTES.md`
- `GODOT_BEST_PRACTICES_AUDIT.md`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why shields are currently item flavor plus stat/effect data, not a separate offhand rules layer.
- Why procedural items would fight the current learning goal.
- Why the Godot project root stays nested for now.

Manual exercise:

- Pick one existing shield-like item and explain whether it is currently acting more like a weapon concept or an armor concept.

Open questions:

- What future item design would make offhand/handedness worth implementing?

## 2026-06-04 - Branching campaign representation decision

Feature worked on:

- Recorded that branching campaigns should continue using campaign node unlock id arrays for now.
- Removed the resolved branching-scenario TODO.

Godot concepts introduced:

- No new Godot concepts; this was a scenario/campaign design note.

Game architecture concepts introduced:

- A campaign node can already unlock multiple scenario ids, so the current Resource shape can represent the first simple branch.
- A separate graph format should wait until authoring with unlock arrays becomes genuinely awkward.

Files touched:

- `DESIGN_NOTES.md`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- How the current campaign node Resource can make a branch.
- Why the project is delaying a more complex campaign graph.

Manual exercise:

- Open `first_road_campaign.tres` and identify which array you would edit if `Burned Chapel` should unlock two follow-up scenarios.

Open questions:

- What UI would be needed before a multi-branch campaign feels readable instead of merely valid data?

## 2026-06-04 - Job/loadout ownership decisions

Feature worked on:

- Recorded that job unlock dependencies stay deferred until the job set is large enough to need them.
- Recorded that equipment permissions remain job-owned for now.
- Recorded that tactics continue to live on loadouts until a party/unit/encounter use case creates real duplication pressure.
- Removed the resolved ownership-decision TODOs.

Godot concepts introduced:

- No new Godot concepts; this was a data ownership decision pass.

Game architecture concepts introduced:

- Ownership should stay where the current data model is simplest and most inspectable.
- Dependencies, item requirements, and tactic relocation are extra rules surfaces that need content pressure before they pay rent.

Files touched:

- `DESIGN_NOTES.md`
- `TODO.md`
- `LEARNING_LOG.md`

What I should now be able to explain:

- Why job unlock dependencies are not useful yet.
- Why equipment forbids live on jobs right now.
- Why loadout-owned tactics still fit the prototype.

Manual exercise:

- Open one loadout Resource and explain which parts would become duplicated if a future party-level doctrine system existed.

Open questions:

- Which future feature would create the strongest reason to move tactics out of loadouts?
