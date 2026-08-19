# Design: Studio to Universo Registry Bridge

## Decision

Implement this change incrementally. Slice 1 only repairs Studio's local `ProjectRecord` persistence in SQLite. Remote publication stays out of the first implementation slice. Later slices define a canonical Firestore public-project contract in `erbolamm-hub` and use a privileged Firebase Function to project validated public fields into Universo's RTDB `nodes` and `edges` read model.

This keeps Analyzer saves durable, avoids coupling local Studio data to remote public graph data, preserves Universo's existing anonymous RTDB landing and 3D graph consumers, and prevents `erbolamm-studio` from becoming a Universo node/card.

## Scope by slice

| Slice | Implementation boundary | Explicitly out of scope |
|---|---|---|
| 1. Local registry repair | `LocalDatabase` creates/migrates `project_records` and implements the methods already called by `ProjectRegistryService`. Focused local tests and `flutter analyze`. | Firestore writes, RTDB writes, Firebase Functions, Universo copy changes. |
| 2. Public registry contract | Define/model `erbolamm-hub` Firestore `project_registry/{projectId}` as the canonical future public-project source. | RTDB projection runtime unless separately scoped. |
| 3. Bridge projection | Add a hub-owned Firebase Function that validates Firestore documents and idempotently projects only allowlisted public data to RTDB `nodes`/`edges`. | Studio direct RTDB writes; publishing `erbolamm-studio`. |
| 4. Optional attribution copy | Copy-only Universo mention that Studio helped create/organize the universe. | Graph data, Studio node/card, publication evidence. |

## Slice 1 design: local SQLite registry

### Files likely to change

| File | Change |
|---|---|
| `lib/services/local_db.dart` | Add DB versioning, `project_records` table creation/migration, registry CRUD/query methods, row mapping helpers, and test database hook/close reset. |
| `lib/services/project_registry_service.dart` | Prefer no behavior change. Only adjust if a small injectable/test seam is needed. |
| `lib/models/project_record.dart` | Prefer no domain field changes. Optional only if serialization helpers must become robust to JSON list strings. |
| `test/services/local_database_project_records_test.dart` | New focused SQLite tests for create/read/update/delete/query/reopen behavior. |
| `test/services/project_registry_service_test.dart` | New or focused service-level test proving calls no longer hit missing `LocalDatabase` methods. |
| `test/features/analyzer/...` or widget/bloc-adjacent focused test | Optional if feasible in this slice; otherwise cover Analyzer conversion/save through a narrow helper/service seam. |

### SQLite schema

Add `project_records` alongside the existing legacy `projects` table. Do not remove or rewrite `projects` in slice 1.

```sql
CREATE TABLE IF NOT EXISTS project_records (
  id TEXT PRIMARY KEY,
  owner TEXT NOT NULL,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  type TEXT NOT NULL,
  techStack TEXT NOT NULL,
  language TEXT,
  patternVersion TEXT,
  patternCompliant INTEGER NOT NULL DEFAULT 0,
  patternViolations TEXT NOT NULL DEFAULT '[]',
  lastCommitAt TEXT,
  lastAnalyzedAt TEXT,
  currentVersions TEXT,
  latestVersions TEXT,
  hasReadme INTEGER NOT NULL DEFAULT 0,
  hasLicense INTEGER NOT NULL DEFAULT 0,
  hasScreenshots INTEGER NOT NULL DEFAULT 0,
  hasVideo INTEGER NOT NULL DEFAULT 0,
  hasLanding INTEGER NOT NULL DEFAULT 0,
  hasBrandSpec INTEGER NOT NULL DEFAULT 0,
  isOwned INTEGER NOT NULL DEFAULT 1,
  isPublic INTEGER NOT NULL DEFAULT 1,
  license TEXT,
  topics TEXT NOT NULL DEFAULT '[]',
  description TEXT,
  addedAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_project_records_updated_at ON project_records(updatedAt);
CREATE INDEX IF NOT EXISTS idx_project_records_last_analyzed_at ON project_records(lastAnalyzedAt);
CREATE INDEX IF NOT EXISTS idx_project_records_type ON project_records(type);
CREATE INDEX IF NOT EXISTS idx_project_records_tech_stack ON project_records(techStack);
CREATE INDEX IF NOT EXISTS idx_project_records_owned ON project_records(isOwned);
CREATE INDEX IF NOT EXISTS idx_project_records_public ON project_records(isPublic);
```

