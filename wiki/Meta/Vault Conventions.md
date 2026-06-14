---
type: meta
state: implemented
tags:
  - wiki
  - documentation
---

# Vault Conventions

## Purpose

The vault is a concise current-knowledge layer optimized for human navigation and token-efficient agent lookup. It is not a duplicate of every project document.

The target lookup path is one index page, one concept/content page, and at most two authoritative implementation files.

## Canonical Ownership

Every current fact should have one canonical home. Other pages link to that page instead of repeating its full rules.

- Concept pages own reusable mechanic explanations.
- Content pages own concrete authored content behavior and identity.
- Architecture pages own implementation responsibilities.
- Design pages own unresolved or proposed ideas.
- Workflow pages own practical change and validation instructions.
- Historical documents explain how the project evolved, not necessarily how it works now.

When the wiki and implementation disagree, inspect the implementation and correct the wiki. When the wiki and an older historical statement disagree, the current wiki page wins unless the implementation shows drift.

## Page Types

Use these `type` values:

- `index`: navigation page
- `concept`: reusable mechanic
- `content`: concrete authored content
- `architecture`: implementation ownership
- `design`: proposed, unresolved, or rejected idea
- `workflow`: practical instructions
- `meta`: vault documentation
- `history`: chronological record

## State Vocabulary

- `implemented`: present and usable in current code/content
- `designed`: concrete intended behavior exists but is not fully implemented
- `candidate`: discussed direction with unresolved behavior
- `deprecated`: previously authoritative but no longer used
- `historical`: preserved to explain project evolution

Do not describe designed or candidate behavior as implemented.

## Frontmatter

Use only metadata that improves lookup:

```yaml
---
type: content
category: status
state: implemented
aliases:
  - Burn
tags:
  - status
  - ailment
---
```

Recommended fields are `type`, `category`, `state`, `aliases`, and broad `tags`. Avoid manually maintained relationship lists and update dates.

Use `design_maturity: prototype` when content is implemented and runnable but its identity, kit, tuning, or presentation is explicitly not a final design. This keeps implementation state separate from design finality.

## Page Shape

Put the shortest useful answer near the top. A content or concept page should usually contain:

1. One-sentence summary
2. Current behavior or intended behavior
3. Important interactions
4. Open questions, only when relevant
5. Authoritative implementation files or source documents

Most pages should stay between roughly 150 and 700 words. Split pages that become difficult to scan; do not create tiny pages for every enum, helper, or field.

## Links

- Use unique, natural page names.
- Link the first meaningful mention in a section, not every repeated word.
- Prefer links over repeated explanations.
- Use aliases for likely lookup terms.
- Do not manually maintain backlink lists.
- Existing root Markdown documents participate in the vault and may be linked by basename.

## Implementation References

Implemented concept/content pages list only authoritative definitions, primary resolver/owner code, and focused validation checks. Do not list every file that merely mentions the concept.

## Maintenance Rule

Update a canonical page only when current behavior, durable design intent, important interactions, implementation ownership, implementation state, or a workflow changes. Do not update it merely to record that implementation work occurred.

## Agent Lookup Protocol

1. Start at [[Home]] or the relevant index.
2. Read the canonical page.
3. Inspect its listed authoritative implementation files.
4. Search broadly only when the page is incomplete or implementation may have drifted.
5. Update the canonical page if the task changes its durable knowledge.
