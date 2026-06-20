---
type: workflow
state: implemented
tags:
  - workflow
  - job
---

# Adding a Job

Jobs should combine shared authored effects before requiring job-specific resolver branches.

## Steps

1. Define the job's identity and buildcraft question.
2. Fit the current scaffold: growth, optional equipment forbids, one primary skill, optional secondary skill, one passive, one reaction, and one default tactic.
3. Test the concept against existing triggers, conditions, targets, formulas, and effects.
4. Add a reusable resolver capability only when the concept cannot be expressed accurately.
5. Author the job Resource and any standalone feature Resources needed for learned-feature provenance.
6. Add focused content/mechanics validation.
7. Add an implemented job page and update [[Jobs]].

## Design Checks

- Does growth pay for strengths with understandable tradeoffs?
- Do abilities remain deterministic and log-readable?
- Are cooldowns battle-local unit-turn counters?
- Does the job create a distinct play pattern rather than a better version of another job?
- Can its default tactic actually exercise its skill?
- If it has a bridge action, does the secondary skill connect existing mechanics without requiring a new resolver branch?

## References

- [[Jobs and Progression]]
- [[JOB_CONTENT_DESIGN]]
- `clockwork-company/scripts/data/job_definition.gd`
- `clockwork-company/scripts/combat/rules/job_effect_resolver.gd`
