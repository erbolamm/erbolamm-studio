# Studio Project Registry Specification

## Purpose

Studio MUST provide durable local `ProjectRecord` persistence before any remote publication path is enabled. The first implementable slice repairs the local `project_records` storage boundary used by `ProjectRegistryService`, `LocalDatabase`, and the Analyzer save flow.

## Requirements

### Requirement: Durable local project record storage

The system MUST persist `ProjectRecord` records in a local `project_records` store that is available through `LocalDatabase` and usable by `ProjectRegistryService`.

#### Acceptance Criteria

- `LocalDatabase` MUST create or migrate the `project_records` storage needed by the registry.
- `ProjectRegistryService` MUST be able to create, read, update, delete, and query project records through `LocalDatabase` without calling missing database methods.
- Stored records MUST survive service/database reinitialization within the same local database.
- Local persistence MUST remain separate from any Firestore or RTDB publication path.

#### Scenario: Persist and retrieve a project record

- GIVEN Studio has a valid `ProjectRecord`
- WHEN the record is saved through `ProjectRegistryService`
- THEN `LocalDatabase` MUST store the record in `project_records`
- AND the same record MUST be retrievable through `ProjectRegistryService` after reopening the local database.

#### Scenario: Query registered project records

- GIVEN multiple project records exist in local storage
- WHEN `ProjectRegistryService` requests the registry list or filtered records
- THEN `LocalDatabase` MUST return the matching records without reading remote services.

### Requirement: Analyzer save path uses the repaired registry

The Analyzer save path MUST save completed analysis output as a local `ProjectRecord` through `ProjectRegistryService` without failing because of absent `LocalDatabase` methods.

#### Acceptance Criteria

- Analyzer record creation MUST remain explicit and local for the first slice.
- Analyzer save MUST NOT imply Firestore publication, RTDB publication, or Universo graph insertion.
- Failures unrelated to local registry persistence MUST be reported separately from missing-method persistence failures.

#### Scenario: Analyzer saves a completed record locally

- GIVEN an Analyzer flow has produced a completed analysis that can be converted to a `ProjectRecord`
- WHEN the user or flow saves the record
- THEN the save MUST complete through `ProjectRegistryService`
- AND the record MUST be durable in local `project_records`
- AND no RTDB `nodes` or `edges` write MUST occur.

### Requirement: Local persistence verification

The first slice MUST include focused verification for local registry persistence and static analysis.

#### Acceptance Criteria

- `flutter analyze` MUST pass for the local persistence changes or report unrelated baseline failures separately.
- Focused tests MUST cover local project record create, read, update, delete, query, and Analyzer save behavior.
- Remote bridge or Firebase Function tests MAY be deferred to later slices and MUST NOT block completion of the local persistence slice.

#### Scenario: Verify the local registry repair

- GIVEN the local persistence slice has been implemented
- WHEN `flutter analyze` and the focused local registry tests are run
- THEN the registry-related checks MUST pass
- AND any non-registry baseline failures MUST be identified as outside the local persistence acceptance criteria.
