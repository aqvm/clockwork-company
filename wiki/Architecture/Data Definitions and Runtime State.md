---
type: architecture
state: implemented
aliases:
  - Definitions and Runtime State
tags:
  - architecture
  - data
---

# Data Definitions and Runtime State

Authored definitions describe reusable content; runtime state describes one mutable combat instance.

## Definitions

Godot Resources define units, ancestries, loadouts, jobs, items, tactics, statuses, encounters, scenarios, campaigns, and related effects. They should remain inspectable and should not be mutated by combat.

Primary location: `clockwork-company/resources/`

Definition scripts: `clockwork-company/scripts/data/`

## Runtime State

`UnitState` copies definition data at battle start and owns current HP, next action time, armor, temporary modifiers, cooldowns, statuses, counters, and other battle-local state.

Battle-only state resets between encounters. Durable campaign state stores unit definitions/progress, loadouts, equipment, inventory, and campaign progression instead.

## Why the Split Matters

- Combat and [[Foretell]] can mutate isolated copies safely.
- Authored content remains reusable and inspectable.
- Campaign persistence does not accidentally save temporary battle effects.
- UI can display definitions and runtime snapshots without becoming simulation authority.

## Implementation

- `clockwork-company/scripts/data/`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/campaign/campaign_roster_state.gd`
