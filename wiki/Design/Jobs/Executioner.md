---
type: design
category: job
state: designed
tags: [job, physical, execution, interception]
---
# Executioner

Executioner is a slow, durable physical attacker who pressures high-HP targets, finishes wounded enemies, and prepares lethal attacks between its scheduled actions.

## Intended Kit

- Strong physical-damage growth, moderate maximum-HP growth, and poor action-speed growth.
- Attack an enemy, then deal additional physical damage proportional to its maximum HP.
- Immediately defeat an enemy left at or below 10% HP by the Executioner's physical damage.
- After falling to 30% HP or lower, heal after each enemy scheduled action completed before the Executioner's next scheduled action.
- `Ready the Swing` prepares one base attack against the next enemy to begin a scheduled action.

The execute requires positive HP damage from the Executioner and does not activate from a fully prevented hit. `Ready the Swing` performs one complete base attack before the enemy acts; if that attack defeats the enemy, its pending action is canceled.

## Authoring

- Passive: `Hit` + `Execute Target` on `Attack Target`, with `threshold_percent = 10`.
- Reaction: `HP Below Threshold` at 30%, with a `Reaction Triggered` + `Begin Enemy Action Healing` effect on `Self`. Use `Target Max HP` with an authored multiplier/divisor for the heal amount.
- `Ready the Swing`: an `Effects Only` skill targeting `Self`, with `Skill Used` + `Prepare Base Attack`.

These reusable resolver capabilities are implemented; the job Resource and final tuning remain unimplemented.

Detailed recipe: [[JOB_CONTENT_DESIGN#Executioner]]
