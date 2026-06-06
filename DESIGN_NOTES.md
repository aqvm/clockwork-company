# Design Notes

## Thesis

This is a party-based autobattler where buildcraft becomes biography.

The player should not merely optimize "a tank" or "a DPS." The player should remember individual units as characters shaped by ancestry/body, aptitudes, jobs, gear, tactics, and combat history.

A unit biography should eventually surface persistent history: stats, jobs trained, job features unlocked, scars acquired, bosses defeated, notable scenario clears, tactics used, and other facts that explain how the unit became who they are. Gear is part of buildcraft but should not dominate biography tracking because gear is intentionally swappable between units.

Because biography matters beyond a single run, the game should eventually support a profile-level mythos or legacy feature. The player should be able to flag MVP units for preservation and later display outside the current campaign, inspired by the way Wyldermyth lets memorable characters outlive one story.

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
- automatic export from base `.tres` content to reference JSON should wait until the schema is calmer; for now, hand-authored reference JSON is a better teaching/modding artifact and is validated through the loader
- every modding JSON file should have an adjacent options/keywords markdown so schema expectations stay explicit for non-programmer modders
- mod-pack enable/disable controls should live in UI presentation and never alter simulator rules directly; they only change which validated content packs are loaded before simulation
- cooldown visualization should map to simulation time so a unit acts when its cooldown bar reaches empty
- cooldown shimmer can be a small presentation cue on the existing cooldown bar; it should not imply a separate haste/status system
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
- equipment is allowed by default; the current job or immutable ancestry can explicitly forbid weapon, armor, helmet, or trinket slots for special identities
- changing jobs automatically returns newly illegal equipped items to campaign inventory
- forbidden loadout equipment is skipped and explained in the combat log
- each current job defines one skill, one passive, one reaction, and one default tactic, but only unlocked/assigned features function in combat
- each loadout stores one cross-job assigned skill plus one assigned learned passive and reaction
- a skill is an active combat action that tactics can select through `Job Skill` or `Assigned Skill`
- a passive is a deterministic combat hook with an optional unit-turn cooldown
- a reaction is a conditional response with an optional unit-turn cooldown
- job abilities modify `UnitState` combat outcomes, not unit or job Resource files

This is deliberately not a job tree, XP system, unlock system, visual loadout editor, or progression UI. Those can come later once the small version is understandable.

Current loadout-level equipped ability slots are the first small learned-job assignment model. Per-job progress proves which features are permanently learned, while the loadout stores the current between-scenario assignments.

Learned ability equipment preserves the current-job frame while letting past jobs leave readable residue. A unit has two possible skill channels: `Job Skill` uses the unlocked skill from the currently assigned job, while `Assigned Skill` uses one equipped learned skill unlocked from a different job. A unit can also equip one learned passive and one learned reaction from any job where it unlocked them. Planning can change jobs and assignments freely between scenarios. Changing into the assigned skill's source job clears that assigned skill slot.

The unit career model remembers current ability provenance through per-job progress. Save data stores the source job id for assigned skills, passives, and reactions, so planning menus can filter eligible cross-class skills and restore assignments.

FFT-style job unlock dependencies are a future layer, not part of the first learned ability assignment pass. The design should leave room for levels in some jobs to unlock other jobs later, but the near-term goal is only to track learned abilities, assign the allowed cross-class slots, and make that understandable in the UI.

Current job leveling rules:

- each unit can gain at most five total job levels across all jobs
- each job can gain at most three levels
- completing a campaign scenario grants one level to one surviving deployed unit tied for the lowest total unit level
- ties use a stable pseudo-random selection derived from the scenario and eligible campaign unit ids, so save/load cannot reroll the recipient
- the scenario tier prevents that scenario from advancing a unit beyond the tier
- failed scenarios, practice scenarios, knocked-out units, max-level units, and units whose current job is already level 3 are not eligible
- job levels are per unit and per job, not one global unit level
- job levels permanently apply that job's growth spread to runtime stats
- job level 1 requires a skill-versus-reaction choice before another campaign scenario can start
- job level 2 unlocks the passive
- job level 3 unlocks the unchosen skill or reaction
- unlocked features permanently remain on the unit's character sheet
- job unlock dependency trees are intentionally deferred; do not add dependencies until there are enough jobs that dependency rules clarify choices instead of obscuring them

