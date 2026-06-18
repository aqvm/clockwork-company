---
type: design
category: item
state: designed
tags: [item, ailment, status-transfer, retaliation]
---
# Ailment Theft Relic

Enemies that damage the wearer steal one of the wearer's negative status effects.

## Intended Behavior

- When an enemy deals HP damage to the wearer, remove one ailment from the wearer and apply that ailment to the attacker.
- Selection should be deterministic when the wearer has multiple ailments.
- "Steal" means the ailment leaves the wearer; this item is not only ailment copying.

This is item-shaped because it turns accepting bad statuses into a threat. It does not grant a job's ailment kit; it makes incoming damage and carried ailments interact in a strange way.

## Promising Job Synergies

- [[Pyromancer]] can turn enemy contact and hostile ailment play into punishment, especially around [[Burning]].
- [[Sanguinist]] can self-apply [[Bleed]] and invite attackers to inherit the problem.
- [[Monk]] can combine status-transfer identity with a second route for moving harmful statuses.

## Open Questions

- Decide whether the stolen ailment preserves stacks and remaining duration exactly.
- Decide how authored immunities or prevention effects should interact with theft.
