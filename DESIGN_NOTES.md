# Design Notes

## Thesis

This is a party-based autobattler where buildcraft becomes biography.

The player should not merely optimize "a tank" or "a DPS." The player should remember individual units as characters shaped by ancestry/body, aptitudes, jobs, gear, tactics, and combat history.

## Core design pillars

### Buildcraft as biography

A unit should feel like a little career:

Example:
Roger begins as a high-Int mage, finds a sword that scales from Int, trains as a warrior to use it, becomes a fragile melee spellsword, and relies on allies for protection.

### Discrete-event combat

Combat uses an FFT-like clock idea:

- each unit acts according to timing
- speed/action interval matters
- actions resolve one at a time
- combat remains readable through logs

### Gear as pressure

Gear should create tradeoffs and pivots:

- hard-hitting but slow
- fragile but fast
- defensive but low tempo
- supports a job pivot
- enables a hybrid

Avoid pure "number goes up forever" design.

Phase 3 kept gear intentionally blunt: items were one-slot Resources with flat stat modifiers. The current gear model still values clear tradeoffs, but it now has weapon, armor, helmet, and trinket slots, with shields represented as bundled weapon/armor concepts until offhand rules are worth the extra system weight.

Shields should remain bundled into weapon or armor item concepts for now. A true offhand/handedness system should wait until there are actual two-hand, dual-wield, shield-skill, or slot-capacity decisions for the player to make.

Phase 4 adds triggered item effects, but keeps them deliberately narrow. An item can define one trigger, one effect type, and one amount. This is enough to make gear feel like an identity hook, while avoiding a full ability engine before tactics and jobs exist.

Current triggered item design rules:

- triggered effects must be deterministic
- triggered effects must write clear combat log lines
- triggered effects may change runtime combat state, not source definitions
- demo effects should create visible combat patterns with small numbers
- unsupported trigger/effect pairings should stay obvious rather than silently doing something surprising
- new item behavior should prefer declarative `EffectDefinition` Resources over one-off code paths
- tags are freeform authoring hooks for future filtering and conditions, not a full attribute system yet
- reserved effect vocabulary is allowed when it clarifies the design direction, but unimplemented combinations must be documented plainly

Combat log structure now matters because triggers make one action contain several explainable sub-events. A parent entry should name the main combat moment, such as a unit attacking at a time. Child entries should explain what happened inside that moment, such as item triggers, final damage, armor changes, defeat, or follow-up effects.

Current combat log design rules:

- only parent action entries need visible timestamps
- child entries inherit the parent moment in the player's reading of the log
- indentation should clarify causality, not hide important outcomes
- scenario/party planning information, static fight setup information, and timed combat events should be visually separated
- scenario list buttons select scenarios for inspection; a separate main action starts the selected available scenario
- the scene should open on scenario planning data, not a precomputed combat report
- top-row run/debug/reward controls should render in a small panel component, while campaign and run-state decisions stay in the main scene coordinator
- old run-harness controls should stay available behind a small Debug toggle until the fallback path is intentionally retired
- the old combat conditions pane should not compete with the planning UI once scenario, party, and unit details are visible
- selected-unit planning equipment should show explicit valid item choices by slot rather than hiding choices behind cycle buttons
- the combat test should wait for an explicit run click before replaying combat events
- setup should sit above replay and use only the height it needs, capped at half the visible log area
- the UI can reveal the already-generated combat events over time to make the fight easier to follow
- replay pacing should be readable rather than literal; one parent combat event per second is the current default
- manual scrolling during replay should stop forced autoscroll so the player can inspect earlier events
- live log replay is presentation-only and must not make combat rules frame-dependent or real-time
- replay should reveal only combat events, not static setup/context lines
- visible game Resources should be hoverable and explain themselves through immediate custom tooltips
- tooltip content should be centralized by Resource type so later locked/nested tooltips do not require rewriting every UI panel
- a `RichTextLabel` is preferred for the visible log so future keyword coloration can live in the UI layer
- keyword highlighting should stay a small UI categorization pass over plain log lines, not a combat-system rewrite
- highlight category colors should be exposed as inspectable `Color` fields on a Resource so tuning can happen with Godot color pickers
- highlighting should remain whole-line for now; phrase-level emphasis can wait until category colors make important values harder to scan
- the combat test scene background should be an intentional dark neutral so highlight colors retain readable contrast
- background color should stay fixed while highlight palettes are still being tuned; expose background and palette choices together only when the project has real theme presets instead of one-off color toggles
- replay text and replay visualization can coexist in the same pane, with a clear divider so readability stays primary
- replay visualization should prefer simulator-authored unit snapshots for authoritative unit state, while structured events remain useful for grouping text and triggering lightweight visual emphasis
- once replay effects expand, UI systems should consume structured combat events (`event_type` + payload) rather than parsing prose line phrasing
- structured event types should be validated at write-time so missing payload fields fail early during development
- event payloads should carry stable unit IDs in addition to display names so rename-friendly UI features remain safe
- core authoring can stay `.tres`-first for editor ergonomics while modding uses JSON packs with equivalent fields/enums
- every modding JSON file should have an adjacent options/keywords markdown so schema expectations stay explicit for non-programmer modders
- mod-pack enable/disable controls should live in UI presentation and never alter simulator rules directly; they only change which validated content packs are loaded before simulation
- cooldown visualization should map to simulation time so a unit acts when its cooldown bar reaches empty
- ready units should be explicitly labeled once their cooldown reaches empty so timing is readable at a glance
- turn ownership should be readable at a glance through a short pulse around the acting unit
- HP changes should be reinforced with brief floating +/− value text on the affected unit
- defeated units should fade/desaturate and show a clear defeated overlay so board state remains legible without removing unit slots
- combat simulator orchestration should stay thin; scheduling, targeting, effect resolution, and text formatting should live in dedicated scripts with clear names