Future player-facing job unlocks should be authored, not random. The current job scaffold is still small, with one active skill, one passive, and one reaction per job, but the unlock UI should point toward a larger authored progression shape rather than a loot-roll shape. For the first choice structure, a unit should choose between an active skill and a reaction first, then receive or choose the job passive later. When practical, an unpicked active/reaction option should remain available through further investment in that same job, so choices shape development order and unit biography without making early experimentation too punishing.

The first real progression pass should keep job content tiny and make the model durable. Build unlock tracking, player choice, learned ability equipment, persistence, and menu filtering around the current one-skill/one-passive/one-reaction scaffold before expanding jobs into larger authored ability catalogs. Once the pipeline is understandable, more job abilities should be mostly content and balance work rather than a new architecture pass.

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
- supported actions are attack, heal, guard, `Job Skill`, and `Assigned Skill`
- heal is a small fixed amount so it stays predictable
- guard is temporary armor until the unit's next turn
- every selected tactic must explain itself in the combat log
- tactic Resources live in loadouts so behavior can be edited in Godot without changing simulator code
- tactics should have human-readable names because a library of behaviors needs to be recognizable in setup and combat logs, not only by filename or raw rule triplet
- tactics should continue to live on loadouts until a party-level doctrine, unit career, or encounter override creates real duplication pressure
- campaign planning edits tactics as an ordered library: players can add/remove/reorder authored tactics, but do not construct arbitrary condition/action/target rules in the planning UI
- the current job's default tactic remains appended at combat initialization and is not part of the editable loadout list

Armor reduction should stay readable when temporary armor exists. Base battle armor cannot go below zero. Effects such as Shortblade reduce base armor first; if a target has no base armor left, the same reduction can reduce temporary guard armor instead.

Future fully-blocked hits should not trigger normal hit effects unless the effect explicitly says it triggers on contact. The current combat formula still deals at least 1 damage, so this is a future-proofing decision for possible zero-damage armor rules.

Armor-buff wording should keep using the existing split for now: base battle armor for persistent battle modifiers, temporary guard armor for guard-like short-lived protection, and named statuses only after the status system exists. Do not introduce a status label only to name armor.

Tie-breaks should continue using roster order while the project is deterministic and small. A visible speed or tiebreak stat should wait until ties become common enough that roster-order resolution feels confusing or unfair.

Future ailments should not be generic damage-over-time skins. A status should create a distinct rule pressure, tactical question, or matchup hook that the combat log can explain. Ailments can punish a unit's strengths, exploit a unit's weaknesses, or do both in different content. Good early directions include bleed that punishes faster units or future movement, confusion that makes the afflicted unit skip the first tactic it would have used, armor corrosion that changes mitigation math, silence-like effects that disrupt skill use, and panic effects that alter targeting.

The first ailment implementation should stay tiny and content-led: add one or two statuses only when a scenario, job, enemy, or item needs them. Status state should be simulator-owned, deterministic, visible in logs, and tooltip-readable. Do not build a broad status framework until several concrete ailments prove what common duration, stacking, purge, immunity, and UI rules are actually needed.

Debuff purges should eventually exist, but they should be specific tools rather than a universal, always-accessible cleanse. Purge options should create buildcraft and matchup decisions, not erase ailment pressure by default. Generic ailment resistance stats should not be part of the core model; occasional authored immunities are acceptable when they make a unit, enemy, item, or scenario identity clearer.

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

`CONTENT_HOOK_AUDIT.md` records the first project-wide mechanic authoring audit. When a mechanic becomes real content, it should remain authorable, inspectable, and respondable through the project's normal systems where relevant: tactics conditions/actions/targets, declarative item effects, job skills/passives/reactions, ancestry features, enemy builds, scenario rules, combat logs, replay snapshots, tooltips, save boundaries, content validation, and JSON sidecar docs. Watch for straggler mechanics that only work through one-off simulator branches or are not exposed cleanly to content authors.

### Short roguelite run loop

Phase 7 turns the combat test into a tiny vertical slice: five fights, reward choices between fights, and a clear win/loss endpoint.

Current run-loop design rules:

