# Combat Events

Combat rules communicate through the simulator-owned `CombatContext`. The context keeps deterministic responder order, an authoritative event history, causal parent/root ids, and safety limits for triggered chains.

## Requests and facts

Requests describe something that is proposed but can still be modified or prevented:

- `damage_requested`
- `healing_requested`
- `status_application_requested`
- `status_removal_requested`
- `reaction_requested`

Responders may modify a request's `payload` in registration order. A prevented request sets `prevented = true` and should explain the reason through `prevented_reason`.

Facts describe something that has already happened. Responders may create consequences, but cannot retroactively change the fact:

- battle, turn, and action facts
- `attack_performed`
- `damage_dealt` / `damage_prevented`
- `healing_received` / `healing_prevented`
- `armor_gained` / `armor_lost`
- `status_applied`, `status_triggered`, `status_removed`, and `status_application_prevented`
- `reaction_triggered` / `reaction_suppressed`
- `unit_defeated`
- `triggered_effect_resolved`
- `temporary_modifier_applied` / `temporary_modifier_removed`

## Deterministic ordering

Requests are offered synchronously to responders in registration order so later responders see earlier modifications.

Facts use a queue. Every responder sees the current fact before any facts created in response to it are processed. Nested facts retain `parent_id` and `root_id`, making chains readable and preventing call-stack ordering from silently changing outcomes.

`CombatHookResolver` is the current central responder. It dispatches existing item, ancestry, reaction, status, kill, and death behavior in an explicit order. Additional focused responders can be registered later when a mechanic family becomes large enough to justify separate ownership.

`TriggeredEffectResolver` is dispatched first by the central responder. It resolves shared authored effects from equipped items, used skills, and active scenario rules. Each shared effect can fire only once per causal root, which prevents status-application/removal hooks from recursively triggering themselves forever.

## Runtime and presentation

Gameplay responds to `CombatContext` events, not combat-log entries or Godot signals. The log and replay remain presentation consumers.

Battle reports expose sanitized `combat_events` without runtime unit references. Existing structured log `events` remain the presentation-oriented event stream.

## Safety

The context limits event-chain depth and total processed facts. Content should additionally use cooldowns, charges, or once-per-root rules whenever a mechanic could respond to its own consequences.
