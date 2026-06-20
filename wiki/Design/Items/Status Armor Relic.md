---
type: design
category: item
state: designed
tags: [item, armor, status]
---
# Status Armor Relic

Every different status effect on the wearer grants +1 armor.

## Intended Behavior

- Count unique status types on the wearer, not stacks.
- Both boons and ailments can count unless later tuning makes ailments-only cleaner.
- The armor bonus should update as statuses are applied, removed, transferred, consumed, or expired.

This is item-shaped because it turns messy status state into a defensive conversion engine. It rewards broad status interaction without becoming a job's core status kit.

## Promising Job Synergies

- [[Sanguinist]] deliberately accepts ailments, making the item a stabilizer for self-harm and ailment fuel.
- [[Monk]] can use status-transfer play to collect, shed, or redistribute the statuses that feed the armor.
- [[Bard]] can make broad boon and ailment layering into a team plan rather than a pile of incidental statuses.

## Open Questions

- Decide whether permanent statuses, battle-long auras, and dynamic stat modifiers count.
- Decide whether the bonus is normal armor, battle armor, or a separate dynamic modifier.
