# Architecture

## Project purpose

This is a systems testbed for a small party-based roguelite autobattler. The priority is understandable mechanics and fast iteration, not polish.

The current Godot project lives in `clockwork-company/`, where `project.godot` defines the Godot project root.

`CONTENT_HOOK_AUDIT.md` records the current cross-system mechanic authoring and inspection coverage, including deliberate gaps that should remain focused follow-up work.

## Core layers

### Combat simulation

Responsible for:

- unit action timing
- discrete-event clock
- targeting
- damage/healing
- status effects eventually
- win/loss detection
- combat log generation

Should avoid:

- UI code
- animation code
- input handling
- scene-specific assumptions

### Data definitions

Responsible for:

- unit definitions
- ancestry definitions
- item definitions
- job definitions
- tactics definitions
- loadout definitions
- encounters

Prefer data-driven definitions where reasonable. Use Resources when they make the project more inspectable in Godot.

### Runtime state

Responsible for:

- current HP
- current action time
- temporary modifiers
- cooldowns/statuses
- combat-only state

Keep definitions and runtime state conceptually separate.

Example:

- `UnitDefinition`: what a Warrior is in general.
- `ItemDefinition`: what a Shortblade is in general.
- `UnitState`: this specific Warrior right now, with current HP and next action time.

### UI / presentation

Responsible for:

- buttons
- combat log display
- timed reveal of already-generated combat logs
- static display of combat setup information
- reward choices eventually
- party/equipment screens eventually

Should not own combat rules.

### Run flow

Responsible for:

- fight sequence
- reward selection
- inventory/equipment between fights
- run start/end conditions

### Skirmish, scenario, and campaign

The project now has three tactical content layers:

- Skirmish: one combat test or single fight, handled by `CombatSimulator` and the existing combat test scene.
- Scenario: a short handcrafted sequence of encounters, defined by `ScenarioDefinition` Resources and advanced through `RunState` plus `ScenarioRunner`.
- Campaign: a thin wrapper over scenarios, defined by `CampaignDefinition` and tracked by `CampaignManager`/`CampaignProgress`.

Scenarios own authored mission data: story text, party size, encounter Resources, data-only scenario rules, rewards, tags, and content unlock ids. Campaigns own availability and completion: which scenarios start unlocked, which scenarios have been attempted or completed, which scenarios unlock after completion, which content ids are unlocked, and whether the campaign is complete.

Scenario rules stay data-first while the rule vocabulary is still young. `RunState` no longer patches Iron Tollgate enemy armor; that scenario should express armor pressure through normal enemy definitions, jobs, gear, tactics, and encounter composition.

The scenario workbench can also start an unlocked scenario as a practice run. Practice runs use `RunState.start_scenario(...)` but do not call `CampaignManager.start_scenario(...)`, and they do not complete or unlock campaign nodes.

The campaign layer does not change combat rules. Real fights still run through `CombatSimulator`; runtime combat state still lives in combat runtime classes; between-fight roster/reward/equipment choices still live in `RunState`.

When a campaign scenario is lost, the workbench marks the scenario as attempted, clears the active campaign scenario id, and reloads the visible planning party from durable campaign roster state instead of the failed `RunState` clones. This keeps failed attempts from accidentally becoming progression state while still allowing a retry from planning.

Campaign progress can be saved to and loaded from `user://first_road_campaign_save.json` as small JSON. The save stores campaign id/version, attempted scenarios, completed scenarios, unlocked scenarios, unlocked content ids, campaign completion, and campaign roster state. Roster state currently includes the campaign's durable unit definitions, their per-job progress, their current loadout equipment, and unequipped campaign inventory items.

Campaign scenario victory awards one post-scenario job level after the successful run is committed. `CampaignRosterState` chooses one surviving deployed unit tied for the lowest total level, enforces the scenario tier plus unit/job caps, and owns permanent unlock flags. A pending level-1 skill-versus-reaction choice blocks starting another campaign scenario until planning UI resolves it; practice scenarios remain available.

Campaign planning can freely change a unit's current job and assign unlocked learned features between scenarios. Per-job progress supplies ability provenance. `Job Skill` resolves the unlocked current-job skill, while `Assigned Skill` resolves the separately equipped skill from a different learned job. Passives and reactions use their assigned learned slots. Current job and ancestry equipment restrictions are strict blacklists; changing jobs returns newly illegal gear to campaign inventory.