### Jobs as identity

Jobs should provide:

- stat tendencies
- optional equipment restrictions
- innate behavior
- learnable actions/passives
- reasons to develop a unit over time

Past jobs should leave residue.

Phase 6 starts jobs as a tiny readable identity layer, not a full progression system.

Current job design rules:

- each unit points to one reusable loadout Resource
- each loadout has exactly one current job
- current jobs define small per-level growth biases instead of applying their old flat stat modifiers directly
- equipment is allowed by default; a job can explicitly forbid weapon, armor, helmet, or trinket slots for special identities
- forbidden loadout equipment is skipped and explained in the combat log
- each current job grants one skill, one passive, one reaction, and one default tactic
- each loadout can override the current job's skill, passive, or reaction to model learned abilities before full progression exists
- a skill is an active combat action that tactics can select through `Job Skill`
- a passive is a deterministic combat hook with an optional unit-turn cooldown
- a reaction is a conditional response with an optional unit-turn cooldown
- job abilities modify `UnitState` combat outcomes, not unit or job Resource files

This is deliberately not a job tree, XP system, unlock system, visual loadout editor, or progression UI. Those can come later once the small version is understandable.

Current loadout-level equipped ability slots are the first small version of learned job history. Future job progression can replace manual loadout overrides with unlock rules, but the combat simulator already sees the intended shape: current job frame plus equipped skill/passive/reaction.

Current job leveling rules:

- each unit can gain at most five total job levels across all jobs
- winning a fight currently grants each ally one level's worth of XP in their current job
- job levels are per unit and per job, not one global unit level
- job levels permanently apply that job's growth spread to runtime stats
- unlocks are currently predetermined tracks: skill, passive, and reaction unlock at configured job levels
- `pending_unlock_choice` exists as scaffolding for future player choice, but this pass auto-unlocks by track
- job unlock dependency trees are intentionally deferred; do not add dependencies until there are enough jobs that dependency rules clarify choices instead of obscuring them

Current job growth rules:

- growth uses small integers and should be roughly point-buy balanced
- `max_hp_growth`, `physical_damage_growth`, `magic_damage_growth`, and `armor_growth` are positive durability/offense axes
- `action_interval_growth` uses the simulator's native stat: negative means faster, positive means slower
- no job should dominate both speed and every damage/defense axis without paying somewhere else

Damage is now split into physical and magic damage. A damage source with the `magic` tag uses magic damage; otherwise it uses physical damage. Physical damage is reduced by armor. Magic damage currently ignores armor because there is no magic resistance stat yet.

