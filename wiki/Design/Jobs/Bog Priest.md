---
type: design
category: job
state: designed
tags: [job, healing, rot]
---
# Bog Priest

Bog Priest redistributes wasted healing while corrupting enemy recovery and allies who receive excessive care.

## Intended Kit

- Heal an ally for a percentage of maximum HP.
- Replace an enemy heal with 1 healing and apply [[Rot]].
- When overhealing another ally, redistribute the excess to a deterministic-random damaged ally and apply Rot to the original target.
- Consume enemy Rot to heal allies by the total maximum HP lost to it, then restore that maximum HP as empty HP.

The event pipeline's cooldown and causal-root protections prevent the replacement and redistribution effects from recursively triggering themselves.

Detailed recipe: [[JOB_CONTENT_DESIGN#Bog Priest]]
