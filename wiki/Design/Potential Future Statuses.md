---
type: design
category: status
state: candidate
aliases:
  - Future Statuses
  - Status Ideas
tags:
  - status
  - design-candidate
  - future
---

# Potential Future Statuses

These concepts have been discussed but are not implemented or committed designs. They should only become authored [[Statuses]] when focused content needs them and their rules create a distinct, readable tactical question.

## Candidate Ailments

### Doom

**Discussion state:** User-confirmed prior discussion; no checked-in design text preserves the exact rule.

Doom occupies the delayed-defeat or looming-consequence design space. Its value would be forcing both sides to respond before a visible deadline rather than acting as another ordinary damage-over-time effect.

Questions to settle before implementation:

- Does Doom defeat the unit when a countdown expires, deal a large damage request, or trigger a source-authored consequence?
- Is its countdown represented by stacks, owner-turn duration, or separate mechanic state?
- Can Doom be removed normally, transferred, prevented by [[Ward]], or replaced by reactions?
- How should defeat prevention, healing, and [[Renewal]] interact with it?
- What focused job, enemy, item, or scenario makes Doom necessary?

### Armor Corrosion

**Discussion state:** Loose direction recorded in `DESIGN_NOTES.md` and `TODO.md`.

Armor Corrosion would change mitigation math and make armored units increasingly vulnerable. Its main design challenge is distinguishing itself from existing direct armor-reduction effects.

Questions to settle before implementation:

- Does it reduce base battle armor, temporary guard armor, or physical mitigation at damage-request time?
- Should it punish high-armor units proportionally or create a flat weakness?
- Is it clearer as an ailment, or should authored effects continue reducing armor directly?

### Silence-Like Disruption

**Discussion state:** Loose direction recorded in `DESIGN_NOTES.md` and `TODO.md`; final name unresolved.

A silence-like ailment would disrupt skill use. It could create a planning puzzle by causing skill tactics to be skipped while leaving attacks, healing, or guard available.

Questions to settle before implementation:

- Does it prevent only job skills, both job and assigned skills, or all non-basic actions?
- Does tactic evaluation continue to later tactics, as with [[Confusion]], or does the attempted skill waste the action?
- How is it kept distinct from [[Numb]], which suppresses reactions?

### Panic

**Discussion state:** Loose direction recorded in `DESIGN_NOTES.md` and `TODO.md`.

Panic would alter targeting rather than action availability. Its purpose would be to disrupt formation and target-selection plans while remaining deterministic and explainable in the combat log.

Questions to settle before implementation:

- Does Panic redirect attacks, alter tactic-selected targets, or constrain valid target groups?
- What deterministic selection rule replaces the intended target?
- How is it kept distinct from existing attack redirection and from [[Confusion]]?

## Discussed Status-Adjacent Mechanics

These ideas have appeared in status discussions but are currently intended to remain outside the status system.

### Stun

Stun is designed as a named timeline delay, not a turn-duration status. A delayed unit does not need to complete a turn before the delay ends.

### Guard and Armor Boons

Armor buffs currently use base battle armor for persistent battle modifiers and temporary guard armor for short-lived protection. The design notes explicitly avoid introducing a named status merely to label armor.

### Scorched

Scorched is the named timeline-delay consequence of supporting a [[Burning]] unit, not a separate status.

### Purge and Immunity

Specific ailment removal and occasional authored immunity are future content tools, not statuses themselves. Generic ailment resistance and universal cleanse access are intentionally discouraged.

## Design Gate

Before promoting one of these ideas into an individual status page:

- Tie it to focused content.
- Define the tactical question it creates.
- Specify request/fact pipeline interactions and deterministic ordering.
- Decide stacking, duration, removal, prevention, and log wording.
- Confirm an existing direct effect or timeline mechanic would not express it more clearly.

## Sources

- User-confirmed prior discussion of Doom
- `DESIGN_NOTES.md`
- `TODO.md`
- `JOB_CONTENT_DESIGN.md`
