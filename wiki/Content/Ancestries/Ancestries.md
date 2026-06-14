---
type: index
category: ancestry
state: implemented
tags:
  - ancestry
  - content
---

# Ancestries

Ancestry is the immutable body/identity layer, separate from [[Jobs and Progression|jobs]] as trained identity.

Each ancestry can define future stat-generation ranges, baseline growth applied per total job level, one always-on feature, tags, notes, and equipment blacklists.

## Current Catalog

- **Brassbound:** clockwork body with `Spring Return`.
- **Emberkin:** magic/fire identity with `Ember Vein`.
- **Hollow:** fragile echo/survival identity with `Second Echo`.
- **Minotaur:** large physical identity with `Goring Charge`.
- **Redcap:** swift bloodied identity with `Blood Rush`.
- **Stonekin:** durable guard identity with `Stone Memory`.
- **Typhon-born:** many-headed helmet/prophecy identity with `Many-Crowned`; future two-helmet capacity is not implemented.

## Implementation

- `clockwork-company/resources/ancestries/`
- `clockwork-company/scripts/data/ancestry_definition.gd`
- `clockwork-company/scripts/data/ancestry_feature_definition.gd`
- `clockwork-company/scripts/combat/rules/ancestry_feature_resolver.gd`
