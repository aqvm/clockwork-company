---
type: index
category: unit
state: implemented
aliases:
  - Units
  - Loadouts
  - Builds
tags:
  - unit
  - loadout
  - content
---

# Units and Builds

A `UnitDefinition` owns named identity, ancestry/body, explicit base stats, and per-job progress. A reusable `UnitLoadoutDefinition` owns current job, learned ability assignments, equipment, and ordered tactics.

This separation lets the same build archetype move between different bodies without changing combat code, while campaign units can preserve individual career progression and equipment choices.

## Current Catalog

- Named unit definitions: `clockwork-company/resources/units/`
- Reusable loadouts: `clockwork-company/resources/loadouts/`
- Reusable tactic templates: `clockwork-company/resources/tactics/`

Individual unit/loadout pages should be added only when a named character or build has enough biography, unique mechanics, or design relationships to justify independent lookup.

## Implementation

- `clockwork-company/scripts/data/unit_definition.gd`
- `clockwork-company/scripts/data/unit_loadout_definition.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/campaign/campaign_roster_state.gd`

## Related

- [[Ancestries]]
- [[Jobs]]
- [[Items and Equipment]]
- [[Tactics]]