Campaign planning equipment options come only from the selected unit's current gear and `CampaignRosterState.inventory_items`. `CampaignRosterState` owns equip/unequip transactions so replacing an item returns the old item to inventory and planning UI snapshots cannot create gear.

Scenario-local knockout lives in `RunState`, not campaign save data. When an ally is defeated in a won fight, `RunState` records that ally's stable campaign unit id from the simulator's final replay snapshot and omits the unit from later encounters in the same active scenario. Because only completed campaign scenarios commit back to `CampaignRosterState`, knockouts create short-term scenario pressure without becoming long-term injury or death.

Intentionally not implemented here:

- active scenario-run save/load
- roster import/export outside the current campaign save
- injuries, fatigue, rest, or base management
- procedural generation
- async multiplayer or ghost snapshots
- adaptive enemy doctrine

## Initial combat model

Use a discrete-event model:

- Each unit has an action interval.
- Each unit has a next action time.
- The simulator advances to the next ready unit.
- That unit performs an action.
- The unit schedules its next action.
- Combat ends when one side is dead.

Current combat stats:

- max HP
- current HP
- physical damage
- magic damage
- armor
- action interval
- targeting rule

Current damage formula:

- physical component: `max(1, physical_damage - defender.armor)` when physical damage is present
- magic component: `magic_damage`
- total damage: `max(1, physical_component_after_armor + magic_component)`

This is intentionally crude and replaceable. There is no magic resistance stat yet.

## Current scenario workbench implementation

The first playable test now opens as a scenario workbench with the older combat replay harness below it. The planning area is now split into small child UI scenes so the main scene can coordinate state without owning every rendering detail:

