---
type: content
category: status
state: implemented
tags:
  - status
  - ailment
  - healing
  - max-hp
---

# Rot

**Polarity:** [[Ailments|Ailment]]
**State:** Implemented
**Stacking:** `Intensify`, maximum 5 stacks
**Natural expiry:** No

Whenever the afflicted unit receives positive healing, it loses 1 maximum HP per stack for the rest of the battle. Current HP is clamped to the new maximum.

Rot counts as `Ailment Damaged` only when its maximum-HP reduction also lowers current HP.

## Tactical Role

Rot punishes healing without simply preventing it. It creates a choice between immediate recovery and permanent battle-long durability loss.

## Designed Content Links

- The designed Bog Priest applies Rot when interfering with enemy healing and can later consume enemy Rot for a payoff.
- The designed Sanguinist can benefit when Rot causes actual HP loss.

## Related

- [[Burning]]: makes supporting an afflicted unit costly in timeline terms.
- [[Renewal]]: heals when Rot is removed.
- [[Ward]]: can prevent Rot from applying.

## Sources

- `clockwork-company/resources/statuses/rot.tres`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- `JOB_CONTENT_DESIGN.md`
