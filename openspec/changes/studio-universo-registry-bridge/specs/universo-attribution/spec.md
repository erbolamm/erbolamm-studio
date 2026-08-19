# Universo Attribution Specification

## Purpose

Any later Universo mention of ErBolamm Studio MUST be copy-only attribution. Attribution MUST NOT create a Studio graph node, edge, project record, or Universe card.

## Requirements

### Requirement: Attribution is copy-only

The system MAY add later Universo copy that attributes creation or organization of the universe to ErBolamm Studio, but that copy MUST remain separate from project registry and graph publication data.

#### Acceptance Criteria

- Attribution copy MAY describe Studio as the tool used to create or organize the universe.
- Attribution copy MUST NOT create or require RTDB `nodes`, RTDB `edges`, Firestore `project_registry` documents, or Universe cards for Studio.
- Attribution copy MUST be scoped and verified independently from local registry persistence and bridge projection.

#### Scenario: Add attribution without graph data

- GIVEN a later slice changes Universo landing copy to mention ErBolamm Studio
- WHEN the copy is rendered
- THEN the mention MAY appear as attribution text
- AND no `erbolamm-studio` node, edge, canonical project document, or Universe card MUST be created.

### Requirement: Attribution is not part of slice one

The first implementable local persistence slice MUST NOT include Universo attribution copy unless a later task explicitly scopes it.

#### Acceptance Criteria

- Local persistence tasks MUST focus on `project_records`, `ProjectRegistryService`, `LocalDatabase`, Analyzer save behavior, `flutter analyze`, and focused local tests.
- Attribution copy MUST NOT be used as evidence that remote publication or bridge projection works.

#### Scenario: Complete local persistence without attribution

- GIVEN the local registry repair slice is implemented and verified
- WHEN the slice is reviewed
- THEN missing Universo attribution copy MUST NOT fail the local persistence acceptance criteria
- AND no graph publication MUST be inferred from the local save path.
