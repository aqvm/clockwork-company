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

No authored ancestry Resources are present after the character-content cleanup. Template characters currently use explicit base stats with no ancestry so job mechanics can be inspected without inherited body features.

## Implementation

- `clockwork-company/resources/ancestries/`
- `clockwork-company/scripts/data/ancestry_definition.gd`
- `clockwork-company/scripts/data/ancestry_feature_definition.gd`
- `clockwork-company/scripts/combat/rules/ancestry_feature_resolver.gd`