- the run loop should orchestrate battles, not change combat rules
- a run should be deterministic and inspectable while the project is still teaching its systems
- reward choices should be concrete equipment/build decisions, even if the first UI is just buttons
- scenario reward lists should offer at least a small choice where existing catalog rewards fit the scenario theme, without adding large reward pools
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

Campaign graph validation should stay simple but strict: starting scenarios and unlocked scenarios must be normal authored scenarios, must also be present as nodes in the current campaign, and every campaign node must be reachable from at least one starting scenario.

Scenario rules should be data-first. A rule such as `ash_chapel_healing_pressure` may exist as a readable Resource before the combat simulator knows how to enforce it.

The first mechanical scenario rule, `iron_tollgate_armored_enemies`, was intentionally narrow and useful as a plumbing proof, but it has now been retired as a runtime stat patch. Iron Tollgate keeps a visible rule Resource as an authoring note, while armor pressure should come from enemy builds, jobs, gear, tactics, and encounter composition. If a scenario is meant to test armor-breaking, the enemies should naturally have high-armor builds rather than receiving hidden stat patches from a rule.

Scenario rules are better suited to broad scenario-wide conditions: weather, terrain, visibility, ritual pressure, environmental hazards, or other global modifiers that affect the battlefield. A rainstorm that makes attacks less reliable is a more natural scenario rule than a rule that quietly changes one team's armor. Keep these rules visible, deterministic, and easy to explain before combat starts.

Scenario and encounter design should intentionally test specific mechanics, matchup questions, or synergy patterns. Enemy parties should be self-synergistic where possible, using normal unit/loadout/job/item/tactic/ancestry tools to demonstrate coherent buildcraft. This makes losses educational: when the player loses, they should be able to inspect the fight and learn what kind of synergy beat them.

An ideal loss teaches a buildcraft lesson. For example, a vampire coven might deal damage that also heals them, teaching the player that armor could blunt both the incoming damage and the enemy sustain. But armor should not be the mandatory answer. Other valid answers might include heavy magic burst to kill vampires before they heal, enough sustain to keep a tank alive while damage ramps, control that disrupts the coven's action pattern, or targeting rules that collapse the key healer first. A later Iron Tollgate fight can then ask whether the player brought enough armor penetration for naturally tanky enemy builds. The goal is for enemy plans to become ideas the player wants to try later, not only obstacles to clear.

Scenario questions should be pointed but not locked. Enemy stats and abilities should pose pressures through normal content, while the player's answer space remains plural: mitigation, burst damage, sustain, control, ramping damage, targeting plans, or other buildcraft routes can all be valid if they are readable and earned.

Scouting should differ between standalone scenarios and campaign play. For a first-time standalone scenario, the player should know little beyond the scenario name, story framing, and implicit theme. If a scenario is called "Raid the Vampire Lair," vampire assumptions should generally be vindicated, but the exact enemy list can remain a discovery reward. After a standalone scenario has been attempted, whether won or lost, exact encounter contents should be inspectable for future attempts.

Campaign scenarios should give more practical planning information because roster, job, and gear choices persist. The player should usually have a decent sense of at least the first fight before committing. Later fights do not need full spoilers up front, but scenarios should have strong, dominant, consistent themes across encounters so the player can reasonably infer what the rest of the scenario is likely to test.

Three encounters is the normal scenario length. This is long enough to test a committed build across multiple questions, but short enough that a bad plan can be retried without becoming a slog. Four or five encounters can appear occasionally for pacing texture, but should justify the longer commitment.

Climactic campaign bosses can break normal length and party assumptions. One model is a single huge fight with an expanded roster, letting the whole campaign biography pay off at once. Another model is an eight-to-ten-fight gauntlet for a smaller party, where the scenario asks contradictory build questions such as "can this party keep high armor while also taking enough damage to ramp over a long fight?"

Mini-bosses can appear in some longer scenarios, especially four-or-five encounter scenarios. A mini-boss should usually be an upgraded, overleveled, or overgeared normal unit with one memorable mechanic, not a separate monster-only ruleset. This keeps bosses inside the same buildcraft language the player can learn from.

Final boss design needs its own later pass. A campaign final boss should be epic enough to create tension against roughly nine developed units, but the exact structure should wait until roster persistence, multi-unit presentation, and enough content vocabulary exist to support it.

