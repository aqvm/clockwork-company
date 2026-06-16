---
type: meta
state: implemented
tags:
  - wiki
  - documentation
---

# Documentation Map

## Current Knowledge

`wiki/` is the canonical concise lookup layer for current concepts, content behavior, implementation ownership, and workflows.

## Root Documents

- [[ARCHITECTURE]] is the detailed structural record. Update it only for meaningful responsibility or structural changes.
- [[DESIGN_NOTES]] holds durable long-form design decisions and rationale.
- [[LEARNING_LOG]] is chronological history. New entries should link to canonical wiki pages where useful instead of repeating full current rules.
- [[TODO]] is the backlog, not a design authority.
- [[ROADMAP]] is phase planning, not a current behavior reference.
- [[JOB_CONTENT_DESIGN]] owns detailed recipes for designed jobs until those jobs become implemented content.
- [[CONTENT_AUTHORING]] owns the detailed `.tres` authoring workflow.
- [[CONTENT_HOOK_AUDIT]] records focused audit findings and deliberate gaps.
- [[COMBAT_EVENTS]] documents the detailed request/fact event contract.
- [[MODDING]] is the modding entry point.
- `.options.md` files under `clockwork-company/modding/reference/` are authoritative for externally authorable JSON contracts.

## Source of Truth Order

For implemented behavior:

1. Runtime code and authored Resources
2. Focused validation checks
3. Canonical wiki page
4. Detailed root documents
5. Historical documents

For durable design intent:

1. Canonical wiki design/concept page
2. [[DESIGN_NOTES]] or [[JOB_CONTENT_DESIGN]]
3. [[TODO]] and [[ROADMAP]]
4. [[LEARNING_LOG]]

## Historical Linking

Do not atomize or rewrite [[LEARNING_LOG]]. Add links in new retrospective entries when relevant. Retroactive link passes should be narrow and purposeful rather than rewriting the historical record.
