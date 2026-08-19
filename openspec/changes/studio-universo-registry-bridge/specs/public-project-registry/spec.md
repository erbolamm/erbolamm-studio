# Public Project Registry Specification

## Purpose

`erbolamm-hub` Firestore `project_registry/{projectId}` documents MUST be the future canonical source for publishable public projects. This contract is separate from Studio's local `ProjectRecord` persistence and exposes only the public fields approved for Universo projection.

## Requirements

### Requirement: Canonical Firestore public project document

The system MUST define `project_registry/{projectId}` in the shared `erbolamm-hub` Firestore project as the canonical document location for projects intended for future public publication.

#### Acceptance Criteria

- Each canonical document MUST use `projectId` as its stable document identifier.
- The canonical document MUST contain only fields needed to decide and perform public projection.
- The canonical document MUST NOT copy Studio's full local `ProjectRecord`, internal analysis results, local paths, owner-only metadata, secrets, or workflow-private data.
- Studio local persistence MUST work before any broad remote publication workflow depends on this collection.

#### Scenario: Define a canonical public project

- GIVEN a project is intended to become publishable in Universo
- WHEN its canonical record is created for future publication
- THEN it MUST be represented as `project_registry/{projectId}` in `erbolamm-hub` Firestore
- AND the document MUST exclude internal Studio-only fields.

### Requirement: Public projection field allowlist

The canonical public-project contract MUST identify the only fields that may be projected to public RTDB `nodes` and related public graph data.

#### Acceptance Criteria

- The public projection allowlist MUST be limited to: `id`, `label`, `subtitle`, `url`, `type`, `status`, `pillar`, `emoji`, `color`, `size`, and optional `stats.downloads`.
- Required projection fields MUST be validated before a document can be projected.
- Fields outside the allowlist MUST NOT appear in derived public RTDB data.
- Any later extension to the allowlist MUST be specified before implementation.

#### Scenario: Reject unallowlisted public data

- GIVEN a canonical project document contains approved public fields and additional private or unknown fields
- WHEN the document is evaluated for public projection
- THEN only allowlisted fields MAY be considered for RTDB output
- AND private or unknown fields MUST NOT be written to public RTDB.

### Requirement: Publishability is explicit and safe by default

The system MUST project only documents that are explicitly eligible for public Universo publication, and it MUST treat incomplete, draft, archived, internal, or otherwise non-publishable documents as not projectable.

#### Acceptance Criteria

- The set of publishable `status` values MUST be defined before enabling bridge projection for remote publication.
- Documents with missing required public fields MUST NOT be projected.
- Documents with non-publishable status values MUST NOT be projected.
- Unknown status values MUST be rejected or ignored safely rather than projected by default.

#### Scenario: Ignore a non-publishable project

- GIVEN a canonical project document exists with a draft, archived, internal, unknown, or otherwise non-publishable status
- WHEN projection eligibility is evaluated
- THEN the document MUST NOT produce a public RTDB node
- AND it MUST NOT produce public RTDB edges.

### Requirement: Remote publication verification is slice-scoped

Remote publication requirements MUST be verified when the publication contract or bridge slices are implemented, not as part of the local persistence-only slice.

#### Acceptance Criteria

- Contract/design tasks MUST identify the authorized publisher identity before Studio writes canonical Firestore documents.
- Bridge/function tasks MUST include validation evidence for allowed fields and publishability rules before public projection is enabled.
- Local slice verification MUST remain limited to `flutter analyze` and focused local persistence tests.

#### Scenario: Defer remote verification from slice one

- GIVEN only the local registry repair slice is being implemented
- WHEN verification is performed
- THEN Firestore publisher and bridge verification MAY be recorded as pending future-slice work
- AND the local slice MUST NOT be considered a remote publication release.
