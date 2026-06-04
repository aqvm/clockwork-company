# Roadmap

## Phase 0: Repo bootstrap

Goal:
Create project instructions, architecture docs, and folder structure.

Done when:

- markdown files exist
- folder structure exists
- project purpose is clear

## Phase 1: Text-only combat simulator

Goal:
A button runs a hardcoded 3v3 fight and prints a combat log.

Features:

- hardcoded units
- discrete-event action timing
- frontmost targeting
- basic damage formula
- victory/loss detection
- combat log

Done when:

- I can run one fight
- I can change a unit stat and predict the result
- the combat log explains what happened

## Phase 2: Data-driven units

Goal:
Move unit definitions out of hardcoded combat logic.

Features:

- unit definitions
- runtime unit states
- clear definition/state separation

Done when:

- I can add or edit a unit without rewriting the simulator

## Phase 3: Basic gear

Goal:
Items modify unit stats.

Features:

- simple item definitions
- equipment slots
- flat modifiers for damage, HP, armor, action interval

Done when:

- equipping an item visibly changes combat results

## Phase 4: Triggered item effects

Goal:
Items can create simple build identity.

Initial triggers:

- on battle start
- on attack
- on hit
- on kill
- on death

Done when:

- at least one item creates a clearly different combat pattern

## Phase 5: Basic tactics

Goal:
Units choose actions from simple priority rules.

Tactic form:
condition -> action -> target

Done when:

- a unit can heal, guard, or attack based on a condition
- tactics are visible and explainable

## Phase 6: Basic jobs

Goal:
Jobs shape unit identity.

Features:

- current job
- job stat modifiers
- job equipment permissions
- one learned passive or action

Done when:

- a unit can become a hybrid through past job learning

## Phase 7: Short roguelite run loop

Goal:
A tiny run of 5 fights with rewards between fights.

Features:

- fixed encounters
- reward choice
- inventory/equipment decisions
- run win/loss

Done when:

- I can play a complete short run

## Phase 8: Scenario Definition Framework

Goal:
Represent short handcrafted missions as data.

Features:

- scenario definitions
- scenario rule definitions
- ordered encounter references
- story intro/outro text

Done when:

- I can inspect a scenario Resource and see what fights it contains

## Phase 9: First Sample Campaign

Goal:
Chain a few scenarios into a lightweight campaign.

Features:

- campaign definition
- scenario unlocks
- campaign progress
- first sample campaign with four scenarios

Done when:

- completing one scenario unlocks the next scenario
- completing the fourth sample scenario marks the campaign complete

## Phase 10: Scenario Rules

Goal:
Turn data-only scenario rules into small, readable mechanical hooks.

Features:

- rule descriptions
- rule UI summary
- narrow combat or run modifiers only when needed

Done when:

- at least one scenario rule changes play and explains itself clearly

## Phase 11: Rewards and Unlocks

Goal:
Make scenario completion rewards and content unlocks useful.

Features:

- scenario-specific reward offers
- content unlock ids that gate visible options
- clearer reward history

Done when:

- scenario completion visibly changes what the player can use next

## Phase 12: Persistent Roster Integration

Goal:
Carry roster/job/gear state across scenarios.

Features:

- persistent unit state
- job progress across scenarios
- gear inventory across scenarios

Done when:

- a unit's campaign history affects a later scenario

## Phase 13: Campaign Save/Load

Goal:
Persist lightweight campaign progress.

Features:

- completed scenarios
- unlocked scenario/content ids
- active roster state

Done when:

- closing and reopening can restore campaign progress

## Phase 14: Standalone Scenario Mode

Goal:
Let scenarios be played outside campaign progression.

Features:

- scenario select
- fixed test roster or chosen roster
- clear completion summary

Done when:

- I can replay a scenario without changing campaign progress

## Later / not soon

- procedural items
- class trees
- async multiplayer snapshots / ghost mode, much later
- enemy doctrine analysis
- adaptive difficulty
- scouting reports
- polish/animation/audio
