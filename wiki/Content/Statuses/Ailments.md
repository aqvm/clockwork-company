---
type: index
category: status
state: implemented
aliases:
  - Ailment
tags:
  - status
  - ailment
---

# Ailments

Ailments are negative [[Statuses]]. They are intended to create distinct tactical pressures rather than interchangeable damage-over-time effects.

- [[Bleed]] punishes acting frequently.
- [[Burning]] punishes acting and receiving support.
- [[Confusion]] disrupts tactic priority.
- [[Frost]] sets up physical burst.
- [[Numb]] suppresses reactions.
- [[Rot]] punishes healing.

## Counters and Synergies

- [[Ward]] prevents an incoming ailment by consuming one stack.
- [[Renewal]] heals whenever an ailment is removed.
- [[Bleed]], [[Burning]], and qualifying [[Rot]] damage can trigger effects that listen for `Ailment Damaged`.
- Generic resistance is intentionally not part of the current model; authored prevention, replacement, and removal are preferred.

See [[Statuses]] for shared duration and stacking rules.

See [[Potential Future Statuses]] for discussed ailment concepts that are not implemented or committed.