Normal deployed party size is three units. Larger parties should be rare scenario-authored exceptions, not campaign progression upgrades. Voluntary under-deployment can be allowed where practical, so a player can bring one or two units into a three-unit scenario if they want a foolish challenge, but encounter tuning should assume the authored maximum party size.

Do not add campaign unlocks that increase party size. Extra party slots would become mandatory high-priority upgrades, and variable campaign-wide party size would make encounter tuning much harder because scenarios would need to support too wide a power band.

For now, completing a campaign scenario should unlock the next authored scenario or scenarios for that campaign within the current run. This is the first concrete campaign unlock behavior and should stay understandable before content unlock IDs begin changing broader options.

Content unlock IDs should be visible before they become gates. The scenario list and detail panels can show whether a scenario's content IDs are unlocked or pending, but those IDs should not silently change gear, roster, or branch availability until the consuming system is designed and documented.

Future content unlocks should gate content complexity, not raw power. Good early unlock targets are new recruit candidates, new item or reward types entering scenario reward pools, optional scenario branches, and more complex buildcraft concepts. Avoid using unlock IDs to hide basic UI, core job rules, or strictly stronger upgrades unless a later design pass deliberately changes the philosophy.

Scenario rewards should mostly be gear choices. Gear is the primary between-scenario buildcraft lever, so rewards should usually ask the player which new tradeoff, synergy, or matchup tool they want to add to the campaign inventory. Recruit choices should happen less often, roughly every couple of scenarios when the campaign wants to widen the roster, introduce a new body/job possibility, or create future rotation decisions.

A campaign roster can grow to roughly three full deployed parties by the end, around nine units. This supports rotation pressure, matchup planning, and full-roster finale payoff without making the roster so large that individual unit biography becomes diluted.

Recruit design should change over the campaign. Early recruits can be nearly blank slates: they have ancestry/body identity, but little or no job history, so the player shapes their biography through development. Late recruits should be partially developed because there is not enough campaign time left to grow everyone from zero. They may arrive with job levels, an unlocked skill, a high-tier passive or reaction, or some other authored history hook that makes them immediately legible and useful.

Roger Spellsword is the first authored developed-recruit example using normal progression content. His `Spellsword` job owns Sparkblade, Sword Memory, and Ward Flare; his unit definition starts with that job at level 3 and its features unlocked. Shared standalone feature Resources let the job and authored loadout reference the same feature instances, so the base Resource loader can preserve equipped-feature provenance without loadout-only custom abilities.

Most campaign scenarios can stay limited to a small deployed party, currently three units, so roster and gear selection remain focused. A campaign finale can deliberately allow the entire roster, turning the final boss battle into a payoff for long-term roster development rather than another three-unit optimization puzzle.

Campaign persistence should stay light at first: completed scenarios, unlocked content, and campaign-only roster/job/gear state. Standalone scenarios remain self-contained and should not write long-term roster state. Campaign runs should carry forward anything that contributes to unit biography: named unit identity, ancestry/body, current job, job progress, learned/equipped abilities, tactics/loadout choices, equipped gear, unequipped inventory, and scenario/content unlocks.

Battle-only runtime effects should not persist after a scenario by default. Current HP damage, temporary armor, statuses, and other fight-local state reset between scenarios unless a later explicit design pass adds long-term consequences. Injury, fatigue, rest, economy, base-building, calendars, and management-sim systems remain out of scope.

Once a scenario starts, roster, gear, tactics, jobs, and learned ability assignments should be locked until that scenario ends or is retried. This preserves multi-question scenario design space: a late-game scenario can ask whether one committed party plan can handle fast ranged attackers behind a supertank and a delayed-cast magic area nuke later in the same scenario. The player solves that at the scenario-planning layer, not by retooling between every encounter.

Between encounters inside a scenario, surviving units reset to baseline combat capacity because each fight rebuilds combat runtime state from definitions. HP, temporary armor, statuses, cooldown-like battle state, and other runtime effects clear before the next fight. The deliberate exception is scenario-local knockout: a unit defeated in one fight remains unavailable for the rest of that scenario.