- `clockwork-company/scenes/combat_test_scene.tscn` owns the visible test scene.
- `clockwork-company/scripts/ui/combat_test_scene.gd` owns campaign/run coordination, selected scenario/unit state, selected-unit planning equipment changes, static combat setup display after a fight starts, and tooltip hosting.
- `clockwork-company/scripts/ui/run_flow_controls_panel.gd` is attached to the top control row in `combat_test_scene.tscn`; it owns run button, mod button, palette/save/load buttons, a collapsed debug harness, reward buttons, continue button, and top-row equipment option button presentation, then emits request signals back to the main scene.
- The former `Combat Conditions` pane is now used as a visible `Fight Preview` area for campaign/run status and static setup text.
- `clockwork-company/scenes/planning_workbench_panel.tscn` and `scripts/ui/planning_workbench_panel.gd` own the stable planning-row layout and forward child-panel signals/tooltips to the main scene.
- `clockwork-company/scenes/scenario_list_panel.tscn` and `scripts/ui/scenario_list_panel.gd` own scenario list button rendering, campaign state labels, and emit `scenario_selected`.
- `clockwork-company/scenes/scenario_detail_panel.tscn` and `scripts/ui/scenario_detail_panel.gd` own read-only selected scenario detail rendering, scouting reports, readable campaign status text, and campaign content unlock state.
- `clockwork-company/scenes/party_panel.tscn` and `scripts/ui/party_panel.gd` own party summary button rendering and emit `unit_selected`.
- `clockwork-company/scenes/unit_detail_panel.tscn` and `scripts/ui/unit_detail_panel.gd` own read-only selected unit detail rendering, including computed planning stats.
- `clockwork-company/scenes/unit_action_panel.tscn` and `scripts/ui/unit_action_panel.gd` own selected-unit action button rendering and emit start/equipment-change request signals.
- `clockwork-company/scripts/ui/combat_replay_panel.gd` is attached to the existing replay column in `combat_test_scene.tscn`; it owns replay speed controls, replay text timing, replay log autoscroll, structured event grouping, event payload tooltips, unit replay dots, and runtime unit tooltip requests.
- `clockwork-company/scripts/ui/combat_log_rich_text_formatter.gd` owns UI-layer BBCode escaping and color highlighting for readable combat/setup lines.
- `clockwork-company/scripts/ui/planning_stat_preview.gd` builds read-only planning stat summaries from `UnitState` and battle-start resolver hooks without advancing combat turns.
- `clockwork-company/scripts/ui/resource_tooltip_builder.gd` converts known game Resources into readable tooltip text and related-Resource link data for pinned tooltip traversal.
- `clockwork-company/scripts/ui/tooltip_presenter.gd` owns the shared floating tooltip panel used by hoverable Resource rows/buttons. Hover shows tooltips, left click pins the visible tooltip, pinned Resource tooltips show related Resource buttons with Back navigation, and Escape or an outside click closes a pinned tooltip.
- `clockwork-company/scripts/ui/combat_test_scene.gd` now also owns the local mod-pack toggle UI state (checkbox dropdown), including enabled-pack persistence and preview refresh behavior.
- `clockwork-company/scripts/ui/unit_status_dot.gd` owns drawing one unit's circular replay marker, health arc, cooldown bar with shimmer, ready badge, and defeated overlay.
- `clockwork-company/scripts/combat/combat_simulator.gd` owns the combat rules.
- `clockwork-company/scripts/combat/combat_constants.gd` owns shared combat labels and numeric constants.
- `clockwork-company/scripts/combat/logging/combat_log.gd` owns hierarchical log entry storage and line rendering.
- `clockwork-company/scripts/combat/logging/combat_text_formatter.gd` owns combat summary text formatting helpers.
- `clockwork-company/scripts/combat/runtime/unit_state.gd` owns per-unit runtime combat state initialization and helpers.
- `clockwork-company/scripts/combat/runtime/turn_scheduler.gd` owns deterministic next-actor selection and action re-scheduling.
- `clockwork-company/scripts/combat/rules/targeting_rules.gd` owns team and target selection helpers.
- `clockwork-company/scripts/combat/rules/tactic_resolver.gd` owns tactic evaluation/selection decisions.
- `clockwork-company/scripts/combat/rules/job_effect_resolver.gd` owns current-job combat bonus hooks.
- `clockwork-company/scripts/combat/rules/ancestry_feature_resolver.gd` owns always-on ancestry combat hooks.
- `clockwork-company/scripts/combat/rules/item_effect_resolver.gd` owns triggered item effect resolution.
- `clockwork-company/scripts/combat/scenarios/demo_battle_factory.gd` owns current fixed demo roster construction.
- `clockwork-company/scripts/run/run_state.gd` owns short-run progression state: current fight index, active/reward/equipment/won/lost status, cloned party definitions, run inventory, fixed encounter order, and reward/equipment application.
- `clockwork-company/scripts/scenario/scenario_runner.gd` owns the current scenario progress wrapper: active scenario id, encounter index, completion, and scenario summary lines.
- `clockwork-company/scripts/campaign/campaign_manager.gd` owns campaign unlock progression: available scenarios, attempted scenarios, completed scenarios, unlocked content ids, and campaign completion.
- `clockwork-company/scripts/campaign/campaign_roster_state.gd` owns durable campaign roster state: starting roster construction from campaign unit ids, stable campaign unit instance ids, campaign-party snapshots for scenario starts, victory commits from `RunState`, campaign inventory, and roster/inventory JSON save data.
- `clockwork-company/scripts/modding/json_content_loader.gd` owns JSON pack loading/merging/validation and runtime Resource reconstruction for ancestries, items, jobs, tactics, loadouts, and units.
- Base `.tres` loadouts can author equipped learned passives/reactions/skills by referencing the same standalone feature Resource as the owning job; `JsonContentLoader` infers that job provenance before reconstructing content.
- `clockwork-company/scripts/tools/content_validation_check.gd` owns repository content sanity checks for scenarios, scenario rules, scenario rewards, campaign identity/graph reachability/starting-roster references, JSON pack loading, and required JSON sidecar docs. The loader validation it invokes also rejects equipped learned features without matching unlocked job progress.
- `CombatLog` and `CombatLogEntry` are dedicated helper classes in `scripts/combat/logging/combat_log.gd` that build readable text logs and structured event metadata.
- `scripts/combat/logging/combat_event_schema.gd` defines known event types and required payload keys as the structured logging contract.
- `scripts/combat/logging/combat_events.gd` provides typed event-construction helpers so simulator/rule code does not handcraft payload dictionaries ad hoc.
- `combat_simulator.gd` now orchestrates a battle by delegating logging, targeting, tactic selection, effect resolution, scheduling, and demo roster setup to dedicated scripts.
- `combat_simulator.gd` now also provides structured battle report APIs (`run_demo_battle_report` and `run_battle_report`) that return rendered lines, structured events, initial roster snapshots, replay unit-state snapshots, winner, and action count.
- Base game content remains authored in `.tres` Resources; the loader derives JSON-like dictionaries from those Resources, then applies mod JSON overrides from `res://mods/*.json` before constructing runtime Resources.
- Structured report payloads now include a `log_version` field for format evolution safety.
- `clockwork-company/scripts/data/unit_definition.gd` defines the editable unit data Resource type, including ancestry, base physical/magic damage, and per-job progress.
- `clockwork-company/scripts/data/ancestry_definition.gd` defines an editable ancestry Resource with future base-stat ranges, baseline growth, notes, and an always-on feature reference.
- `clockwork-company/scripts/data/ancestry_feature_definition.gd` defines the limited ancestry feature payload, including trigger, condition, feature type, amount, cooldown, and notes.
- `clockwork-company/scripts/data/item_definition.gd` defines the editable item data Resource type, including flat modifiers, tags, and authored effect references.
- `clockwork-company/scripts/data/effect_definition.gd` defines the first declarative effect payload for data-authored triggers, conditions, target selectors, amounts, limits, and tags.
- `clockwork-company/scripts/data/job_definition.gd` defines the editable job data Resource type, including per-level stat growth, optional equipment forbids, unlock levels, and skill/passive/reaction/default-tactic references.
- `clockwork-company/scripts/data/job_progress_definition.gd` defines one unit's progress in one job: level, XP, unlocked feature flags, and future choice scaffolding.
- `clockwork-company/scripts/data/skill_definition.gd` defines the limited active action payload a job can grant.
- `clockwork-company/scripts/data/passive_definition.gd` defines the limited passive combat hook a job can grant, including cooldown turns.
- `clockwork-company/scripts/data/reaction_definition.gd` defines the limited reaction hook a job can grant, including trigger, condition, and cooldown turns.
- `clockwork-company/scripts/data/unit_loadout_definition.gd` defines a reusable build package with a current job, optional equipped learned abilities, weapon, armor, helmet, trinket, and tactic list.
- `clockwork-company/scripts/data/tactic_definition.gd` defines the small tactic rule Resource type.
- `clockwork-company/scripts/data/encounter_definition.gd` defines a run encounter as a named enemy party made from normal `UnitDefinition` Resources.
- `clockwork-company/scripts/data/reward_definition.gd` defines a run reward as a named offer with a suggested recipient and a normal `ItemDefinition` payload.
- `clockwork-company/scripts/data/scenario_definition.gd` defines a handcrafted mission as story text, ordered encounter references, optional data-only scenario rules, rewards, tags, and unlock ids.
- `clockwork-company/scripts/data/scenario_rule_definition.gd` defines a named scenario rule placeholder that can exist as data before combat mechanics implement it.
- `clockwork-company/scripts/data/campaign_definition.gd` and `campaign_scenario_node_definition.gd` define a lightweight scenario chain and starting roster ids.
- `clockwork-company/resources/ancestries/*.tres` stores the current ancestry catalog.
- `clockwork-company/resources/units/*.tres` stores the current demo unit definitions and a wider catalog of future ally/enemy build bodies.
- `clockwork-company/resources/items/*.tres` stores the current demo item definitions and a wider catalog of build-enabling gear.
- `clockwork-company/resources/jobs/*.tres` stores the current demo job definitions and a wider catalog of job identities.
- `clockwork-company/resources/loadouts/*.tres` stores reusable demo and catalog build archetypes.
- `clockwork-company/resources/tactics/*.tres` stores reusable named tactic rule definitions.
- `clockwork-company/resources/encounters/*.tres` stores fixed authored encounters used by the old Phase 7 run and the new sample scenarios.
- `clockwork-company/resources/rewards/*.tres` stores reusable reward offers used by the old Phase 7 run and curated scenario reward lists.
- `clockwork-company/resources/scenarios/*.tres` stores sample scenario definitions.
- `clockwork-company/resources/scenario_rules/*.tres` stores data-only scenario rule definitions.
- `clockwork-company/resources/campaigns/first_road_campaign.tres` stores the first sample campaign.

