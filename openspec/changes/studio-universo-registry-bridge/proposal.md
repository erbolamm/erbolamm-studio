# Proposal: Studio to Universo Registry Bridge

## Executive summary

Repair Studio's local project registry first, then define a canonical public-project contract in Firestore and project approved public fields into Universo's RTDB graph through a privileged Firebase Function in the shared `erbolamm-hub` project.

This keeps Studio from writing RTDB directly, preserves Universo's current anonymous landing and 3D graph behavior, and avoids publishing `erbolamm-studio` itself as a Universe node/card.

## Problem statement

Studio already turns Analyzer output into a `ProjectRecord`, but that save path is not reliable: `ProjectRegistryService` calls local database methods that `LocalDatabase` does not implement, and the local database only creates the legacy `projects` table. Any remote publication built on top of this would publish from a broken or non-durable local source.

Universo currently renders public project cards and the 3D graph from RTDB `nodes` and `edges`. Firestore exists in the hub project, but it is not the anonymous public-project source today. Directly changing only the landing page to Firestore would leave the 3D graph stale; letting Studio write RTDB directly would rely on an unsafe authenticated create loophole and make RTDB canonical again.

## Intent

Create an incremental, reviewable path from Studio's local `ProjectRecord` persistence to a safe public Universo projection:

1. Make Studio's local registry durable and unblock Analyzer save.
2. Define canonical Firestore `project_registry/{projectId}` documents as the future source for publishable projects.
3. Add a hub-owned privileged bridge that validates canonical documents and projects only allowlisted public fields to RTDB `nodes` and `edges`.
4. Keep `erbolamm-studio` out of Universo as a project node/card; if Universo landing copy changes later, it may attribute that the universe was created or organized with ErBolamm Studio.

## User decisions incorporated

| Decision | Proposal impact |
|---|---|
| Shared Firebase project is `erbolamm-hub`. | Firestore canonical docs and the bridge belong to the hub project. |
| Bridge runtime is a Firebase Function. | Projection is implemented as a privileged hub-owned Function, not a client write path. |
| Bridge is preferred over direct Firestore landing reads for actual Universe graph publication. | RTDB remains the derived read model for current landing and 3D consumers. |
| `erbolamm-studio` must not be published as a Universe node/card. | No `nodes/erbolamm-studio` and no Studio edge are in scope. |
| First implementation prerequisite is Studio local `project_records` persistence. | Remote sync/publication waits until local registry persistence is repaired. |

## Goals

- Persist `ProjectRecord` locally through `LocalDatabase` and `ProjectRegistryService`.
- Stop Analyzer's save path from failing because of missing local database methods.
- Establish canonical Firestore `project_registry/{projectId}` as the future source of publishable projects.
- Define a minimal public projection contract with these allowlisted fields:
  - `id`
  - `label`
  - `subtitle`
  - `url`
  - `type`
  - `status`
  - `pillar`
  - `emoji`
  - `color`
  - `size`
  - optional `stats.downloads`
- Project only validated, publishable projects from Firestore to RTDB `nodes`/`edges` through a Firebase Function.
- Preserve Universo's current anonymous RTDB read path for landing and 3D graph consumers.

## Non-goals

- Do not publish `erbolamm-studio` as a Universe node/card.
- Do not create `nodes/erbolamm-studio` or any Studio-related Universe `edges` entry.
- Do not make Studio write RTDB directly.
- Do not rely on RTDB's authenticated `nodes` create loophole.
- Do not migrate Universo landing or 3D graph clients to read Firestore directly in this first slice.
- Do not copy full `ProjectRecord` or internal analysis fields into public RTDB data.
- Do not implement broad remote sync before local `project_records` persistence works.

## Scope

### First slice: local registry repair

- Add the `project_records` local schema to `LocalDatabase`.
- Implement the registry CRUD/query methods expected by `ProjectRegistryService`.
- Preserve the existing Analyzer flow, but make its project-record save path durable and testable.
- Treat this as the prerequisite for any later remote publication work.

### Second slice: canonical publication contract

- Define the Firestore document shape for `project_registry/{projectId}`.
- Keep the public projection minimal and explicit.
- Separate private/local analysis metadata from public Universo fields.
- Define publishability rules, including that only projects meant to appear in Universo are projected.

### Third slice: Firebase Function bridge

- Add a Firebase Function in `erbolamm-hub` that reacts to canonical Firestore project registry changes or runs an equivalent controlled projection path.
- Validate canonical docs before projection.
- Write only allowlisted public fields to RTDB `nodes` and the required public graph edge entries.
- Make projection idempotent so repeated writes do not duplicate graph data.

### Optional later slice: Universo attribution copy

- If later scoped by spec/tasks, update Universo landing copy to explain that the universe was created or organized with ErBolamm Studio.
- This is attribution/copy only, not a Studio node/card.

## Affected areas

