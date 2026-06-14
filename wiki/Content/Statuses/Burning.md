---
type: content
category: status
state: implemented
aliases:
  - Burn
tags:
  - status
  - ailment
  - damage
  - action
---

# Burning

**Polarity:** [[Ailments|Ailment]]
**State:** Implemented
**Stacking:** Uncapped `Intensify`
**Natural expiry:** No

After the afflicted unit completes an action, it takes 1 damage per stack and loses one stack. Healing or granting armor to the unit Scorches the supporter, delaying that supporter's next action by 2 time per Burning stack.

Scorched is a named consequence, not a separate [[Statuses|status]].

## Tactical Role

Burning pressures both the afflicted unit and anyone trying to support it. It decays through actions, unlike persistent [[Bleed]].

## Designed Content Links

- The designed Pyromancer builds persistent Burning pressure and can turn an incoming ailment into more Burning on its source.
- The designed Enthalpyst applies, reflects, and gathers Burning alongside [[Frost]].
- Burning damage qualifies for `Ailment Damaged` effects when it causes positive HP loss.

## Related

- [[Bleed]]: persistent action-completion damage without the support cost.
- [[Rot]]: another ailment that makes healing dangerous.
- [[Ward]]: can prevent Burning from applying.

## Sources

- `clockwork-company/resources/statuses/burning.tres`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- `JOB_CONTENT_DESIGN.md`
