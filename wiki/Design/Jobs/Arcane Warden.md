---
type: design
category: job
state: designed
tags:
  - job
  - support
  - energy-shield
  - link
---

# Arcane Warden

Arcane Warden is a link-and-transmutation support duelist who converts suffered
HP loss into Energy Shield, then routes damage through temporary bonds.

`Warden` is treated as its own noun rather than a reference to the implemented
[[Ward]] status.

## Intended Kit

- Growth biases: magic damage and action speed, with the third bias unresolved.
- Passive: whenever the Arcane Warden loses HP from damage, gain Energy Shield
  equal to the actual HP lost. Healing received by the Arcane Warden is reduced
  by 50%.
- Secondary action: link to an ally until the Arcane Warden has taken two
  actions. Damage to either linked unit is split evenly between them. Physical
  damage the Warden takes because of this link becomes magic damage.
- Primary action: link to an enemy until the Arcane Warden has taken two
  actions. Damage to either linked unit is split evenly between them. Magic
  damage the Warden takes because of this link becomes physical damage.
- Reaction: once per combat, when the Arcane Warden has more Energy Shield than
  current HP, detonate all Energy Shield and deal physical damage equal to the
  shield lost to all enemies.

## Balance Notes

The learned-reaction slot makes the detonation optional at build time: a unit
that does not want the automatic once-per-combat explosion can equip a
different learned reaction.

Action speed is a tradeoff. It creates more frequent link choices, but because
links expire after two Warden actions, faster Wardens keep each individual link
for less timeline time.

The ally link is defensive because it can route physical damage into Energy
Shield. The enemy link is riskier because it can turn the Warden's linked magic
damage share into physical damage that bypasses Energy Shield.

## Authoring Gaps

The concept is not fully buildable with the current authoring vocabulary.
Needed reusable capabilities include persistent unit links, linked damage
splitting, per-link damage type conversion, actual-HP-loss-to-Energy-Shield
conversion, received-healing reduction, Energy-Shield-greater-than-HP reaction
conditions, and Energy Shield detonation that spends shield and uses the spent
amount as damage.

Detailed recipe: [[JOB_CONTENT_DESIGN#Arcane Warden]]
