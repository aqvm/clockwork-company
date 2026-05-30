# Architecture

## Project purpose

This is a systems testbed for a small party-based roguelite autobattler. The priority is understandable mechanics and fast iteration, not polish.

The current Godot project lives in `clockwork-company/`, where `project.godot` defines the Godot project root.

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
- item definitions
- job definitions eventually
- tactics definitions eventually
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
- `UnitState`: this specific Warrior right now, with current HP and next action time.

### UI / presentation

Responsible for:

- buttons
- combat log display
- reward choices eventually
- party/equipment screens eventually

Should not own combat rules.

### Run flow

Responsible for:

- fight sequence
- reward selection
- inventory/equipment between fights
- run start/end conditions

## Initial combat model

Use a discrete-event model:

- Each unit has an action interval.
- Each unit has a next action time.
- The simulator advances to the next ready unit.
- That unit performs an action.
- The unit schedules its next action.
- Combat ends when one side is dead.

Initial stats:

- max HP
- current HP
- damage
- armor
- action interval
- targeting rule

Initial damage formula:

`damage_taken = max(1, attacker.damage - defender.armor)`

This is intentionally crude and replaceable.

## Current Phase 1 implementation

The first playable test is a text-only combat scene:

- `clockwork-company/scenes/combat_test_scene.tscn` owns the visible test scene.
- `clockwork-company/scripts/ui/combat_test_scene.gd` owns the button and combat log display.
- `clockwork-company/scripts/combat/combat_simulator.gd` owns the combat rules.

The scene is set as the main scene in `clockwork-company/project.godot`, so pressing Play in Godot should open the combat test.

Current combat rules:

- the fight is hardcoded as 3 allies against 3 enemies
- every unit starts with `next_action_time = action_interval`
- the living unit with the lowest `next_action_time` acts next
- ties use roster order, which keeps the result deterministic
- every action attacks the frontmost living enemy
- damage uses `max(1, attacker.damage - defender.armor)`
- defeated units stop acting
- the fight ends when one side has no living units

The simulator currently has no random rolls. A future version can introduce seeded randomness, but Phase 1 stays deterministic by construction.

Manual test:

- Open the Godot project in `clockwork-company/`.
- Press Play.
- Click `Run Hardcoded 3v3 Fight`.
- Confirm the text log shows the roster, action times, damage, defeats, and final result.

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
