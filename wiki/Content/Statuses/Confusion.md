---
type: content
category: status
state: implemented
tags:
  - status
  - ailment
  - tactics
---

# Confusion

**Polarity:** [[Ailments|Ailment]]
**State:** Implemented
**Stacking:** `Refresh`, one stack

On each turn, Confusion skips the first tactic whose condition is true, action is available, and target is valid. Evaluation continues through the remaining ordered tactics, and the normal fallback attack still applies if nothing later selects.

## Tactical Role

Confusion creates a tactic-ordering puzzle. Players can plan around it by placing a sacrificial valid tactic before the action they most want to execute.

## Built Content Links

- Burned Chapel's `Ash-Choked Rites` scenario rule permanently applies Confusion to every unit for each encounter.

## Related

- [[Numb]]: disrupts reactions rather than tactic selection.
- [[Ward]]: can prevent a non-prevented Confusion application.
- [[Renewal]]: rewards removing Confusion.

## Sources

- `clockwork-company/resources/statuses/confusion.tres`
- `clockwork-company/resources/scenario_rules/ash_chapel_confusion.tres`
- `clockwork-company/scripts/combat/rules/tactic_resolver.gd`
- `DESIGN_NOTES.md`
