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
- the UI can still display plain text until a richer combat log viewer is worth building

### Jobs as identity

Jobs should provide:

- stat tendencies
- equipment permissions
- innate behavior
- learnable actions/passives
- reasons to develop a unit over time

Past jobs should leave residue.

### Tactics as authored behavior

The player does not act during combat. The player authors behavior beforehand.

Tactics should be:

- limited
- readable
- priority-ordered
- explainable through combat logs

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
