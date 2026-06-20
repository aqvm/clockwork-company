---
type: design
category: job
state: designed
tags: [job, burning, ailment]
---
# Pyromancer

Pyromancer builds persistent [[Burning]] pressure while turning hostile ailments back onto their source.

## Intended Kit

- Apply Burning to enemies through an effects-only skill.
- Maintain global Burning pressure through passive battle-start and turn-start Burning pulses that affect every unit, with the Pyromancer's own Burn immunity preventing self-Burning.
- Be immune to incoming Burning.
- Replace an incoming ailment with a deterministic-random boon, then double the attempted source's Burning.
- Secondary skill `Hot on Their Heels` hastens an ally based on its total ailment stacks.

Burn immunity prevents the request before the replacement reaction sees it, so incoming Burning does not also reward the Pyromancer's replacement reaction.

No new resolver capability is currently required.

Current Resource implementation keeps the authored Pyromancer pieces as standalone files under `res://resources/job_features/Pyromancer/`, with `res://resources/jobs/Pyromancer.tres` referencing the primary skill, secondary skill, passive, reaction, and default tactic.

Detailed recipe: [[JOB_CONTENT_DESIGN#Pyromancer]]