The scene is set as the main scene in `clockwork-company/project.godot`, so pressing Play in Godot should open the scenario workbench. The simulator should not run merely because a scenario is selected; combat reports are generated when the player starts or runs a fight.

Current run-loop rules:

- a run contains exactly five deterministic fights
- the player starts with the current three ally definitions loaded through the existing `.tres`/JSON bridge
- each fight loads a fixed `EncounterDefinition`
- encounter enemies are normal `UnitDefinition` Resources with normal jobs, items, loadouts, and tactics
- reward choices are `RewardDefinition` Resources that point to normal item Resources
- winning fights 1-4 moves the run to reward choice
- choosing one reward adds that reward's item to run inventory and moves the run to equipment decisions for the next fight
- scenario run status and buttons name the next encounter so multi-fight scenarios have an explicit transition before combat starts
- equipment buttons show valid item/unit pairings based on current job equipment forbids
- equipping an inventory item replaces that unit's existing item in the matching slot and returns the replaced item to inventory
- `Continue to Next Fight` leaves the equipment state and starts the next active fight
- winning fight 5 sets the run status to won
- losing any fight sets the run status to lost
- `Start Loss Test` starts a deliberately harsh run so the loss state can be checked on demand
- reward inventory is currently a readable history of applied equipment decisions, not a separate unequipped item bag

