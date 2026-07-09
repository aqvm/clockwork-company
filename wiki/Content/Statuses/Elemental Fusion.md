---
type: content
category: status
state: implemented
aliases:
  - Composite Elemental Ailment
tags:
  - status
  - ailment
  - magic
  - elemental
---

# Elemental Fusion

Elemental Fusion is an authorable composite ailment that shares one stack pool
across [[Burning]], [[Frost]], and [[Shock]] behavior.

**Polarity:** [[Ailments|Ailment]]
**State:** Implemented
**Stacking:** Uncapped `Intensify`
**Natural expiry:** No

Each stack participates in all three rules:

- After the afflicted unit completes an action, it takes 1 magic damage per
  stack and consumes one stack, like Burning.
- Incoming magic damage can propagate 25%, rounded down, to at most three
  deterministic allied targets and consumes one stack, like Shock.
- Incoming physical damage gains 20% post-armor damage per stack, rounded up,
  and then removes Elemental Fusion, like Frost.

When ordinary Frost and Elemental Fusion coexist, each adds its own physical
amplification from the same pre-amplification physical amount. When ordinary
Shock and Elemental Fusion coexist, each can discharge and consumes its own
stack.

## Authoring

`Fuse Elemental Ailments` removes all Burning, Shock, and Frost from its target,
totals their stacks, divides by the effect's `amount_divisor`, rounds up, and
applies that many stacks of its referenced Elemental Fusion status. A divisor
of 3 is the intended starting recipe.

## Sources

- `clockwork-company/resources/statuses/elemental_fusion.tres`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- `clockwork-company/scripts/combat/rules/triggered_effect_resolver.gd`
