## Exploration: studio-universo-registry-bridge

### Current State
`erbolamm-hub` is the deployed Firebase project for Universo (`.firebaserc`). Universo initializes both Firestore and RTDB from environment configuration. Its public landing reads RTDB `nodes` anonymously in `App.tsx`, turns them into ecosystem cards, and excludes archived entries. Its 3D scene also consumes the node/edge graph through `useUniverseNodes` and `Universe3D`; a newly published project must therefore exist in RTDB `nodes` and have a connecting `edges` entry to appear in both public surfaces.

Firestore is already initialized in Universo but is not the public-project source. Existing Firestore rules require authentication for every readable collection, including `/global/{docId}`; there is no anonymous canonical-project read path. RTDB rules allow anonymous reads of `nodes` and `edges`, while their write rules are privileged except for the unsafe create exception on `nodes` (`!data.exists()`). That exception must not be used by Studio.

Studio has `ProjectRecord` and `ProjectRegistryService`, and Analyzer converts a completed analysis into a record before calling the registry. The persistence boundary is broken: `ProjectRegistryService` calls eight `LocalDatabase` methods that do not exist, and `LocalDatabase` only creates the legacy `projects` table. Studio has Firestore packages but no generated Firebase options or Firebase deployment configuration; `Firebase.initializeApp()` falls back to local mode when configuration is unavailable.

### Affected Areas
- `erbolamm-studio/lib/services/local_db.dart` — must define the `project_records` schema and all registry CRUD/query methods before an analyzed record can be reliably published.
- `erbolamm-studio/lib/services/project_registry_service.dart` — existing local registry façade becomes the durable pre-publication boundary.
- `erbolamm-studio/lib/features/analyzer/presentation/screens/analyzer_screen.dart` — already creates a `ProjectRecord`; publication must be explicit rather than implied by analysis/save.
- `erbolamm-studio/lib/models/project_record.dart` — has useful analysis fields but lacks an explicit Universo projection contract such as pillar, public status, and stable published metadata.
- `erbolamm-universo/src/App.tsx` — public landing projects currently derive solely from RTDB `nodes`.
- `erbolamm-universo/src/hooks/useUniverseNodes.ts` and `src/components/Universe3D.tsx` — the 3D graph requires RTDB nodes plus edges; it is not fed by `EcosystemSection` alone.
- `erbolamm-universo/firestore.rules` and `database.rules.json` — define the anonymous-read and privileged-write boundaries that the solution must preserve.
- `erbolamm-universo/firebase.json` — deploys Hosting, Firestore, RTDB, and Storage rules but contains no Functions/bridge deployment.

### Approaches
1. **Canonical Firestore with a privileged Firestore-to-RTDB projection bridge** — Studio writes a canonical public-project document to Firestore using a restricted publisher identity; a hub-owned privileged trigger/worker validates and projects the public node and edge into RTDB.
   - Pros: preserves the current anonymous landing and 3D behavior without modifying public read clients; Firestore is the single source of truth; RTDB becomes a deliberately derived legacy/presentation projection; no client receives RTDB write authority; supports idempotent re-projection, backfill, and later RTDB retirement.
   - Cons: adds a small privileged deployment and two representations; projection failures need observability and retry/replay.
   - Effort: Medium. The one-project slice is bounded: repair local persistence, publish one explicit canonical document, deploy one validated projection, and verify one node plus one edge on the existing landing and 3D scene.

2. **Change only `EcosystemSection`/landing to read canonical Firestore directly** — add a public Firestore collection/rule and map it to cards in the client.
   - Pros: fewer bridge components and no RTDB copy for landing cards.
   - Cons: does not publish the project into the existing 3D graph, which still reads RTDB nodes/edges; requires anonymous Firestore reads and a separate public projection/schema; creates two public discovery paths with different sources until 3D is also migrated; moving 3D to Firestore expands the blast radius through `useUniverseNodes`, graph edges, and layout behavior.
   - Effort: Medium for landing-only but High for feature parity. It is not the smallest safe end-to-end slice because landing success would conceal 3D absence.

3. **Have Studio write RTDB directly** — serialize `ProjectRecord` into `nodes` and `edges` from the desktop client.
   - Pros: smallest apparent client code path and immediately exercises both existing public surfaces.
   - Cons: makes RTDB canonical again, duplicates no canonical Firestore source, and relies on a client privilege boundary. The current `nodes` rule allows any authenticated user to create a missing node, so it cannot safely authorize Studio publication; broadening it or embedding privileged credentials would worsen security.
   - Effort: Low implementation effort, unacceptable security/maintenance cost.

### Recommendation
Choose **canonical Firestore plus a privileged Firestore-to-RTDB projection bridge**. It is the smallest safe one-project end-to-end vertical slice: Universo needs no source change for either the anonymous landing or the 3D universe because both already react to RTDB `nodes`/`edges`; RTDB is explicitly retained only as a derived legacy/presentation read model. The bridge has a narrowly auditable security boundary and the duplicated RTDB data is intentional, limited, and rebuildable from Firestore.

Changing `EcosystemSection` to Firestore directly is lower code only if product scope excludes 3D. It is not lower total cost for the approved public-project flow: it introduces anonymous Firestore-read rules, leaves 3D stale, and eventually requires a second graph migration. Do not use the existing RTDB authenticated-create exception as a shortcut.

### Risks
- The bridge must be idempotent, validate a minimal allowlisted public schema, and report/retry projection failures; otherwise Firestore and the RTDB projection can drift.
- Anonymous RTDB reads make every projected node/edge public. The bridge must exclude internal analysis, owner-only fields, and secrets rather than copying `ProjectRecord` wholesale.
- Studio’s local registry repair is a prerequisite, not cleanup: today Analyzer reports success after calling methods absent from `LocalDatabase`.
- The existing test/analyzer baseline is already red because of the missing database methods, so regression proof must distinguish the repaired registry from unrelated baseline failures.

### Genuine Product/Configuration Blockers
- **Hub publisher configuration:** Studio has no checked-in Firebase options/deployment target, and its macOS path intentionally permits local mode. A verified `erbolamm-hub` client configuration plus a restricted authenticated publisher identity are required before Studio can write canonical Firestore safely.
- **Public-project contract for the first project:** choose the explicit public values the projection cannot infer reliably: stable project ID, display name/description, public URL, pillar, type, status, and whether an edge to `erbolamm` is wanted. These are publication content decisions, not implementation defaults.
- **Privileged bridge runtime:** Universo has no Functions configuration or existing worker. A hub-owned deployment location, service identity, and operational owner for the Firestore trigger/worker must be selected before the bridge can be deployed.
- **Rules deployment:** Firestore rules must permit only the designated publisher to create/update the canonical public-project collection; RTDB rules should retain anonymous reads but remove or avoid reliance on the authenticated-create loophole for `nodes` before publication.

### Ready for Proposal
Yes — after the four blockers above are confirmed. The proposal should scope the first slice to repaired Studio `ProjectRecord` persistence, one explicit canonical Firestore document, one privileged validated RTDB node/edge projection, and verification in Universo’s anonymous landing and 3D view. It should not migrate Universo clients to Firestore or expose generic Firestore public reads.