Current combat rules:

- the fight still uses a fixed 3 allies against 3 enemies roster
- unit stats are loaded from `UnitDefinition` Resources instead of hardcoded dictionaries
- each `UnitDefinition` points to one `UnitLoadoutDefinition`
- a loadout gives a unit one current `JobDefinition`
- a loadout can assign one weapon, one armor item, one helmet, and one trinket item
- the current job decides whether each assigned item is allowed before item modifiers or triggers apply
- a loadout owns the unit's priority-ordered tactic Resource list
- each item has one slot label and flat modifiers for max HP, physical damage, magic damage, armor, and action interval
- each item can also define declarative authored effects through `Array[EffectDefinition]`
- item effects are authored through `effects: Array[EffectDefinition]`; the old top-level item `trigger`, `effect`, and `effect_amount` fields have been removed
- ancestries, items, jobs, tactics, and units can carry freeform tags for future filtering/conditions/content tools
- each job has small per-level growth values for HP, physical damage, magic damage, armor, and action interval
- each unit can gain at most five total job levels across all jobs
- job progress is stored per unit and per job, with a fixed three-level unlock schedule and a level-1 skill-versus-reaction choice
- ancestries provide baseline stat-growth values that apply once per total unit job level, in addition to the growth from the specific jobs leveled
- ancestry features are always-on deterministic hooks separate from job passives/reactions
- equipment is allowed by default; the current job or ancestry may explicitly forbid weapons, armor, helmets, or trinkets
- shields currently live inside weapon or armor item concepts; there is no offhand/handedness rules layer yet
- each current job defines one active skill, one passive, one reaction, and one default tactic; only unlocked and appropriately assigned features function
- loadouts store one cross-job assigned skill plus one assigned learned passive and reaction
- `UnitState` copies definition data into combat-only runtime state at battle start, reads ancestry and loadout data, applies ancestry baseline growth and permanent job-progress growth, appends the current job's default tactic, checks equipment forbids, then applies allowed item modifiers to produce final battle stats
- battle-start item effects can further change combat-only runtime stats before the roster is printed
- battle-start ancestry features can further change combat-only runtime stats before the roster is printed
- skipped equipment is logged and does not provide stat modifiers or triggered effects
- current job passives are deterministic combat hooks such as attack damage, healing, or guard armor bonuses
- current job reactions are deterministic damaged/low-HP hooks such as temporary armor, self-healing, or damaging the attacker
- passive and reaction cooldowns are tracked as combat-only unit-turn counters
- physical damage is reduced by armor; magic-tagged damage uses magic damage and ignores armor
- every unit starts with `next_action_time = action_interval`
- the living unit with the lowest `next_action_time` acts next
- ties use roster order, which keeps the result deterministic
- every turn evaluates that unit's loadout tactics in priority order
- each tactic is a limited `condition -> action -> target` rule
- the first tactic with a true condition and valid target is selected
- if no tactic matches, the simulator falls back to attacking the frontmost living enemy
- current supported tactic actions are attack, heal, guard, job skill, and assigned skill
- heal restores a fixed 5 HP without exceeding max HP
- guard grants 2 temporary armor until that unit's next turn
- runtime armor is split into base battle armor and temporary guard armor
- armor-reduction effects reduce base battle armor first, then temporary guard armor only if no base armor remains or the reduction has leftover
- base physical attack damage uses physical damage reduced by defender total armor
- magic-tagged attacks use magic damage and currently ignore armor
- attack-triggered bonus damage is split by effect tags: `magic` bonuses are magic damage, other bonuses are physical damage
- attack-triggered ancestry bonus damage follows the same `magic` tag split
- hit-triggered armor reduction changes the target's runtime armor for the rest of the battle
- damaged/low-HP item effects can currently heal the damaged unit or increase their max HP once/per configured limit
- kill and death trigger hooks exist for narrow effects, but the current demo items focus on battle-start, attack, and hit effects
- log entries can have invisible integer IDs, and child entries render indented below their parent
- child log entries do not print their own time because they explain the same parent combat moment
- defeated units stop acting
- the fight ends when one side has no living units

