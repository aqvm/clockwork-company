---
type: design
category: job
state: designed
design_maturity: prototype
tags:
  - job
  - support
  - bard
---

# Bard

The Bard is a pure global support whose mechanics improve the whole allied
team rather than dealing damage.

## Design

- Growth biases: HP and action speed; specifically no physical- or
  magic-damage growth.
- Action: grant temporary Haste to all allies.
- Reaction: when an ally successfully gains an ailment, grant all allies
  1 Ward. Cooldown 3.
- Bridge action: grant Regeneration to all allies.
- Passive: timed buffs on allies last a configurable percentage longer.

## Authoring

- Action: `Effects Only`; `Skill Used` + `Apply Haste` on `Allied Units`.
- Reaction: `Ally Ailment Applied`; `Effects Only`; cooldown 3;
  `Reaction Triggered` + `Apply Status` Ward on `Allied Units`.
- Bridge: `Effects Only`; `Skill Used` + `Apply Status` Regeneration on
  `Allied Units`.
- Passive: `Extend Allied Buff Duration`; `amount` is the percentage.

## Duration Rules

The passive affects buffs from any source on the passive owner's living team.
Multiple allied copies do not stack; the strongest applies. Eligible buffs are
finite naturally-elapsing Boons, positive temporary stat modifiers, and
temporary Haste. It excludes permanent and non-elapsing statuses such as Ward,
debuffs, transferred existing durations, and battle-long action-speed gains.
