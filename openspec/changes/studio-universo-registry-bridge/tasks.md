# Tasks: Studio to Universo Registry Bridge

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | Current apply batch: ~250-380; full roadmap: ~900-1,500 |
| 400-line budget risk | Current batch: Low; full roadmap: High |
| Chained PRs recommended | Current batch: No; future remote/Universo roadmap: Yes |
| Suggested split | Apply now: local `project_records` persistence only. Later changes: public Firestore contract, Firebase Function RTDB bridge, optional attribution copy. |
| Delivery strategy | single-repo Batch 1 now; decide chain strategy before any later cross-repository batch |
| Chain strategy | not required for Batch 1 |

Decision needed before apply: No for Batch 1
Chained PRs recommended: No for Batch 1
Chain strategy: not required for Batch 1
400-line budget risk: Low for Batch 1

## Work-unit boundaries

| Work unit | Finish state | Verification | Rollback boundary |
|---|---|---|---|
| Batch 1: local registry repair | Analyzer/registry saves durable `ProjectRecord` rows in local SQLite only. | Focused registry tests plus `flutter analyze`. | Revert `lib/services/local_db.dart`, optional narrow seams in `lib/services/project_registry_service.dart` / `lib/features/analyzer/presentation/screens/analyzer_screen.dart`, `lib/models/project_record.dart`, and new focused tests. |
| Batch 2: public Firestore contract | `erbolamm-hub` `project_registry/{projectId}` contract is modeled/documented separately from local `ProjectRecord`. | Contract/model tests or rules checks in the chosen hub root. | Remove contract/model/rule additions; local registry remains intact. |
| Batch 3: Firebase Function bridge | Privileged hub Function projects validated public fields idempotently into RTDB `nodes`/`edges`. | Function tests plus emulator or controlled manual projection evidence. | Disable/revert Function and remove derived RTDB projection data; Firestore remains canonical. |
| Batch 4: optional attribution copy | Universo copy can mention Studio without graph data. | Copy/render test or structural readback. | Revert copy only. |

## Batch 1 — Apply-ready: local `project_records` persistence

### RED

- [x] Add failing focused SQLite tests in `test/services/local_database_project_records_test.dart` for creating the `project_records` table, inserting a complete `ProjectRecord`, reopening the same database, and reading the same record back through `LocalDatabase`. <!-- sdd-owner: implementation -->
- [x] Extend `test/services/local_database_project_records_test.dart` with failing coverage for replace-by-`id`, delete-by-`id`, `updatedAt DESC` listing, filters by `ProjectType`, `TechStack`, `isOwned`, `isPublic`, stale records with `lastAnalyzedAt IS NULL` or older than a `Duration`, and JSON list round-trips containing commas and `||`. <!-- sdd-owner: implementation -->
- [x] Add failing service-level tests in `test/services/project_registry_service_test.dart` proving `ProjectRegistryService.upsertProject`, `getProject`, `getAllProjects`, `deleteProject`, filtered queries, `getProjectsNeedingAttention`, and `getStats` delegate successfully to implemented `LocalDatabase` methods. <!-- sdd-owner: implementation -->
- [x] Add a focused Analyzer save test in `test/features/analyzer/analyzer_registry_save_test.dart` or a narrower discovered helper test target proving Analyzer-created `ProjectRecord` saves through `ProjectRegistryService` locally and does not introduce Firestore, RTDB `nodes`, or RTDB `edges` writes. <!-- sdd-owner: implementation -->

### GREEN

