---
type: concept
state: implemented
aliases:
  - Request Fact Pipeline
tags:
  - combat
  - events
  - architecture
---

# Combat Event Pipeline

Combat causality uses simulator-owned requests and facts. Requests may be modified or prevented before resolution; facts describe completed outcomes and may queue consequences.

## Why It Exists

- Preserves deterministic ordering
- Keeps [[Foretell]] compatible with normal combat
- Allows reactions, prevention, statuses, items, jobs, and ancestry features to share hooks
- Produces readable causal logs
- Avoids gameplay responding to prose or Godot signals

## Ordering

`CombatContext` owns event history, responder order, request handling, and triggered-chain limits. `CombatHookResolver` is the central responder and dispatches shared triggered effects first, then focused mechanic families in explicit order.

Each shared effect normally fires at most once per causal root, preventing recursive status/effect loops. Explicit effects can opt into repeat behavior where supported.

## Requests and Facts

Important requests include damage, healing, reaction, status application/removal, and attack targeting. Important facts include damage dealt, healing received, status applied/removed, action completed, and unit defeated.

See [[COMBAT_EVENTS]] for the detailed event contract.

## Implementation

- `clockwork-company/scripts/combat/runtime/combat_context.gd`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- `clockwork-company/scripts/combat/rules/triggered_effect_resolver.gd`
- `clockwork-company/scripts/combat/logging/combat_event_schema.gd`
- `clockwork-company/scripts/tools/combat_event_pipeline_check.gd`
