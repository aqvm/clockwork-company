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

Gear is the primary between-scenario buildcraft lever. It should create tradeoffs, pivots, and identity hooks rather than only increasing numbers. The intended long-term direction is that notable items are build-warping artifacts: portable rules exceptions that create emergent synergy with jobs, tactics, statuses, scenario pressure, and party composition.

## Current Model

- Slots are weapon, armor, helmet, and trinket.
- Shields remain bundled into weapon or armor concepts.
- Items can modify HP, physical damage, magic damage, armor, and action speed.
- Items can carry declarative triggered effects.
- Equipment is allowed unless the current job or immutable ancestry explicitly forbids its slot.
- Campaign-owned gear is freely swappable between scenarios and locked during an active scenario.

The current catalog contains many straightforward assets. Individual wiki pages should be created only for items with substantial unique mechanic/design lookup value.

## Designed Direction

- [[Item Design Philosophy]] owns the durable boundary between item design and job design.
- Designed-but-unimplemented item concepts currently include [[Broken Locket]], [[Status Armor Relic]], [[Third-Attack Nova Relic]], [[Ailment Theft Relic]], [[Armor Retaliation Relic]], [[Magical Skill Status Intensifier]], [[Battle-Start Energy Shield Relic]], and [[Martyr Speed Relic]].

## Implementation

- `clockwork-company/resources/items/`
- `clockwork-company/scripts/data/item_definition.gd`
- `clockwork-company/scripts/combat/rules/item_effect_resolver.gd`
- `clockwork-company/scripts/campaign/campaign_roster_state.gd`

## Related

- [[Damage and Armor]]
- [[Jobs and Progression]]
- [[Content Authoring]]
