---
type: design
category: item
state: designed
tags: [item, magic, ailment, status]
---
# Magical Skill Status Intensifier

Enemies damaged by the wearer's magical skills gain one additional stack of a negative status effect they already have.

## Intended Behavior

- Trigger only from magical skill damage caused by the wearer.
- The target must already have at least one ailment.
- Add one stack to a deterministic matching ailment on that target.

This is item-shaped because it rewards setup from jobs, allies, or prior actions. It does not apply a private status package by itself.

## Promising Job Synergies

- [[Pyromancer]] can intensify [[Burning]] through magical skill pressure.
- [[Cryomancer]] or [[Enthalpyst]] can deepen Frost/Burning style stack plans.
- [[Elementalist]], [[Chronomancer]], or [[Arcane Warden]] can become payoff pieces in a party that already applies ailments.

## Open Questions

- Decide the matching rule when the target has multiple ailments.
- Decide whether non-damaging magical effects should ever qualify.
