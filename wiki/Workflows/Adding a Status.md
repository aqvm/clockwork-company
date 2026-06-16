---
type: workflow
state: implemented
tags:
  - workflow
  - status
---

# Adding a Status

Add a status only when focused content needs a distinct tactical pressure.

## Steps

1. Define the tactical question and decide whether the mechanic is truly a [[Statuses|status]] rather than a direct effect or [[Timeline and Action Scheduling|timeline]] consequence.
2. Decide polarity, stacking rule/cap, authored amounts, natural expiry, and tooltip description.
3. Add a `StatusDefinition` Resource under `clockwork-company/resources/statuses/`.
4. Extend the explicit status-type vocabulary in `status_definition.gd` and JSON loader/schema docs.
5. Implement focused behavior in the appropriate resolver/hook without adding a broad status DSL.
6. Add focused mechanics validation, including prevention/removal and event ordering where relevant.
7. Add a canonical status page and link related content.

## Design Checks

- Is behavior deterministic and log-readable?
- Does [[Ward]] prevent it?
- Does removal trigger [[Renewal]]?
- Does it qualify for `Ailment Damaged`?
- Does duration belong to the application source?
- Can existing shared effects apply/remove/consume/transfer it correctly?

## Primary References

- [[Statuses]]
- [[Potential Future Statuses]]
- `clockwork-company/scripts/data/status_definition.gd`
- `clockwork-company/scripts/combat/rules/status_resolver.gd`
- `clockwork-company/scripts/tools/status_mechanics_check.gd`
