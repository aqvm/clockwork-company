---
type: design
category: job
state: designed
tags: [job, support, forecast, time]
---
# Chronomancer

Chronomancer is a predictive support mage that manipulates recorded recent
damage and an enemy's deterministic next action.

## Intended Kit

- Passive: grants [[Foretell]] capability.
- Action: heal an ally for the actual HP damage they suffered during a
  configurable recent timeline interval.
- Reaction: after an ally suffers magic HP damage, grant all allies Energy
  Shield equal to half the team's collective magic HP damage during that
  interval. Use an authored cooldown.
- Bridge action: deal damage to an enemy equal to the actual HP damage they are
  predicted to deal during their next action.

## Authoring

- Action amount source: `Target Damage Taken Within Interval`.
- Reaction trigger: `Ally Magically Damaged`; shield amount source:
  `Total Allied Magic Damage Taken Within Interval`.
- Bridge amount source: `Target Predicted Next Action Damage`.
- Set `interval_time` on interval-based effects. Timeline intervals are
  discrete and inclusive.

The reusable resolver capabilities are implemented; the job Resource, final
damage type, interval, cooldown, and tuning remain unimplemented.

Detailed recipe: [[JOB_CONTENT_DESIGN#Chronomancer]]
