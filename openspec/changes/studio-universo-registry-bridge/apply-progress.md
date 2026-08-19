# Apply Progress: Studio to Universo Registry Bridge

## Batch 1 — local `project_records` persistence

Status: implementation complete for Batch 1 local SQLite registry repair.

## Structured status consumed

- Change: `studio-universo-registry-bridge`
- Artifact store: OpenSpec repo-local
- Native status supplied by parent: `apply: ready` after Batch 1 scope narrowing
- Runtime attempt: already acquired by parent; token/revision `sha256:b4c9b87dabe32debdaabc3ee3c82b2df2ba63abc5678bca8c724d10ccf65cea4`
- Work unit: `batch-1-local-project-records`
- Evidence goal: `local-project-records-persistence-tests-and-analyze`
- Action context: edits stayed under `/Users/apliarte/trabajo/erbolamm-studio`; no remote/Universo/Firebase publication work performed
- Workload/PR boundary: Batch 1 only. Remote contract, Firebase Function bridge, RTDB projection, and attribution copy remain deferred.

## Completed tasks and persisted checkboxes

All Batch 1 implementation-owned tasks in `openspec/changes/studio-universo-registry-bridge/tasks.md` were marked `- [x]`, covering RED, GREEN, TRIANGULATE, and REFACTOR rows. Parent-owned lifecycle rows were preserved and remain deferred.

## Files changed

- `lib/services/local_db.dart`
- `lib/models/project_record.dart`
- `lib/features/analyzer/analyzer_registry_mapper.dart`
- `lib/features/analyzer/presentation/screens/analyzer_screen.dart`
- `test/services/local_database_project_records_test.dart`
- `test/services/project_registry_service_test.dart`
- `test/features/analyzer/analyzer_registry_save_test.dart`
- `openspec/changes/studio-universo-registry-bridge/tasks.md`
- `openspec/changes/studio-universo-registry-bridge/apply-progress.md`

## Implementation notes

- `LocalDatabase` now opens schema version 2, creates/migrates `project_records`, and preserves the legacy `projects` table.
- Added idempotent indexes for `updatedAt`, `lastAnalyzedAt`, `type`, `techStack`, `isOwned`, and `isPublic`.
- Implemented all `ProjectRegistryService`-expected local CRUD/query methods with no Firestore, RTDB, `nodes`, or `edges` write path.
- Added a temporary-path SQLite test seam while preserving production `LocalDatabase.instance` behavior.
- `close()` now closes the cached DB handle and resets it to `null` so reopen tests prove durability.
- `ProjectRecord.toMap/fromMap` stores `patternViolations` and `topics` as JSON arrays and still decodes legacy delimiter strings.
- Extracted Analyzer-to-registry mapping into `lib/features/analyzer/analyzer_registry_mapper.dart`; Analyzer screen save/orchestrator paths call that helper and remain local-only.

## TDD Cycle Evidence

| Task group | Test file | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| SQLite schema/persistence | `test/services/local_database_project_records_test.dart` | Unit/integration over sqflite FFI | N/A (new focused test) | Failed first: missing `LocalDatabase` seam and project-record methods | Passed: 2/2 | Covered schema, reopen, JSON list round-trip, replace/delete/list/filter/stale | `dart format` run; tests rerun passing |
| Registry service delegation | `test/services/project_registry_service_test.dart` | Unit/integration over real local DB | N/A (new focused test) | Failed first: service called missing `LocalDatabase` methods | Passed: 1/1 | Covered CRUD, filters, attention, stats | `dart format` run; tests rerun passing |
| Analyzer local save seam | `test/features/analyzer/analyzer_registry_save_test.dart` | Unit/integration over mapper + service + DB | N/A (new focused test/helper) | Failed first: missing analyzer mapper and DB methods | Passed: 1/1 | Covered Analyzer-derived values, local durability, and absence of `nodes`/`edges` tables | `dart format` run; tests rerun passing |

## Verification commands

- `flutter test test/services/local_database_project_records_test.dart` — PASS, 2/2 tests.
- `flutter test test/services/project_registry_service_test.dart` — PASS, 1/1 test.
- `flutter test test/features/analyzer/analyzer_registry_save_test.dart` — PASS, 1/1 test.
- `dart format lib/services/local_db.dart lib/models/project_record.dart lib/features/analyzer/analyzer_registry_mapper.dart lib/features/analyzer/presentation/screens/analyzer_screen.dart test/services/local_database_project_records_test.dart test/services/project_registry_service_test.dart test/features/analyzer/analyzer_registry_save_test.dart` — completed.
- `flutter analyze` — FAILS only on unrelated baseline issues. No registry/local persistence errors remain. Baseline blockers include missing `flutter_secure_storage` dependency for `lib/services/ai_providers_service.dart`, existing lints in animation/music/orchestrator/marketing files, and existing unused import in `test/publisher/publisher_service_test.dart`.

## Deviations from design

- Used backward-compatible JSON list handling in `ProjectRecord.toMap/fromMap` rather than private row mappers in `LocalDatabase`; this matches the allowed design alternative and keeps the database service smaller.
- Added the narrow Analyzer mapper helper because the existing conversion lived in private widget state and needed focused coverage without a broad widget test.

## Runtime boundary

N/A — Batch 1 is local SQLite persistence only. No Firebase, RTDB, Universo graph, or publication runtime boundary was touched.

## Rollback boundary

Revert the local registry repair files listed above. This removes the version-2 `project_records` implementation/tests and Analyzer mapper seam without touching remote publication, RTDB data, Firestore contracts, Firebase Functions, or Universo UI.

## Remaining tasks

Implementation-owned Batch 1 tasks: none.

Parent-owned lifecycle/deferred rows still unchecked:

```text
- [ ] Choose `stacked-to-main` or `feature-branch-chain` before creating any later cross-repository/chained PR work. <!-- sdd-owner: parent -->
- [ ] Confirm later-slice bridge decisions before remote work starts: authorized publisher identity, first real projection project if any, and unpublished/archived cleanup behavior. <!-- sdd-owner: parent -->
- [ ] Start or reuse bounded review after Batch 1 implementation evidence is recorded and before merging or moving to remote publication batches. <!-- sdd-owner: parent -->
```

## Risks / follow-ups

- Broad `flutter analyze` is blocked by unrelated baseline errors in `lib/services/ai_providers_service.dart` (`flutter_secure_storage` missing) and existing non-registry lint findings.
- Authored changed-line count may exceed the original ~250-380 forecast once focused tests and formatting are included; parent should decide review handling before delivery.

## Post-reset verification evidence

A maintainer authorized the native reset after the first attempt exceeded the 400-line forecast by 14 lines. The post-reset verification attempt reused the implemented Batch 1 candidate and ran the focused registry evidence again.

- Native reset revision before reset: `sha256:b4902e2157325d6a752136171d9e2f12fab1fb7428c7455e7bc75839b289b731`.
- New attempt token/revision: `sha256:b2b6df1c802a9a516f72aae345bd65e2b4009011041c6565b5fbdf0c76c848ed`.
- `flutter test test/services/local_database_project_records_test.dart` — PASS, 2/2 tests.
- `flutter test test/services/project_registry_service_test.dart` — PASS, 1/1 test.
- `flutter test test/features/analyzer/analyzer_registry_save_test.dart` — PASS, 1/1 test.
- `flutter analyze` — still FAILS on 28 unrelated baseline issues; no local registry/project_records errors were reported.
- Verification log: `/tmp/studio-batch1-post-reset-verification.log`.
