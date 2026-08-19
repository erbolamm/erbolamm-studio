# Universo Registry Bridge Specification

## Purpose

A privileged Firebase Function in `erbolamm-hub` MUST be the approved runtime for projecting canonical Firestore public-project records into Universo's derived RTDB graph. Studio clients MUST NOT write RTDB publication data directly.

## Requirements

### Requirement: Firebase Function is the approved bridge runtime

The system MUST use a hub-owned privileged Firebase Function, or an equivalent Firebase Functions-controlled execution path, to project validated `project_registry/{projectId}` documents into RTDB `nodes` and `edges`.

#### Acceptance Criteria

- The bridge runtime MUST belong to the shared `erbolamm-hub` project.
- Studio clients MUST NOT receive direct RTDB write authority for publication.
- The bridge MUST preserve Universo's current anonymous RTDB read model for landing and 3D graph consumers.
- Firestore MUST remain canonical and RTDB MUST be treated as a derived public read model.

#### Scenario: Project through the bridge instead of Studio

- GIVEN a canonical Firestore project document is eligible for public publication
- WHEN the project is published to Universo's current graph surfaces
- THEN a privileged Firebase Function MUST perform the RTDB write
- AND Studio MUST NOT write RTDB `nodes` or `edges` directly.

### Requirement: Allowlist-only public projection

The bridge MUST validate canonical documents and write only allowlisted public fields into RTDB.

#### Acceptance Criteria

- The bridge MUST validate required public fields before writing a node or edge.
- The bridge MUST project only the approved public field allowlist from the canonical contract.
- The bridge MUST reject, ignore, or fail safely when a document contains invalid required values.
- The bridge MUST NOT copy internal analysis, owner-only fields, local paths, secrets, or workflow-private data to RTDB.

#### Scenario: Validate before public write

- GIVEN a canonical project document contains missing required fields, invalid public field values, or private fields
- WHEN the bridge evaluates the document
- THEN it MUST NOT publish invalid or private data to RTDB
- AND any derived RTDB output MUST contain only validated allowlisted public fields.

### Requirement: Idempotent RTDB graph projection

The bridge MUST write derived RTDB `nodes` and required public `edges` idempotently so repeated processing of the same eligible Firestore document does not duplicate or corrupt graph data.

#### Acceptance Criteria

- Re-processing the same canonical document MUST converge on the same RTDB node and edge state.
- The bridge MUST NOT create duplicate edges for repeated events.
- The bridge MUST provide verification or operational evidence that projection can be replayed safely.
- Behavior for unpublished or archived documents MUST be explicitly designed before remote bridge implementation.

#### Scenario: Re-run projection safely

- GIVEN an eligible canonical project document has already been projected
- WHEN the bridge processes the same document again without public-field changes
- THEN the RTDB node and edge state MUST remain equivalent
- AND no duplicate edge MUST be created.

### Requirement: No Studio graph publication

The system MUST NOT publish `erbolamm-studio` as a Universo project, node, edge, or card as part of this change.

#### Acceptance Criteria

- No RTDB `nodes/erbolamm-studio` entry MUST be created.
- No RTDB `edges` entry connecting Studio as a graph project MUST be created.
- Universo landing and 3D graph consumers MUST NOT receive a Studio project card from this change.
- Any future Studio mention MUST use copy-only attribution and MUST NOT be graph data.

#### Scenario: Prevent Studio from appearing as a graph project

- GIVEN the bridge is deployed or local persistence is repaired
- WHEN project data is evaluated for Universo publication
- THEN `erbolamm-studio` MUST NOT be emitted as an RTDB node
- AND no Studio-related RTDB edge MUST be emitted
- AND no Universe card MUST be produced for Studio.

### Requirement: Bridge verification is remote-slice scoped

Bridge implementation slices MUST include validation evidence appropriate to Firebase Functions and RTDB projection, while the local persistence slice MAY defer this evidence.

#### Acceptance Criteria

- Bridge tasks MUST include validation tests, emulator evidence, or controlled manual projection evidence before enabling public projection.
- Verification MUST confirm that invalid or unallowlisted fields are not written to RTDB.
- Verification MUST confirm that Studio has no direct RTDB publication path.
- The first local persistence slice MUST NOT be blocked by bridge verification that has not yet been implemented.

#### Scenario: Verify bridge behavior in its own slice

- GIVEN the bridge slice is implemented
- WHEN bridge verification runs
- THEN it MUST demonstrate allowlist validation and idempotent RTDB projection
- AND it MUST demonstrate that Studio does not write RTDB publication data directly.
