---
type: index
category: item
state: implemented
aliases:
  - Gear
  - Equipment
tags:
  - item
  - equipment
  - content
---

# Items and Equipment

Gear is the primary between-scenario buildcraft lever. It should create tradeoffs, pivots, and identity hooks rather than only increasing numbers.

## Current Model

- Slots are weapon, armor, helmet, and trinket.
- Shields remain bundled into weapon or armor concepts.
- Items can modify HP, physical damage, magic damage, armor, and action speed.
- Items can carry declarative triggered effects.
- Equipment is allowed unless the current job or immutable ancestry explicitly forbids its slot.
- Campaign-owned gear is freely swappable between scenarios and locked during an active scenario.

The current catalog contains many straightforward assets. Individual wiki pages should be created only for items with substantial unique mechanic/design lookup value.

## Implementation

- `clockwork-company/resources/items/`
- `clockwork-company/scripts/data/item_definition.gd`
- `clockwork-company/scripts/combat/rules/item_effect_resolver.gd`
- `clockwork-company/scripts/campaign/campaign_roster_state.gd`

## Related

- [[Damage and Armor]]
- [[Jobs and Progression]]
- [[Content Authoring]]
