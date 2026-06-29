---
type: index
category: job
state: implemented
design_maturity: prototype
tags:
  - job
  - content
  - index
---

# Jobs

Jobs are the trained identity layer described by [[Jobs and Progression]].

> [!warning] Prototype job catalog
> The 16 jobs below have authored, runnable Resources, but they are scaffold/catalog content used to exercise current systems. None should be treated as a final job design, including Spellsword.

## Runnable Prototype Jobs

- [[Apprentice]]: fast magic trainee with healing support and self-recovery.
- [[Archivist]]: forecasting support healer.
- [[Bellguard]]: slow, durable guard specialist.
- [[Chirurgeon]]: armored healer.
- [[Cutpurse]]: fast physical attacker.
- [[Debt Knight]]: armored attacker with retaliation.
- [[Foundry Monk]]: self-guarding durable job.
- [[Guard]]: straightforward defensive job.
- [[Lamplighter]]: fast support healer with retaliation.
- [[Ratcatcher]]: physical hunter with retaliation.
- [[Red Scribe]]: fast blood-themed healer.
- [[Roofer]]: fast physical duelist.
- [[Scout]]: fast physical attacker.
- [[Spellsword]]: developed-recruit hybrid with standalone learned features.
- [[Turnkey]]: armor-heavy guard/control job.
- [[Witness]]: flexible magic attacker with self-recovery.

## Designed but Unimplemented Jobs

- [[Pyromancer]]
- [[Cryomancer]]
- [[Enthalpyst]]
- [[Paladin]]
- [[Bog Priest]]
- [[Bruiser]]
- [[Executioner]]
- [[Bard]]
- [[Chronomancer]]
- [[Monk]]
- [[The Spike]]
- [[Sanguinist]]
- [[Aegiswright]]
- [[Arcane Warden]]
- [[Elementalist]]

## Implementation

- `clockwork-company/resources/jobs/`
- `clockwork-company/scripts/data/job_definition.gd`
- `clockwork-company/scripts/combat/rules/job_effect_resolver.gd`
