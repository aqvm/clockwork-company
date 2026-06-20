---
type: design
category: item
state: designed
tags: [item, damage-sharing, party-building]
---
# Broken Locket

Broken Locket always appears as two matching pieces. When two living units wear the pieces, HP damage to either wearer is split evenly between them.

## Intended Behavior

- The item exists as a paired reward, not a single standalone item.
- Both pieces must be equipped by living units for the damage split to function.
- Damage sharing should apply to HP damage after the original target's prevention has resolved.
- The split should be combat-local; it should not create permanent injury or campaign binding.

This is item-shaped because it creates a party-building problem rather than granting a trained protector ability. It asks which two units should share danger, and whether a durable unit can carry a fragile unit through pressure.

## Promising Job Synergies

- [[Guard]], [[Bellguard]], or [[Turnkey]] can turn their armor and guard tools into indirect protection for another wearer.
- [[Chirurgeon]], [[Red Scribe]], or [[Lamplighter]] can make distributed damage easier to heal efficiently.
- [[Sanguinist]] can treat shared HP loss as fuel for damage-acceptance and recovery patterns.

## Open Questions

- Decide whether odd damage rounds toward the original target, the paired wearer, or deterministic alternation.
- Decide whether damage split can trigger each wearer's damaged reactions.