The first campaign defeat rule is scenario-local knockout, not long-term death. If a unit is defeated in a won fight, `RunState` omits that unit from the remaining fights in the same scenario using the unit's stable campaign instance id. After the scenario ends, the unit returns with no long-term penalty because the campaign commit path stores roster definitions, job progress, equipment, and inventory, not scenario knockout flags. This creates short-term stakes inside multi-fight scenarios without pulling injury, recovery, or replacement systems into the main campaign model.

In non-permadeath campaign mode, losing a scenario returns the player to durable campaign planning for that scenario. Job changing, learned ability assignment, and ordered tactic-list editing now exist in planning; fuller roster selection still needs its own UI/model pass. This is the natural expression of the buildcraft puzzle: a failed attempt teaches the enemy plan, then the player responds with a better plan.

Failed campaign attempts grant knowledge only. The campaign progress model now tracks attempted scenario ids separately from completed scenario ids, and the scenario list/detail UI marks attempted scenarios so the player can recognize a learned-but-not-cleared mission. Failed attempts do not call the roster commit path and do not award XP, rewards, scenario unlocks, content unlocks, or roster progression.

This retry model has a narrative risk. If campaign fiction implies irreversible events, unlimited retries can cheapen the story. Keep that concern visible for a later campaign-framing pass; do not add harsher failure consequences until the project deliberately wants them.

A future permadeath mode can exist, but it needs its own focused design pass. Permadeath would introduce replacement and catch-up problems: what happens if the player loses an MVP, whether new units need accelerated progression, whether catch-up recruits should carry a progression penalty, how to protect roster minimums, how the final full-roster battle remains viable, what warnings the UI owes the player, and whether memorialization becomes part of unit biography.

Long-term death consequences need special care because this is a biography-focused game. Character death should not be memoryholed. One promising direction is a scar system for near-death survival: units accumulate scars that alter stats, capabilities, or build incentives, probably with some negative pressure. True death could offer a blaze-of-glory moment, inspired by games like Wyldermyth: the unit expires while doing something extraordinary, helpful, and likely life-saving for the rest of the party. This needs its own design pass before implementation.

The first campaign roster persistence slice now restores stable campaign progress plus campaign-owned roster state. `CampaignRosterState` carries the starting roster by campaign unit ids, stable campaign unit instance ids, current campaign unit definitions, per-job progress, current loadout equipment, and unequipped campaign inventory. Active scenario attempts still are not saved; a run must finish successfully before `RunState` mutations become durable campaign state.

Standalone scenario practice remains self-contained. Practice starts from the current visible planning party snapshot and does not call the campaign completion or roster-commit path, so it can teach encounter contents without writing long-term campaign roster state.

Failed campaign scenario attempts grant knowledge only in the current architecture because `RunState` owns temporary fight rewards and inventory until the scenario is won, while campaign roster progression is awarded only after victory. If a later UI persists scouting reveals explicitly, that reveal state should be separate from reward/progression commits.

Roster rotation pressure should come from opportunity cost and matchup evaluation rather than punishment systems. A campaign unit may remain available long after reaching max level. Max-level units should still be legal, powerful, and sometimes the correct choice for a dangerous fight, but bringing them should waste potential XP compared with fielding units that can still grow.

The stronger long-term pressure should be matchup-based. Scenario parameters, enemy builds, rule modifiers, rewards, and gear tradeoffs should make the player ask which units are best for this fight, not which three units are globally best. If the optimal campaign habit becomes "bring the same three best units to every fight," the roster design has failed.

Do not use hard XP caps as the main rotation tool. Scenario constraints, enemy mechanics, content unlock incentives, and optional mastery goals are available later, but they should create readable buildcraft questions rather than forcing bench use through fatigue, injury, rest, calendars, or other punishment systems.

Campaign gear should be freely swappable between scenarios within normal equipment constraints. An item can remain equipped to the unit who last used it, but it is not soulbound or permanently assigned. Between scenarios, the player should be able to unequip it and equip it to another available unit if that unit's ancestry, job, slot, and item rules allow it. Equipment should be locked during active battle/scenario resolution, then become editable again once the campaign returns to planning.

Do not add a separate mastery-goals system for now. Scenario-specific constraints and encounter parameters can create implicit mastery pressure by making some roster, gear, or job choices more elegant than others. Avoid adding an extra reward checklist until ordinary scenario design fails to create enough replay or optimization pressure.

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
