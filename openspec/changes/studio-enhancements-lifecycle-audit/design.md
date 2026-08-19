# Design: ErBolamm Studio Enhancements & Lifecycle Audit

## Technical Approach

Integrate a unified `PipelineProgress` model into `ProjectMonitor` that computes live statuses for the active project. Expose these statuses via `AdaptiveNavigation` on the NavigationRail, expand `AnalyzerScreen` with an `INBOX` multi-project picker, build a `StoreMetadataAuditor` within the Publisher/Orchestrator tools, and upgrade `TerminalScreen` with contextual directory switching and macOS AI agent detection.

## Architecture Decisions

### Decision: State Calculation in `PipelineProgress`
- **Choice**: Compute `PipelineProgress` on-demand from local project filesystem artifacts (`promo/`, `analysis.json`, `copy-pack.md`, audio files, videos).
- **Alternatives considered**: Storing progress states in a separate database table.
- **Rationale**: Keeps the filesystem as the canonical source of truth without desynchronization bugs.

### Decision: Navigation Status Badges
- **Choice**: Use Flutter `Badge` widget with customized colored dots / icons (`Icons.check_circle`, `Icons.warning`, `Icons.circle_outlined`) directly wrapping `NavigationRailDestination.icon`.
- **Alternatives considered**: Custom custom-painted sidebar.
- **Rationale**: Minimal invasive change, preserves Flutter desktop responsiveness.

### Decision: Terminal Context & Tool Discovery
- **Choice**: Run asynchronous probe using `Process.run('which', [toolName])` on macOS to discover installed tools, and pass `workingDirectory: activeProjectPath` to `TerminalService`.
- **Alternatives considered**: Static hardcoded list.
- **Rationale**: Adapts dynamically to whatever environment the user has on macOS.

## Data Flow

```
   [ INBOX/ Directory ] ────────► [ ProjectMonitor ]
                                          │
                                          ▼
                                 [ PipelineProgress ]
                                          │
                  ┌───────────────────────┼───────────────────────┐
                  ▼                       ▼                       ▼
        [ AdaptiveNavigation ]    [ AnalyzerScreen ]     [ TerminalScreen ]
         (Badges on Rail)         (Project Dropdown)     (Project cwd + Agents)
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/models/pipeline_progress.dart` | Create | DTO calculating step completion (green, yellow, grey) |
| `lib/services/project_monitor.dart` | Modify | Multi-project scanning in `INBOX/` and project switching |
| `lib/core/navigation/adaptive_navigation.dart` | Modify | Render status badges on NavigationRail items |
| `lib/features/analyzer/presentation/screens/analyzer_screen.dart` | Modify | Add INBOX dropdown, update Step 2 descriptions, 1s snackbars |
| `lib/features/publisher/presentation/widgets/store_metadata_auditor_widget.dart` | Create | Release notes 1-click copy & screenshot legacy auditor |
| `lib/features/publisher/presentation/screens/publisher_screen.dart` | Modify | Embed store metadata auditor |
| `lib/features/terminal/domain/terminal_service.dart` | Modify | Support dynamic `cwd` and tool availability check |
| `lib/features/terminal/presentation/screens/terminal_screen.dart` | Modify | Show detected agent chips and active project context |

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | `PipelineProgress` calculation logic | Unit tests validating progress from mock project folders |
| Unit | `StoreMetadataAuditor` release notes & screenshot checks | Unit tests validating legacy size warnings |
| Integration | NavigationRail badge updates on active project switch | Widget tests with `ProjectMonitor` |
| Verification | `flutter analyze` & `flutter test` | Command execution ensuring 0 issues |