Loadouts are the current composability layer. A `UnitDefinition` stores ancestry, base stats, and a pointer to a `UnitLoadoutDefinition`; the loadout stores current job, weapon, armor, helmet, trinket, and tactics. This lets the same build archetype move between units with different base bodies without changing combat code.

Equipment permissions should remain job-owned for now. Unit-specific or item-specific requirements can wait until a concrete item, ancestry, or scenario needs them.

### Ancestry as body

Ancestry is the "who/what you are" layer, separate from jobs as the "what you trained to do" layer.

Current ancestry design rules:

- ancestry grants future base-stat generation ranges, but current units still store explicit authored stats
- ancestry grants baseline growth that applies once per total job level, then job-specific growth stacks on top
- ancestry grants one always-on feature that is active regardless of current job or learned ability loadout
- ancestry features use limited declarative triggers and cooldowns, not arbitrary scripts
- ancestry features should be strong and character-defining because they cannot be swapped like gear or jobs
- Typhon-born is explicitly scaffolded for a future two-helmet feature, but current slot-capacity rules do not implement it yet

### Tactics as authored behavior

The player does not act during combat. The player authors behavior beforehand.

Tactics should be:

- limited
- readable
- priority-ordered
- explainable through combat logs

Phase 5 starts tactics as tiny authored rules in the form `condition -> action -> target`.

Current tactic design rules:

- tactics are evaluated from top to bottom
- the first true condition with a valid target wins
- supported actions are only attack, heal, and guard
- heal is a small fixed amount so it stays predictable
- guard is temporary armor until the unit's next turn
- every selected tactic must explain itself in the combat log
- tactic Resources live in loadouts so behavior can be edited in Godot without changing simulator code
- tactics should have human-readable names because a library of behaviors needs to be recognizable in setup and combat logs, not only by filename or raw rule triplet
- tactics should continue to live on loadouts until a party-level doctrine, unit career, or encounter override creates real duplication pressure

Armor reduction should stay readable when temporary armor exists. Base battle armor cannot go below zero. Effects such as Shortblade reduce base armor first; if a target has no base armor left, the same reduction can reduce temporary guard armor instead.

Future fully-blocked hits should not trigger normal hit effects unless the effect explicitly says it triggers on contact. The current combat formula still deals at least 1 damage, so this is a future-proofing decision for possible zero-damage armor rules.

Armor-buff wording should keep using the existing split for now: base battle armor for persistent battle modifiers, temporary guard armor for guard-like short-lived protection, and named statuses only after the status system exists. Do not introduce a status label only to name armor.

Tie-breaks should continue using roster order while the project is deterministic and small. A visible speed or tiebreak stat should wait until ties become common enough that roster-order resolution feels confusing or unfair.

### Content catalog rules

The first broad content catalog is a pull-from-later library, not a promise that every Resource is already balanced for the current five-fight run loop.

Current catalog authoring rules:

- prefer memorable build hooks over linear upgrades
- write enemies as normal unit/loadout/job/item/tactic builds
- keep items declarative through `EffectDefinition` arrays
- use tags such as `armored`, `fragile`, `machine`, `support`, `swift`, and `death_backlash` as readable authoring hooks
- only rely on simulator-supported effect combinations for live content
- reserve run-loop wiring for a later focused pass
- use optional catalog encounters/rewards as staging material, not automatically reachable content
- procedural items do not belong in the current prototype; hand-authored items teach the combat vocabulary more clearly

### Short roguelite run loop

Phase 7 turns the combat test into a tiny vertical slice: five fights, reward choices between fights, and a clear win/loss endpoint.

Current run-loop design rules:

- the run loop should orchestrate battles, not change combat rules
- a run should be deterministic and inspectable while the project is still teaching its systems
- reward choices should be concrete equipment/build decisions, even if the first UI is just buttons
- a minimal inventory/equipment state should exist before a full inventory screen
- replacing equipment should return the old item to inventory so the player can reason about tradeoffs rather than losing gear silently
- reward content should reference normal item Resources rather than inventing reward-only stat blobs
- run progression should explain itself in the static summary before each fight
- both win and loss states should be easy to reach during testing
- enemy progression is authored as fixed encounter Resources, not procedural generation or adaptive difficulty
- enemies in encounters should remain normal unit/loadout/job/item/tactic builds, not a separate monster-only ruleset

