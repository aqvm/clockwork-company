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

## Later / not soon

- procedural items
- class trees
- async multiplayer snapshots
- enemy doctrine analysis
- adaptive difficulty
- scouting reports
- polish/animation/audio
