---
type: content
category: status
state: implemented
tags:
  - status
  - boon
  - healing
  - retaliatory
---

# Reconstitution

**Polarity:** [[Boons|Boon]]
**State:** Implemented
**Stacking:** `Intensify`, maximum 3 stacks

At the start of its owner's turn, Reconstitution restores a share of damage received since that unit's previous turn, rounded down:

- 1 stack: 50%
- 2 stacks: 75%
- 3 stacks: 100%

The recorded damage is then cleared. A successful heal consumes one stack; no restored HP means no stack is consumed.

## Tactical Role

Reconstitution rewards keeping a damaged unit alive until its next turn and gives opponents a reason to finish that unit before recovery resolves.

## Designed Content Links

- The designed Paladin maintains Reconstitution on the party.

## Related

- [[Regeneration]]: steady turn-start healing that does not depend on recent damage.
- [[Rot]]: can punish Reconstitution healing if both statuses are active.
- [[Renewal]]: another conditional healing boon.

## Sources

- `clockwork-company/resources/statuses/reconstitution.tres`
- `clockwork-company/scripts/combat/rules/status_resolver.gd`
- `DESIGN_NOTES.md`
- `JOB_CONTENT_DESIGN.md`