### Scenario and Campaign Structure

Short handcrafted scenarios are the primary content unit. A scenario is a fixed sequence of encounters with story text, optional rule ids, rewards, tags, and unlock ids. This keeps content inspectable while leaving room for scenario-specific constraints later.

Campaigns are chains or trees of scenarios, not a base-management game. The first campaign layer tracks only available scenarios, active/completed scenarios, unlocked content ids, and campaign completion. The first sample campaign now has four linked scenarios so linear chaining past the initial three-node slice stays visible.

Branching campaigns should keep using `CampaignScenarioNodeDefinition.unlock_scenario_ids_on_completion` until that becomes hard to author. A node can already unlock more than one scenario id, so the next branch does not need a separate graph format yet.

Scenario rules should be data-first. A rule such as `ash_chapel_healing_pressure` may exist as a readable Resource before the combat simulator knows how to enforce it.

The first mechanical scenario rule is intentionally narrow: `iron_tollgate_armored_enemies` gives each enemy +2 armor during the Iron Tollgate scenario. This uses an existing combat stat, appears in run status text, and shows up in the generated roster. Do not generalize this into a broad scenario-rule DSL until at least a few different rules prove the shape is worth it.

Content unlock IDs should be visible before they become gates. The scenario list and detail panels can show whether a scenario's content IDs are unlocked or pending, but those IDs should not silently change gear, roster, or branch availability until the consuming system is designed and documented.

Campaign persistence should stay light at first: completed scenarios, unlocked content, and eventually roster/job/gear state. Do not add injury, rest, fatigue, base-building, calendars, or management-sim systems without an explicit design pass.

The first campaign save/load slice should restore only stable campaign progress: completed scenarios, unlocked scenario IDs, unlocked content IDs, and campaign completion. Active scenario runs, roster careers, inventory, gear, and job progress need their own model before being serialized.

Rotation pressure should eventually come from XP caps, scenario constraints, enemy mechanics, content unlocks, and optional mastery goals rather than punishment systems.

### Tooltip input

Tooltips use a pinned mode for deliberate inspection: hover opens the tooltip, left click pins the currently visible tooltip, and Escape, the pinned Close button, or clicking outside the pinned tooltip closes it. This keeps normal hover inspection fast while giving longer Resource text somewhere stable to sit.

Nested tooltip traversal now uses pinned Resource tooltips: pin a Resource tooltip, then choose related Resources such as loadout, job, gear, tactic, encounter, rule, or reward links inside the same presenter. This keeps normal hover fast while making deeper inspection deliberate. It should not force the whole UI to use native Godot tooltip strings, because the custom presenter is the path for locked/nested game-data inspection.

### Enemy doctrine later

Higher difficulties may eventually let enemies infer and exploit player doctrine:

- healer dependency
- tank-wall dependency
- single-carry dependency
- predictable targeting
- lack of interrupts
- lack of cleanse
- backline fragility

This must feel like scouting, not cheating.

## Initial scope discipline

The first playable prototype should be embarrassing and tiny.

Initial target:

- 3 allied units
- 3 enemies
- one button to run combat
- readable combat log
- no animation
- no procedural generation
- no full job system
- no full tactics system

## Design risks

### Risk: Vibe-coded architecture

If AI writes too much code too quickly, I will not understand the project.

Mitigation:

- small patches
- explanations
- manual exercises
- learning log

### Risk: Invisible complexity

If combat cannot explain itself, tactics and gear will feel random.

Mitigation:

- combat log first
- deterministic simulation
- visible action order

### Risk: Fake choice

Mandatory stats can consume build expression.

Mitigation:

- identify whether a stat is baseline, tradeoff, or identity
- avoid letting one system carry all mandatory survivability/offense

### Risk: Adaptive difficulty feels unfair

Later enemy adaptation must be communicated through scouting reports and encounter flavor.

Mitigation:

- bounded enemy archetypes
- visible scout reads
- counterplay, not automatic negation