`LocalDatabase` should open version `2`. New databases create both `projects` and `project_records`; existing version-1 databases run `onUpgrade` with idempotent `CREATE TABLE IF NOT EXISTS` and index statements.

### Required `LocalDatabase` methods

Implement the methods already expected by `ProjectRegistryService`:

| Method | Query behavior |
|---|---|
| `upsertProjectRecord(ProjectRecord project)` | Insert or replace by `id`. Preserve all local fields. Do not write remote data. |
| `getProjectRecord(String id)` | Return one record or `null`. |
| `getAllProjectRecords()` | Return all records ordered by `updatedAt DESC`. |
| `deleteProjectRecord(String id)` | Delete by `id`; void return is acceptable at service boundary. |
| `getStaleProjectRecords(Duration maxAge)` | Return records with `lastAnalyzedAt IS NULL` or older than `DateTime.now().subtract(maxAge)`, ordered by oldest/null first. |
| `getProjectRecordsByType(String type)` | Filter by stored enum name. |
| `getProjectRecordsByTechStack(String stack)` | Filter by stored enum name. |
| `getOwnedProjectRecords()` | Filter `isOwned = 1`. |
| `getPublicProjectRecords()` | Filter `isPublic = 1`. |

`close()` should close the active database and set the cached static database reference to `null`; otherwise reopen/durability tests can pass against an already-open handle instead of proving persisted storage.

### Testability seam

The current singleton opens the database through `getApplicationDocumentsDirectory()`, which is awkward in local unit tests. Add the smallest test seam in `LocalDatabase`, not a broad repository abstraction:

- allow tests to inject an already-open sqflite FFI database or a temporary path database;
- provide a reset/close helper for tests;
- keep production `LocalDatabase.instance` behavior unchanged.

This lets focused Dart/Flutter tests exercise real SQLite serialization without mocking the registry boundary away.

## Data mapping

### Local mapping rules

Slice 1 stores the full local `ProjectRecord` as local data only. The SQLite mapper must not introduce Firestore/RTDB fields such as `pillar`, `emoji`, `color`, `size`, graph edges, projection status, or publisher metadata.

| Field type | Storage rule |
|---|---|
| `String`, nullable `String` | Store as `TEXT`/`NULL`. |
| `ProjectType`, `TechStack` | Store enum `.name`; deserialize with existing safe fallback (`other`). |
| `bool` | Store as `INTEGER` `0`/`1`. |
| `DateTime` | Store ISO-8601 strings. Preserve nullable dates as `NULL`. |
| `List<String>` (`patternViolations`, `topics`) | Store JSON array strings, not delimiter-joined strings. Decode defensively. |

Prefer private mapper helpers in `LocalDatabase`, for example `_projectRecordToRow()` and `_projectRecordFromRow()`. If existing `ProjectRecord.toMap/fromMap` are reused, update them to remain backward-compatible with their current delimiter format while accepting JSON list strings. JSON is chosen because topic or violation text can contain commas or `||`, and preserving local analysis text is more important than keeping a fragile delimiter encoding.

### Remote coupling guard

Do not add public projection fields to `ProjectRecord` in slice 1. Local analysis data and public Universo publication are separate concepts:

- `ProjectRecord` remains Studio's private/local registry model.
- A future `PublicProjectRegistryDocument`/mapper owns the Firestore projection contract.
- RTDB output is produced only by the bridge, never by serializing `ProjectRecord` wholesale.

## Migration and versioning