- [x] Update `lib/services/local_db.dart` to open SQLite version `2`, keep creating the legacy `projects` table, create/migrate the new `project_records` table, and add the required indexes idempotently in `onCreate` and `onUpgrade`. <!-- sdd-owner: implementation -->
- [x] Add the smallest test database seam to `lib/services/local_db.dart` so tests can use an injected open sqflite FFI database or temporary path while production `LocalDatabase.instance` continues using `getApplicationDocumentsDirectory()`. <!-- sdd-owner: implementation -->
- [x] Implement private `ProjectRecord` row mappers in `lib/services/local_db.dart` or backward-compatible JSON list handling in `lib/models/project_record.dart` so `patternViolations` and `topics` are stored as JSON arrays for `project_records` while existing delimiter-based maps still decode safely. <!-- sdd-owner: implementation -->
- [x] Implement `upsertProjectRecord`, `getProjectRecord`, `getAllProjectRecords`, `deleteProjectRecord`, `getStaleProjectRecords`, `getProjectRecordsByType`, `getProjectRecordsByTechStack`, `getOwnedProjectRecords`, and `getPublicProjectRecords` in `lib/services/local_db.dart` with no Firestore or RTDB write path. <!-- sdd-owner: implementation -->
- [x] Update `LocalDatabase.close()` in `lib/services/local_db.dart` to close the active database and reset the cached static database reference to `null` so durability/reopen tests exercise persisted storage. <!-- sdd-owner: implementation -->
- [x] Keep `lib/services/project_registry_service.dart` behavior unchanged except for any minimal test seam required by the new focused tests; do not add remote publication behavior. <!-- sdd-owner: implementation -->
- [x] If required by the Analyzer save test, extract only the minimal conversion/save seam from `lib/features/analyzer/presentation/screens/analyzer_screen.dart` into a concrete helper target under `lib/features/analyzer/` while preserving current UI behavior and keeping the save local-only. <!-- sdd-owner: implementation -->

### TRIANGULATE

- [x] Run `flutter test test/services/local_database_project_records_test.dart` and add missing edge-case coverage if any required SQLite behavior is still unproven. <!-- sdd-owner: implementation -->
- [x] Run `flutter test test/services/project_registry_service_test.dart` and adjust only registry-local code until service-level registry behavior passes. <!-- sdd-owner: implementation -->
- [x] Run `flutter test test/features/analyzer/analyzer_registry_save_test.dart` or the discovered Analyzer helper test path and verify it proves local save behavior without remote publication. <!-- sdd-owner: implementation -->

### REFACTOR

- [x] Run `dart format lib/services/local_db.dart lib/services/project_registry_service.dart lib/models/project_record.dart test/services/local_database_project_records_test.dart test/services/project_registry_service_test.dart test/features/analyzer/analyzer_registry_save_test.dart` on only existing/changed paths. <!-- sdd-owner: implementation -->
- [x] Run `flutter analyze`; fix registry-caused issues and record unrelated baseline failures separately in apply progress if they exist. <!-- sdd-owner: implementation -->
- [x] Record Batch 1 evidence in the apply-progress artifact: changed files, focused test commands/results, `flutter analyze` result, runtime boundary as `N/A` for local SQLite-only repair, and rollback boundary. <!-- sdd-owner: implementation -->

## Deferred roadmap — not part of Batch 1 apply

The following roadmap remains intentionally out of the authorized Batch 1 apply scope. It must be converted into a new SDD change or a separately authorized follow-up before any cross-repository or remote-publication work starts.

- Canonical public Firestore contract: define `project_registry/{projectId}` in the maintained hub Firebase root after confirming the publisher identity and rules target.
- Privileged Firebase Function bridge: implement allowlist-only, idempotent projection from Firestore to RTDB only after the hub Functions workspace and archive/delete behavior are confirmed.
- Universo attribution copy: if desired later, scope copy-only changes separately and verify that no Studio graph node, edge, or card is created.

These notes are planning context, not unchecked implementation tasks for the current apply batch.

## Parent lifecycle and review notes

- Batch 1 was approved as the first under-400-line, single-repository work unit; after implementation the native ledger recorded 414 changed lines, the maintainer authorized a reset/rescope, and post-reset verification completed under the rescope.
- Choose `stacked-to-main` or `feature-branch-chain` before creating any later cross-repository/chained PR work.
- Confirm later-slice bridge decisions before remote work starts: authorized publisher identity, first real projection project if any, and unpublished/archived cleanup behavior.
- Start or reuse bounded review after Batch 1 implementation evidence is recorded and before merging or moving to remote publication batches.
