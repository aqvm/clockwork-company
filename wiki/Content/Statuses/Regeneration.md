---
type: content
category: status
state: implemented
tags:
  - status
  - boon
  - healing
---

# Regeneration

**Polarity:** [[Boons|Boon]]
**State:** Implemented
**Stacking:** `Refresh`, one stack

At the start of the unit's turn, Regeneration heals 2 HP.

## Tactical Role

Regeneration is predictable sustained healing. Because it resolves through the shared healing pipeline, healing-sensitive mechanics still respond to it.

## Designed Content Links

- The designed Monk attacks an enemy and then applies Regeneration to the selected ally through a bridge action.

## Related

- [[Reconstitution]]: turn-start healing based on recent damage.
- [[Rot]]: punishes each successful Regeneration heal.
- [[Renewal]]: conditional healing tied to ailment removal.

## Sources

- `clockwork-company/resources/statuses/regeneration.tres`
- `clockwork-company/scripts/combat/rules/status_resolver.gd`
- `JOB_CONTENT_DESIGN.md`