The simulator currently has no random rolls. A future version can introduce seeded randomness, but this early combat test stays deterministic by construction.

Combat log responsibility split:

- `CombatLogEntry` stores one invisible entry ID, optional parent ID, optional visible time, text, child entry IDs, and structured metadata (`event_type`, `payload`, `tags`).
- `CombatLog` owns the entry list, assigns IDs, attaches children to parents, renders `Array[String]`, and can emit structured JSON-like event dictionaries.
- `CombatLog.add_event(...)` validates event type and required payload keys against `combat_event_schema.gd` before accepting an event.
- `CombatSimulator` decides what happened and whether a line is a parent event or a child explanation.
- `combat_test_scene.gd` extracts setup/context lines for the static summary pane, while `CombatReplayPanel` owns timed combat-event presentation.
- Replay identity now prefers stable `unit_id` references from event payloads and only falls back to display names when needed.
- The combat test UI splits simulator lines at `Combat log:`. Setup, roster, loadout, gear, and tactic information appears immediately in a static `RichTextLabel`; timestamped combat events are driven in the replay pane from structured event metadata.
- Scenario selection shows authored scenario and party data without running combat. The static setup pane is populated after a fight report is generated for the active encounter.
- The planning party and unit detail panels show computed combat stats from the runtime stat initialization path before combat starts; battle-start effect changes are previewed separately without running turn simulation.
- Resource tooltips are custom UI, not Godot native `tooltip_text`, so pinned tooltips can traverse related game Resources from one presenter path.
- The replay does not start when the scene opens. The UI waits for the run button, then clears and starts `CombatReplayPanel` from the cached structured combat events.
- Battle-start item and ancestry effects are grouped under a timed `t=000` battle-start event for replay, while the static setup summary skips that event block and keeps the final roster after battle-start effects.
- The replay shows one timestamped parent combat event per second. Child explanation lines without their own timestamp appear with the most recent parent event.
- The combat test scene sizes the game window to roughly three quarters of the current monitor's usable area and stacks setup above replay in a vertical split. The setup pane is resized after each run to use the smaller of its content height or half the available log area.
- The replay and setup panes now apply UI-layer keyword highlighting to plain simulator lines by wrapping BBCode-safe text in color tags by category (timestamp, attacks, damage, healing, guard, tactics, job effects, item triggers, defeats, and result).
- The replay pane now has a left/right split: left is the existing text replay, right is a lightweight unit visualization panel separated by a vertical rule.
- The visualization panel is still presentation-only: it reads initial roster snapshots, simulator-authored replay unit-state snapshots, and structured replay events from the simulator report, then draws unit circles, health arcs, cooldown bars, and lightweight VFX without changing simulator rules.
- Structured replay events still drive text grouping, turn pulses, and floating HP changes; replay snapshots are the authoritative source for current unit HP, timing, and defeated state when present.
- Highlight colors are configured in a dedicated `CombatLogHighlightPalette` Resource so color tuning stays editor-visible and does not require editing code constants.
- The scenario workbench includes a default/colorblind highlight palette toggle using separate `CombatLogHighlightPalette` Resources.
- This is presentation only: `run_demo_battle()` still finishes the deterministic simulation before replay starts.

