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
- `ItemDefinition`: what a Shortblade is in general.
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

## Current Phase 4 implementation

The first playable test is a text-only combat scene:

- `clockwork-company/scenes/combat_test_scene.tscn` owns the visible test scene.
- `clockwork-company/scripts/ui/combat_test_scene.gd` owns the button and combat log display.
- `clockwork-company/scripts/combat/combat_simulator.gd` owns the combat rules.
- `CombatLog` and `CombatLogEntry` are small helper classes inside `combat_simulator.gd` that build the readable text log.
- `clockwork-company/scripts/data/unit_definition.gd` defines the editable unit data Resource type.
- `clockwork-company/scripts/data/item_definition.gd` defines the editable item data Resource type, including one optional triggered effect.
- `clockwork-company/resources/units/*.tres` stores the current demo unit definitions.
- `clockwork-company/resources/items/*.tres` stores the current demo item definitions.

The scene is set as the main scene in `clockwork-company/project.godot`, so pressing Play in Godot should open the combat test.

Current combat rules:

- the fight still uses a fixed 3 allies against 3 enemies roster
- unit stats are loaded from `UnitDefinition` Resources instead of hardcoded dictionaries
- a fixed demo equipment list gives some units one equipped `ItemDefinition`
- each item has one slot label and flat modifiers for max HP, damage, armor, and action interval
- each item can also define one simple triggered effect with a trigger, effect type, and amount
- `UnitState` copies definition data into combat-only runtime state at battle start, then applies equipped item modifiers to produce final battle stats
- battle-start item effects can further change combat-only runtime stats before the roster is printed
- every unit starts with `next_action_time = action_interval`
- the living unit with the lowest `next_action_time` acts next
- ties use roster order, which keeps the result deterministic
- every action attacks the frontmost living enemy
- base attack damage uses `max(1, attacker.damage - defender.armor)`
- attack-triggered bonus damage is added before armor reduces damage
- hit-triggered armor reduction changes the target's runtime armor for the rest of the battle
- kill and death trigger hooks exist for narrow effects, but the current demo items focus on battle-start, attack, and hit effects
- log entries can have invisible integer IDs, and child entries render indented below their parent
- child log entries do not print their own time because they explain the same parent combat moment
- defeated units stop acting
- the fight ends when one side has no living units

The simulator currently has no random rolls. A future version can introduce seeded randomness, but this early combat test stays deterministic by construction.

Combat log responsibility split:

- `CombatLogEntry` stores one invisible entry ID, optional parent ID, optional visible time, text, and child entry IDs.
- `CombatLog` owns the entry list, assigns IDs, attaches children to parents, and renders the final `Array[String]`.
- `CombatSimulator` decides what happened and whether a line is a parent event or a child explanation.
- `combat_test_scene.gd` still receives plain lines and does not know about IDs or hierarchy.

Triggered item responsibility split:

- `ItemDefinition` owns inspectable source data: trigger name, effect name, and effect amount.
- `UnitState` owns the mutable combat copy of stats that triggered effects can change.
- `CombatSimulator` owns trigger timing and effect resolution.
- The UI still only asks the simulator for a log and displays it.

Manual test:

- Open the Godot project in `clockwork-company/`.
- Press Play.
- Click `Run Triggered-Item 3v3 Fight`.
- Confirm the text log shows equipped gear, battle-start item effects, final roster stats, action times, damage, defeats, and final result.
- Confirm attack triggers, hit triggers, damage, and defeat lines appear indented below their parent attack line.
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
