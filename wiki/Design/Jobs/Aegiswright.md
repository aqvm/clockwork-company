---
type: design
category: job
state: designed
tags:
  - job
  - support
  - energy-shield
  - armor
---

# Aegiswright

Aegiswright is a provisional job concept for an armor-scaling shield-battery
support who converts personal defenses into shared Energy Shield.

The name is preferred over Ward-based names because this job does not interact
with the implemented [[Ward]] status.

## Intended Kit

- Growth biases: armor, maximum HP, and magic damage.
- Passive: after each action, gain Energy Shield equal to twice current armor.
- Action: deal magic damage that pierces Energy Shield.
- Reaction: when an ally would die, sacrifice 50% of the Aegiswright's Energy
  Shield to keep that ally alive at 1 HP. Cooldown 5. If the Aegiswright has no
  Energy Shield, this does not trigger.
- Bridge action: split the Aegiswright's Energy Shield evenly between all
  allies.

## Balance Notes

The death-prevention reaction is the signature mechanic and should be tuned as
stronger than ordinary healing. A minimum Energy Shield requirement or minimum
cost may be needed so a tiny shield remainder does not buy a full death save.

The Bridge action makes Energy Shield a shared emergency resource rather than
only personal protection. Rounding down and leaving any split remainder on the
Aegiswright is the simplest deterministic rule.

## Authoring Gaps

The concept is not fully buildable with the current authoring vocabulary.
Needed reusable capabilities include owner-armor amount scaling, Energy Shield
redistribution, a broad ally-would-die intervention trigger, source Energy
Shield spending, and magic damage that pierces Energy Shield.

Detailed recipe: [[JOB_CONTENT_DESIGN#Aegiswright]]