Triggered item responsibility split:

- `ItemDefinition` owns inspectable source data: trigger name, effect name, and effect amount.
- `UnitState` owns the mutable combat copy of stats that triggered effects can change.
- `CombatSimulator` owns trigger timing and effect resolution.
- The UI still only asks the simulator for a log and displays it.

Tactic responsibility split:

- `TacticDefinition` owns inspectable source data: a display name, one condition, one action, and one target rule.
- `UnitLoadoutDefinition` owns the source tactic list for a reusable build.
- Campaign planning can add, remove, and reorder authored tactic Resources in that loadout list; the current job's default tactic remains read-only and is appended later by `UnitState`.
- `CampaignRosterState` owns durable campaign tactic ordering and serializes stable tactic content IDs; `JsonContentLoader` reconstructs those Resources when loading a save.
- `UnitState` owns the runtime copy of that priority-ordered tactic list for this combat copy.
- `CombatSimulator` owns tactic evaluation, target validation, and action resolution.
- The current planning UI selects from an authored tactic library rather than constructing arbitrary tactic rules.
- The UI still receives plain rendered log lines and does not know how tactics are evaluated.

Job responsibility split:

- `JobDefinition` owns inspectable source data: current-job stat modifiers, optional equipment forbids, skill, passive, reaction, and default tactic.
- `UnitLoadoutDefinition` owns the source current-job assignment, optional equipped learned abilities, gear, and tactics for a reusable build.
- `UnitState` owns the runtime current job and current granted job abilities assigned to this combat copy.
- `CombatSimulator` owns equipment forbid checks, job skill action resolution, and current-job ability timing.
- Unit, item, tactic, and job definitions remain separate source data. Runtime combat combines them into one `UnitState` without rewriting any `.tres` definition.
- Authored developed recruits can carry normal `JobProgressDefinition` Resources. Roger Spellsword demonstrates a level-3 job whose shared standalone feature Resources are referenced by both the job and loadout.
- The current demo still keeps the fixed 3v3 roster list in code; jobs, gear, and tactics now live in editor-editable unit/loadout Resources.

Manual test:

- Open the Godot project in `clockwork-company/`.
- Press Play.
- Select an available scenario in the top-left scenario list.
- Inspect the scenario details and party/unit details.
- Use the selected unit's planning equipment browser to choose alternate equipment before the scenario starts.
- Click `Start Selected Scenario`, then click `Run Fight`.
- Confirm the text log shows loadouts, current jobs, job skills/passives/reactions, equipped or skipped gear, loadout tactics, battle-start item effects, final roster stats, action times, selected tactics, damage, healing or guarding, defeats, and final result.
- Confirm Sol Apprentice uses the `Apprentice Focus` loadout and that Glass Focus still triggers on attack.
- Confirm Glass Wisp uses the `Apprentice Support` loadout and that the Apprentice job's `First Aid` effect appears when that job heals.
- Confirm Iron Brute's Light-Step Boots now apply because equipment is allowed by default unless a job explicitly forbids that slot.
- Confirm selected tactics appear indented below each turn.
- Confirm attack triggers, hit triggers, damage, and defeat lines appear indented below their parent attack action.
- Edit one `.tres` file in `clockwork-company/resources/units/`, run again, and confirm the roster/log reflects that data change.
- Edit one `.tres` file in `clockwork-company/resources/items/`, run again, and confirm the equipped unit's final roster stats or triggered-effect log lines reflect that item change.

## Non-goals for early prototype

Do not build early:

- procedural item generation
- rarity tiers
- crafting
- full job tree
- full tactics programming
- animations
- multiplayer
- asynchronous multiplayer
- adaptive enemy doctrine
- large content sets
- save/load
- fancy UI