Use SQLite DB version `2` for the local registry repair.

1. `onCreate`: create legacy `projects` and new `project_records` tables.
2. `onUpgrade` from `< 2`: add `project_records` and indexes idempotently.
3. Do not auto-migrate all legacy `projects` rows in slice 1. Existing legacy rows lack stable UUIDs and several `ProjectRecord` fields, so automatic conversion can create misleading registry data.
4. Keep `ProjectRegistryService.migrateLegacyProject()` as an explicit migration helper. A later cleanup can replace its current hash-based ID with a stronger deterministic ID if needed.

Tradeoff: this leaves legacy `projects` data separate for now, but it avoids silently fabricating incomplete public-ready project records. The first slice's success criterion is durable new `ProjectRecord` persistence, not legacy data normalization.

## Verification approach

Strict TDD is disabled in config for this change, but tests exist and should be used. Implement tests before or alongside the local database code where practical.

Focused verification for slice 1:

```bash
flutter test test/services/local_database_project_records_test.dart
flutter test test/services/project_registry_service_test.dart
flutter analyze
```

Test cases should cover:

- inserting and retrieving a complete `ProjectRecord`;
- replacing an existing record by `id`;
- deleting by `id`;
- listing all records by `updatedAt DESC`;
- filtering by type, tech stack, owned, public;
- stale query for null and old `lastAnalyzedAt`;
- list fields round-trip through JSON, including strings containing commas or `||`;
- closing/reopening the database and retrieving the same record;
- `ProjectRegistryService` methods delegate successfully to implemented local DB methods;
- Analyzer save remains local and does not call Firestore/RTDB publication code.

If `flutter analyze` or broad tests reveal unrelated baseline failures, record them separately. Registry-related tests must pass for the slice.

## Future public Firestore contract

Later publication slices should add a separate public contract instead of extending the local database schema prematurely.

Canonical location:

```text
erbolamm-hub Firestore: project_registry/{projectId}
```

Minimal public projection fields:

```json
{
  "id": "project-id",
  "label": "Public project name",
  "subtitle": "Short public description",
  "url": "https://public.example/project",
  "type": "project",
  "status": "published",
  "pillar": "tools",
  "emoji": "🛠️",
  "color": "#7C3AED",
  "size": 1,
  "stats": { "downloads": 0 }
}
```

Publication metadata that is needed for authorization, auditing, source linkage, projection status, or operations must be stored separately from the public projection fields, for example under a private subdocument or sibling private collection protected by Firestore rules. It must not be copied to RTDB.

Publishability rule for the bridge slice: only `status == "published"` is projectable. `draft`, `archived`, `internal`, missing, and unknown statuses are non-projectable by default. If product later wants more publishable statuses, the spec must be extended before implementation.

## Future Firebase Function bridge

### Files likely to change in later slices

Exact paths depend on where the `erbolamm-hub` Firebase deployment is maintained. Based on exploration, likely files are in the Universo/hub Firebase repo rather than Studio:

| File | Change |
|---|---|
| `../erbolamm-universo/firebase.json` or hub repo `firebase.json` | Add Functions deployment if not present. |
| `../erbolamm-universo/functions/package.json` | New Functions workspace dependencies/scripts. |
| `../erbolamm-universo/functions/src/index.ts` | Export bridge trigger. |
| `../erbolamm-universo/functions/src/projectRegistryBridge.ts` | Validate Firestore docs and write RTDB projection. |
| `../erbolamm-universo/functions/test/projectRegistryBridge.test.ts` | Emulator/unit tests for validation, idempotency, and delete/archive behavior. |
| `../erbolamm-universo/firestore.rules` | Restrict writes to `project_registry/{projectId}` to the authorized publisher identity. |
| `../erbolamm-universo/database.rules.json` | Keep anonymous reads and avoid relying on the authenticated create loophole. |
| `../erbolamm-universo/src/App.tsx`, `src/hooks/useUniverseNodes.ts`, `src/components/Universe3D.tsx` | No change expected for the bridge slice because RTDB remains the read model. Read-only verification may inspect these consumers. |

