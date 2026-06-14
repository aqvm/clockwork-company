---
type: content
category: status
state: implemented
tags:
  - status
  - ailment
  - physical
  - setup
---

# Frost

**Polarity:** [[Ailments|Ailment]]
**State:** Implemented
**Stacking:** Uncapped `Intensify`

The next physical damage request against the afflicted unit deals 20% more post-armor physical damage per stack, rounded up. Frost is removed after that modified physical damage resolves.

Magic damage does not benefit from or consume Frost.

## Tactical Role

Frost is a setup/payoff ailment that rewards coordinating status application with a later physical hit.

## Designed Content Links

- The designed Cryomancer applies Frost, slows enemies based on total enemy Frost, and converts Frost into [[Bleed]].
- The designed Enthalpyst applies and reflects Frost, then uses a threshold reaction to trigger and shatter large Frost stacks.

## Related

- [[Numb]]: paired with Frost in the designed Cryomancer kit.
- [[Burning]]: paired with Frost in the designed Enthalpyst kit.
- [[Ward]]: can prevent Frost from applying.

## Sources

- `clockwork-company/resources/statuses/frost.tres`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- `JOB_CONTENT_DESIGN.md`
