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

- One allied `template_` unit per implemented draft job: `clockwork-company/resources/units/`
- Matching equipment-free `template_` loadouts: `clockwork-company/resources/loadouts/`
- Minimal `sparring_` enemies for preserved encounters: `clockwork-company/resources/units/`
- Standalone reusable tactic templates are currently empty; job default tactics are embedded in job Resources.

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
