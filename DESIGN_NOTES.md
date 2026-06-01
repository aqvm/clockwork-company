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

Phase 3 keeps gear intentionally blunt: items are one-slot Resources with flat stat modifiers. Even this small version should show pressure, so some demo items pair an upside with a drawback, such as more armor with slower action timing or faster action timing with less armor.

Phase 4 adds triggered item effects, but keeps them deliberately narrow. An item can define one trigger, one effect type, and one amount. This is enough to make gear feel like an identity hook, while avoiding a full ability engine before tactics and jobs exist.

Current triggered item design rules:

- triggered effects must be deterministic
- triggered effects must write clear combat log lines
- triggered effects may change runtime combat state, not source definitions
- demo effects should create visible combat patterns with small numbers
- unsupported trigger/effect pairings should stay obvious rather than silently doing something surprising

Combat log structure now matters because triggers make one action contain several explainable sub-events. A parent entry should name the main combat moment, such as a unit attacking at a time. Child entries should explain what happened inside that moment, such as item triggers, final damage, armor changes, defeat, or follow-up effects.

Current combat log design rules:

- only parent action entries need visible timestamps
- child entries inherit the parent moment in the player's reading of the log
- indentation should clarify causality, not hide important outcomes
- static setup information and timed combat events should be visually separated
- the static combat conditions should be visible when the scene opens
- the combat test should wait for an explicit run click before replaying combat events
- setup should sit above replay and use only the height it needs, capped at half the visible log area
- the UI can reveal the already-generated combat events over time to make the fight easier to follow
- replay pacing should be readable rather than literal; one parent combat event per second is the current default
- manual scrolling during replay should stop forced autoscroll so the player can inspect earlier events
- live log replay is presentation-only and must not make combat rules frame-dependent or real-time
- a `RichTextLabel` is preferred for the visible log so future keyword coloration can live in the UI layer
- keyword highlighting should stay a small UI categorization pass over plain log lines, not a combat-system rewrite
- highlight category colors should be exposed as inspectable `Color` fields on a Resource so tuning can happen with Godot color pickers
- the combat test scene background should be an intentional dark neutral so highlight colors retain readable contrast
- replay text and replay visualization can coexist in the same pane, with a clear divider so readability stays primary
- a first-pass replay visualization can be reconstructed from deterministic log text if it stays explicitly presentation-only
- once replay effects expand, UI systems should consume structured combat events (`event_type` + payload) rather than parsing prose line phrasing
- structured event types should be validated at write-time so missing payload fields fail early during development
- event payloads should carry stable unit IDs in addition to display names so rename-friendly UI features remain safe
- core authoring can stay `.tres`-first for editor ergonomics while modding uses JSON packs with equivalent fields/enums
- every modding JSON file should have an adjacent options/keywords markdown so schema expectations stay explicit for non-programmer modders
- mod-pack enable/disable controls should live in UI presentation and never alter simulator rules directly; they only change which validated content packs are loaded before simulation
- cooldown visualization should map to simulation time so a unit acts when its cooldown bar reaches empty
- turn ownership should be readable at a glance through a short pulse around the acting unit
- HP changes should be reinforced with brief floating +/− value text on the affected unit
- defeated units should fade/desaturate so board state remains legible without removing unit slots
- combat simulator orchestration should stay thin; scheduling, targeting, effect resolution, and text formatting should live in dedicated scripts with clear names

### Jobs as identity

Jobs should provide:

- stat tendencies
- equipment permissions
- innate behavior
- learnable actions/passives
- reasons to develop a unit over time

Past jobs should leave residue.

Phase 6 starts jobs as a tiny readable identity layer, not a full progression system.

Current job design rules:

- each unit points to one reusable loadout Resource
- each loadout has exactly one current job
- current jobs apply small flat stat modifiers to runtime combat stats
- current jobs decide whether weapon, armor, and trinket items can be equipped
- forbidden loadout equipment is skipped and explained in the combat log
- each current job has one small job effect
- job effects are deterministic and narrow: extra attack damage, extra healing, or extra guard armor
- job effects modify `UnitState` combat outcomes, not unit or job Resource files

This is deliberately not a job tree, XP system, unlock system, visual loadout editor, or progression UI. Those can come later once the small version is understandable.

Loadouts are the current composability layer. A `UnitDefinition` stores base stats and points to a `UnitLoadoutDefinition`; the loadout stores current job, weapon, armor, trinket, and tactics. This lets the same build archetype move between units with different base bodies without changing combat code.

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

Armor reduction should stay readable when temporary armor exists. Base battle armor cannot go below zero. Effects such as Shortblade reduce base armor first; if a target has no base armor left, the same reduction can reduce temporary guard armor instead.

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
