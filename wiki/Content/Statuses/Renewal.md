---
type: content
category: status
state: implemented
tags:
  - status
  - boon
  - cleanse
  - healing
---

# Renewal

**Polarity:** [[Boons|Boon]]
**State:** Implemented
**Stacking:** `Intensify`, maximum 3 stacks

Whenever an [[Ailments|ailment]] is removed from this unit, Renewal heals 2 HP per stack.

## Tactical Role

Renewal turns scarce ailment removal into both control relief and recovery. It rewards cleanse-focused builds without making cleanse universally available.

## Related

- [[Ward]]: prevents ailments before they land; because no ailment is removed, Ward prevention does not trigger Renewal.
- [[Rot]]: removing Rot can trigger Renewal, and the resulting heal is not punished by that Rot because Rot has already been removed.
- [[Regeneration]] and [[Reconstitution]]: other healing boons.

## Sources

- `clockwork-company/resources/statuses/renewal.tres`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
