---
type: design
state: implemented
tags:
  - design
  - principles
---

# Design Principles

The project is a learning-first, systems-heavy single-player roguelite autobattler where buildcraft becomes biography.

## Durable Principles

- Units should become memorable through ancestry/body, jobs, learned features, gear, tactics, and combat history.
- Combat is deterministic, discrete-event, and readable through logs.
- The player authors behavior before combat rather than issuing commands during it.
- Gear creates tradeoffs and build pivots rather than only increasing numbers.
- Jobs provide identity, growth tendencies, abilities, and career residue.
- Ancestry is an immutable body/identity layer separate from trained jobs.
- Scenarios ask pointed buildcraft questions through normal authored content.
- The combat simulation remains separate from presentation and UI.
- Definitions remain separate from mutable runtime combat state.
- New mechanics should be small, content-led, deterministic, and explainable.
- Campaign and scenario systems remain thin wrappers over combat.

## Scope Boundaries

Do not introduce procedural generation, management-sim systems, networking, broad animation systems, or large content sets without an explicit focused decision.

## Related

- [[Combat Simulation]]
- [[Tactics]]
- [[Jobs and Progression]]
- [[Scenarios and Campaigns]]
- [[DESIGN_NOTES]]
