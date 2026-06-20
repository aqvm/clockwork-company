---
type: index
category: status
state: implemented
aliases:
  - Status Catalog
tags:
  - status
  - design-reference
---

# Statuses

Statuses are battle-local effects. Positive statuses are [[Boons]] and negative statuses are [[Ailments]].

## Ailments

- [[Bleed]]: action-frequency damage that persists until removed.
- [[Burning]]: action-frequency damage that decays, but punishes support.
- [[Confusion]]: skips the first otherwise-valid tactic each turn.
- [[Frost]]: amplifies and is consumed by the next physical hit.
- [[Numb]]: prevents reactions.
- [[Rot]]: turns received healing into battle-long maximum-HP loss.

## Boons

- [[Reconstitution]]: restores a share of recently received damage.
- [[Regeneration]]: heals at turn start.
- [[Renewal]]: heals when an ailment is removed.
- [[Ward]]: consumes a stack to prevent an incoming ailment.

## Shared Rules

- Status duration belongs to the application source. Applications default to three affected owner turns, can author another finite duration, or can be permanent.
- `Ignore` rejects reapplication, `Refresh` keeps one stack and the longer duration, and `Intensify` adds stacks while keeping the longer duration.
- Statuses reset between fights and scenarios.
- Status application and removal use the deterministic combat request/fact pipeline.

## Undeveloped Directions

[[Potential Future Statuses]] collates discussed but unimplemented ideas, including Shock, Doom, armor corrosion, silence-like skill disruption, and panic-based targeting changes. These are design candidates, not committed mechanics.

## Sources

- `clockwork-company/resources/statuses/`
- `clockwork-company/scripts/data/status_definition.gd`
- `clockwork-company/scripts/combat/rules/status_resolver.gd`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- `DESIGN_NOTES.md`
- `JOB_CONTENT_DESIGN.md`
