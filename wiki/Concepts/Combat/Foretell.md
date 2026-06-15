---
type: concept
state: implemented
tags:
  - combat
  - tactics
  - forecasting
---

# Foretell

Foretell is an optional deterministic evaluation mode for a normal [[Tactics|tactic]], gated by an equipped `Forecast` passive.

## Current Behavior

- A configured Foretell tactic remains stored when Forecast is unavailable, but cannot be selected.
- Foretell follows one deterministic baseline rather than searching alternatives.
- Speculative turns ignore all Foretell toggles and evaluate normal tactic rules.
- The first future state where the configured condition is true wins.
- The normal target selector runs in that future state and maps the selected unit back to real runtime state.
- The action executes now.
- The horizon ends before the original actor's next turn.
- Speculation is presentation-silent, cannot recursively forecast, and uses isolated runtime/Resource copies.

## Design Boundary

Foretell is intentionally narrow. Do not add alternative futures, arbitrary event predicates, timeline rewriting, or continuous forecasting until focused content needs them.

The same isolated deterministic simulation can also project one unit's next
action damage for authored effects. This projection totals actual HP damage
sourced by that unit, does not mutate real combat, and treats nested
next-action prediction as zero.

## Implementation

- `clockwork-company/scripts/combat/rules/forecast_service.gd`
- `clockwork-company/scripts/combat/rules/tactic_resolver.gd`
- `clockwork-company/scripts/tools/forecast_mechanics_check.gd`
