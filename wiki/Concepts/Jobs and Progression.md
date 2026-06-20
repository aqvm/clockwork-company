---
type: concept
state: implemented
tags:
  - jobs
  - progression
  - campaign
---

# Jobs and Progression

Jobs are the trained identity layer. They provide stat-growth tendencies, optional equipment restrictions, one primary skill, one optional secondary skill, one passive, one reaction, and one default tactic.

## Current Ability Model

- `Job Skill` uses the unlocked skill from the current job.
- `Secondary Skill` uses the unlocked secondary skill from the current job.
- `Assigned Skill` uses one equipped learned skill from another job.
- A loadout may equip one learned passive and one learned reaction.
- Per-job progress records levels and unlocked feature provenance.
- Abilities mutate runtime outcomes, not authored definitions.

Secondary skills hold job-owned bridge actions: active abilities that connect the job's main mechanic to another planning axis without consuming the cross-job assigned skill slot. They unlock with the job's normal skill unlock and are not currently separate learned-feature assignments.

## Current Progression

- Maximum five total job levels per unit
- Maximum three levels in one job
- Level 1 requires a skill-versus-reaction choice
- Level 2 unlocks the passive
- Level 3 unlocks the unchosen skill or reaction
- Campaign scenario victory awards one eligible deployed survivor a level
- Scenario tier, unit cap, job cap, and stable selection rules constrain the award

Past jobs leave readable residue through learned ability assignments and permanent growth. Job dependency trees are intentionally deferred.

## Related

- [[Jobs]]
- [[Tactics]]
- [[Items and Equipment]]
- [[Scenarios and Campaigns]]

## Implementation

- `clockwork-company/scripts/data/job_definition.gd`
- `clockwork-company/scripts/data/job_progress_definition.gd`
- `clockwork-company/scripts/data/unit_loadout_definition.gd`
- `clockwork-company/scripts/combat/rules/job_effect_resolver.gd`
- `clockwork-company/scripts/campaign/campaign_roster_state.gd`