### Bridge behavior

Use a hub-owned Firebase Function trigger on `project_registry/{projectId}` writes or a controlled callable/scheduled projection path owned by Functions. The Function runs with privileged server credentials; Studio clients never receive RTDB write authority.

Processing steps:

1. Read canonical Firestore document and `projectId`.
2. Reject `projectId == "erbolamm-studio"` and any document intended to represent Studio as a graph project.
3. Validate required public fields and `status == "published"`.
4. Build an RTDB node using only the allowlisted public fields: `id`, `label`, `subtitle`, `url`, `type`, `status`, `pillar`, `emoji`, `color`, `size`, and optional `stats.downloads`.
5. Write the node to a deterministic path such as `nodes/{projectId}` with `set`/`update` semantics so reprocessing converges.
6. Write required graph edges to deterministic keys, for example `edges/{sourceId}_{targetId}_{type}` or another canonical edge ID. Never push anonymous edge IDs for projections.
7. For non-projectable documents, use the behavior defined by the bridge task before implementation: delete derived node/edges, mark archived, or leave for manual cleanup. Default design preference is delete derived entries for `archived`/`internal` and no-op for invalid drafts, but this must be confirmed in the bridge slice.
8. Log validation/projection results with enough detail for replay/debugging without logging private fields.

### Idempotency contract

Repeated processing of the same Firestore document must produce equivalent RTDB state:

- node path is deterministic (`nodes/{projectId}`);
- edge IDs are deterministic;
- writes are `set`/merge updates, not append-only `push` writes;
- unknown/private fields are ignored rather than mirrored;
- replay from Firestore can rebuild RTDB public projection.

## Universo attribution

Attribution remains optional copy and is not part of graph publication. It must not create:

- `project_registry/erbolamm-studio`;
- `nodes/erbolamm-studio`;
- any Studio edge;
- any Studio card in Universo.

A later copy-only slice can mention that the universe was created or organized with ErBolamm Studio, but that text is verified independently from local persistence and bridge projection.

## Tradeoffs and alternatives

| Alternative | Decision | Reason |
|---|---|---|
| Firestore canonical document + privileged RTDB bridge | Chosen for remote slices. | Preserves current Universo landing/3D behavior while keeping Firestore canonical and RTDB derived. |
| Change only Universo landing to read Firestore | Not chosen. | Leaves 3D graph stale and creates two discovery sources until a larger migration happens. |
| Studio writes RTDB directly | Rejected. | Unsafe client authority boundary and relies on the existing authenticated create loophole. |
| Store list fields with current delimiters | Rejected for new `project_records`. | Commas and `||` can appear in real topics/violations; JSON preserves local data. |
| Store full `ProjectRecord` as one JSON blob | Not chosen for slice 1. | Easier schema evolution, but harder to query by type/stack/stale/owned/public with SQLite. |
| Auto-migrate legacy `projects` rows | Deferred. | Legacy rows lack stable complete registry data; explicit migration is safer. |

## Rollback boundaries

- Slice 1 rollback: revert `local_db.dart`/test changes. Existing `projects` table remains untouched; no remote data exists.
- Public contract rollback: remove contract/model/rule additions before any bridge projection.
- Bridge rollback: disable Function and delete/rebuild derived RTDB `nodes`/`edges` from corrected Firestore documents.
- Attribution rollback: revert copy only; graph data is unaffected.

## Risks

- Existing singleton database design can make tests brittle unless a small test seam is added.
- JSON list mapping must be implemented defensively to avoid breaking any existing `ProjectRecord.fromMap()` call sites.
- Publisher identity and Firestore rules remain unresolved before remote Studio publication can be enabled.
- Archive/delete projection behavior needs final product confirmation in the bridge slice.
- The bridge must never treat RTDB as canonical or rely on Studio/client RTDB writes.
