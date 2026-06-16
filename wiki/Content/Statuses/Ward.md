---
type: content
category: status
state: implemented
tags:
  - status
  - boon
  - protection
---

# Ward

**Polarity:** [[Boons|Boon]]
**State:** Implemented
**Stacking:** `Intensify`, maximum 3 stacks
**Natural expiry:** No

Ward consumes one stack to prevent the next incoming [[Ailments|ailment]] from applying. Consuming the final stack removes Ward.

Job reactions that replace or prevent a requested status resolve before Ward, so Ward is spent only if an ailment request is still unprevented.

## Tactical Role

Ward is proactive status protection. Its stack count creates a visible budget that attackers can pressure with repeated ailment applications.

## Built and Designed Content Links

- The built Spellsword feature `Ward Flare` is named around Ward, but does not currently apply the Ward status.
- Designed ailment-replacement reactions can protect Ward charges by resolving before Ward.

## Related

- [[Renewal]]: rewards ailment removal, while Ward prevents application and therefore does not trigger Renewal.
- [[Numb]], [[Confusion]], [[Bleed]], [[Burning]], [[Frost]], and [[Rot]] can all be prevented by Ward.

## Sources

- `clockwork-company/resources/statuses/ward.tres`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