- `lib/services/local_db.dart` — add `project_records` schema and registry persistence methods.
- `lib/services/project_registry_service.dart` — continue as the local durable registry facade.
- `lib/features/analyzer/presentation/screens/analyzer_screen.dart` — Analyzer save path should remain explicit and stop failing on missing persistence methods.
- `lib/models/project_record.dart` — may need future public projection metadata, but must not expose internal analysis wholesale.
- `erbolamm-hub` Firebase configuration/deployment — hosts Firestore canonical registry and Firebase Function bridge.
- Universo RTDB `nodes`/`edges` — remains a derived public read model.
- Universo landing/3D consumers — should continue working from RTDB unless a later spec scopes a client migration.

## Security boundary

Studio must not write RTDB directly. The existing RTDB authenticated create loophole for `nodes` is not a safe publication mechanism and must not be relied on, broadened, or treated as authorization.

The intended boundary is:

1. Studio maintains durable local `ProjectRecord` state.
2. A restricted publisher path writes canonical Firestore `project_registry/{projectId}` documents in `erbolamm-hub`.
3. A privileged Firebase Function validates canonical documents and writes the derived public RTDB projection.
4. Anonymous clients read only public RTDB `nodes`/`edges` data.

Every projection must be allowlist-based. Internal analysis, owner-only metadata, secrets, local paths, and non-public workflow data must remain outside RTDB.

## Incremental delivery plan

| Slice | Outcome | Review boundary | Rollback boundary |
|---|---|---|---|
| 1. Local registry repair | Analyzer can persist `ProjectRecord` locally through `ProjectRegistryService`. | Studio local DB schema, service methods, focused persistence tests. | Revert local schema/service changes without touching remote publication. |
| 2. Publication contract | Canonical Firestore `project_registry/{projectId}` public projection is documented and modeled. | Schema/rules/model changes only; no RTDB writes yet unless explicitly scoped. | Remove contract/model/rule additions without affecting local registry. |
| 3. Bridge projection | Firebase Function validates canonical docs and writes derived RTDB `nodes`/`edges`. | Function, validation tests, emulator/manual projection evidence. | Disable/revert Function and delete derived RTDB entries; Firestore remains canonical. |
| 4. Optional attribution copy | Universo can describe Studio as the organizing tool without adding a Studio card. | Landing copy only. | Revert copy; graph data unchanged. |

## Rollback plan

- If local persistence fails, revert the `project_records` schema/method changes and keep remote publication out of scope.
- If canonical Firestore publication is incorrect, stop publisher writes and update/remove affected `project_registry/{projectId}` docs before any projection.
- If the bridge projects bad data, disable the Firebase Function, delete the affected derived RTDB `nodes`/`edges`, and re-run projection from corrected Firestore docs.
- Because RTDB is derived, it should be rebuildable from Firestore canonical documents after bridge fixes.
- No rollback path should require deleting a Studio node/card because this proposal explicitly excludes creating one.

## Success criteria

- Analyzer save no longer fails because `ProjectRegistryService` calls missing `LocalDatabase` methods.
- Studio persists and retrieves `ProjectRecord` data from local `project_records` storage.
- The proposal/spec defines `project_registry/{projectId}` as the canonical future source for publishable project records.
- The public projection contract includes only the approved allowlisted fields.
- Studio has no RTDB write path for publication.
- The bridge design uses a privileged Firebase Function in `erbolamm-hub`.
- Projected Universo entries are limited to projects that belong in Universo.
- No `erbolamm-studio` RTDB node or edge is created.
- Any Universo attribution to Studio is copy-only and separately scoped.

## Proposal question round

The continuation supplied the blocking product decisions needed to finalize this proposal. The remaining questions should be answered during spec/design if those slices are selected:

1. Which exact status values make a Firestore project publishable versus draft/archived/internal?
2. Which restricted publisher identity is allowed to create or update `project_registry/{projectId}` in `erbolamm-hub`?
3. What first real project, if any, should be used to verify projection into Universo, including its public label, URL, pillar, and graph edge target?
4. Should RTDB projection delete archived/unpublished nodes immediately, mark them archived, or preserve them until a manual cleanup step?

## Risks

- Local persistence may expose existing baseline test failures; verification must distinguish repaired registry behavior from unrelated failures.
- Bridge drift is possible if projection is not idempotent, observable, and replayable.
- Public RTDB reads make every projected field public, so validation must reject unallowlisted or private fields.
- Firebase Functions deployment introduces a new operational surface in `erbolamm-hub`.
- Firestore publisher authorization remains a design/spec dependency before safe remote writes.

## Result contract

- `status`: success
- `executive_summary`: Repair Studio local `ProjectRecord` persistence first, then use canonical Firestore documents and a privileged Firebase Function bridge to project approved public projects into Universo RTDB without creating a Studio node/card.
- `artifacts`:
  - `openspec/changes/studio-universo-registry-bridge/proposal.md`
- `next_recommended`: spec
- `risks`:
  - Firestore publisher identity and rules must be specified before remote writes.
  - Bridge projection must be idempotent and allowlist-only.
  - RTDB authenticated create loophole must not be used.
  - Existing local persistence baseline is broken and must be repaired first.
- `skill_resolution`: paths-injected
