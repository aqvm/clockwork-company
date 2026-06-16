---
type: workflow
state: implemented
tags:
  - workflow
  - documentation
  - wiki
---

# Maintaining the Vault

The vault stays useful only if it remains concise, canonical, and cheaper to consult than broad repository search.

## During Implementation

1. Start at [[Home]] and the relevant canonical page.
2. Inspect the page's authoritative implementation files.
3. Update the page only if behavior, durable intent, important interactions, ownership, state, or workflow changed.
4. Link to the canonical page from new historical/design notes instead of repeating its full rules.
5. Add a new page only when a concept is independently searchable, linkable, designed around, or changed often enough to justify maintenance.

## Avoid

- Duplicating full rules across job, status, system, and history pages
- Treating [[TODO]] or [[LEARNING_LOG]] as current behavior authority
- Creating pages for every enum, helper, effect, or trivial content asset
- Listing every file that merely mentions a concept
- Converting unresolved candidates into implemented-sounding documentation

## Documentation Validation

For a documentation-focused change:

1. Run `powershell -ExecutionPolicy Bypass -File tools/check_wiki.ps1`.
2. Run `git diff --check`.

## Periodic Audit

When lookup begins requiring broad search again, audit the relevant area:

- Is a canonical page missing?
- Has a page drifted from implementation?
- Is duplicated information creating contradictions?
- Is a large page mixing several independently useful concepts?
- Is a tiny page providing enough value to justify itself?

See [[Vault Conventions]] for the durable contract.
