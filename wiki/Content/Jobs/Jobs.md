---
type: index
category: job
state: implemented
design_maturity: playable draft
tags:
  - job
  - content
  - index
---

# Jobs

Jobs are the trained identity layer described by [[Jobs and Progression]].

The current Resource catalog is a clean slate: old prototype/scaffold jobs, units, loadouts, items, tactics, and ancestries have been removed. Each designed job below has an authored `JobDefinition` Resource plus one allied template unit/loadout for manual testing.

Some jobs are exact fits for the current shared effect vocabulary. Jobs whose design pages call out resolver gaps use conservative current-engine approximations in their Resources until the missing mechanics are implemented.

## Implemented Draft Jobs

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

## Character Templates

- `clockwork-company/resources/units/` contains one allied `template_` unit per job and minimal `sparring_` enemies used by preserved encounters.
- `clockwork-company/resources/loadouts/` contains one matching equipment-free `template_` loadout per job.

## Implementation

- `clockwork-company/resources/jobs/`
- `clockwork-company/resources/units/`
- `clockwork-company/resources/loadouts/`
- `clockwork-company/scripts/data/job_definition.gd`
- `clockwork-company/scripts/combat/rules/job_effect_resolver.gd`
