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

`UnitState` copies definition data at battle start and owns current HP, next action time, armor, temporary modifiers, cooldowns, statuses, counters, and other battle-local state. Runtime clone mechanics live in `UnitStateCloneHelper` so speculative combat and [[Foretell]] can copy state without mixing clone plumbing into every combat rule.

Battle-only state resets between encounters. Durable campaign state stores unit definitions/progress, loadouts, equipment, inventory, and campaign progression instead.

Developer tools follow the same split. Combat Lab selections clone catalog `UnitDefinition` resources before party editing or battle assembly, so changing a lab matchup does not mutate canonical content loaded from `resources/` or mod JSON.

Combat Lab setups are lightweight developer fixtures, not canonical authored content and not campaign saves. They live under `clockwork-company/devtools/combat_lab_setups/` as inspectable JSON that stores content ids plus lab-local overrides for unit stats, ancestry/job/features, equipment, and tactic order. Loading a setup resolves those ids through the current catalog and recreates fresh lab clones; missing ids fail with a clear validation message instead of partially applying the setup.

## Why the Split Matters

- Combat and [[Foretell]] can mutate isolated copies safely.
- Authored content remains reusable and inspectable.
- Campaign persistence does not accidentally save temporary battle effects.
- UI can display definitions and runtime snapshots without becoming simulation authority.

## Implementation

- `clockwork-company/scripts/data/`
- `clockwork-company/scripts/data/definition_clone_helper.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/combat/runtime/unit_state_clone_helper.gd`
- `clockwork-company/scripts/campaign/campaign_roster_state.gd`
- `clockwork-company/scripts/devtools/combat_lab_state.gd`
- `clockwork-company/devtools/combat_lab_setups/`
