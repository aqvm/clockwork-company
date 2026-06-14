---
type: content
category: status
state: implemented
aliases:
  - Bleeding
tags:
  - status
  - ailment
  - damage
  - action
---

# Bleed

**Polarity:** [[Ailments|Ailment]]
**State:** Implemented
**Stacking:** `Intensify`, maximum 5 stacks
**Natural expiry:** No

After the afflicted unit completes an action, it takes 1 damage per stack. Bleed remains until explicitly removed.

## Tactical Role

Bleed punishes units that act frequently and creates a readable reason to value ailment removal. Unlike [[Burning]], it does not consume itself after dealing damage.

## Designed Content Links

- The designed Cryomancer bridge action `Cold Blood` converts an enemy's [[Frost]] stacks into Bleed.
- The designed Sanguinist applies Bleed to both an enemy and itself, then uses Bleed as a targeting and payoff hook.
- Bleed damage qualifies for `Ailment Damaged` effects when it causes positive HP loss.

## Related

- [[Burning]]: another action-completion damage ailment, but it decays and punishes support.
- [[Renewal]]: rewards removing Bleed.
- [[Ward]]: can prevent Bleed from applying.

## Sources

- `clockwork-company/resources/statuses/bleed.tres`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- `JOB_CONTENT_DESIGN.md`
