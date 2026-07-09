---
type: design
category: job
state: designed
tags:
  - job
  - magic
  - ailment
  - elemental
---

# Elementalist

Elementalist is the provisional name for an ailment engine that creates,
compresses, and preserves elemental stacks. The reusable authoring mechanics
are implemented; the job Resource and final tuning are not.

## Intended Kit

- Growth biases: strong magic damage and moderate maximum HP.
- Passive: whenever the Elementalist newly applies ailment stacks, gain 5
  Energy Shield per stack actually added. Transferred stacks do not count.
- Primary action: apply one [[Burning]], one [[Shock]], and one [[Frost]] to an
  enemy.
- Bridge action: remove all three elemental ailments from an enemy and apply
  one [[Elemental Fusion]] stack per three stacks removed, rounded up.
- Reaction: when an enemy dies carrying ailments, transfer every carried
  ailment to the living enemy with the most ailment stacks, then lowest HP,
  then roster order. Cooldown 3.

## Authoring

- Passive: `Owner Applied Ailment` + `Grant Energy Shield` on `Self`, using
  `Applied Status Stacks` multiplied by 5, with
  `repeat_within_event_chain = true` so all three primary applications count.
- Primary: `Effects Only` with three `Skill Used` + `Apply Status` effects.
- Bridge: `Skill Used` + `Fuse Elemental Ailments` on `Event Target`, referencing
  Elemental Fusion with `amount_divisor = 3`.
- Reaction: `Enemy Died With Ailments`; `Effects Only`; cooldown 3; followed by
  `Reaction Triggered` + `Transfer Defeated Ailments` targeting
  `Most Ailmented Enemy Unit`.

## Important Interactions

Fusion creates new ailment stacks and therefore fuels the passive. Death
transfer moves existing stacks and deliberately does not fuel it again.

Ward can prevent each transferred ailment as it enters the new host. The
transfer preserves stacks, duration, permanence, and source name, but blocked
applications are lost because the original host is already defeated.

Detailed recipe: [[JOB_CONTENT_DESIGN#Elementalist]]
