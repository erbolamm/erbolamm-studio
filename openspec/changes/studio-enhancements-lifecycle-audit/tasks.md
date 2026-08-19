# Tasks: ErBolamm Studio Enhancements & Lifecycle Audit

## Phase 1: Models & Progress Computation
- [ ] 1.1 Create `PipelineProgress` model in `lib/models/pipeline_progress.dart` calculating status (green, yellow, grey) for each module.
- [ ] 1.2 Update `ProjectMonitor` in `lib/services/project_monitor.dart` to support scanning multiple `INBOX/` subfolders, selecting active project, and emitting progress updates.
- [ ] 1.3 Add unit tests for `PipelineProgress` and `ProjectMonitor`.

## Phase 2: NavigationRail & Analyzer Enhancements
- [ ] 2.1 Update `AdaptiveNavigation` in `lib/core/navigation/adaptive_navigation.dart` to display colored badges/icons reflecting module progress on NavigationRail.
- [ ] 2.2 Add project selector dropdown in `lib/features/analyzer/presentation/screens/analyzer_screen.dart` for local `INBOX/` projects.
- [ ] 2.3 Clarify Step 2 decision options with detailed honest descriptions and add custom rule creation option.
- [ ] 2.4 Reduce all ScaffoldMessenger / Snackbar durations to 1 second.

## Phase 3: Store Metadata & Release Notes Auditor (Anti-Rechazo 2.3.3)
- [ ] 3.1 Create `StoreMetadataAuditorWidget` with:
  - Batch "What's New" copy for Android (Google Play).
  - Per-language "What's New" selector & copy for iOS (App Store Connect).
  - Screenshot folder auditor detecting and warning about obsolete sizes (5.5", 4.7", 4", 3.5", iPad 9.7").
- [ ] 3.2 Integrate `StoreMetadataAuditorWidget` into `PublisherScreen` and `OrchestratorScreen`.

## Phase 4: Contextual Agent-Aware Terminal
- [ ] 4.1 Update `TerminalService` in `lib/features/terminal/domain/terminal_service.dart` to accept dynamic `cwd` based on the active `INBOX` project.
- [ ] 4.2 Implement macOS CLI tool detection (`gentle-ai`, `opencode`, `claude`, `codex`, `pi`, `flutter`, `dart`, `gh`).
- [ ] 4.3 Update `TerminalScreen` in `lib/features/terminal/presentation/screens/terminal_screen.dart` with detected agent chips, current directory display, and project-contextual quick action buttons.

## Phase 5: Verification & Quality Assurance
- [ ] 5.1 Run `flutter test` and ensure all existing and new unit/widget tests pass 100%.
- [ ] 5.2 Run `flutter analyze` and ensure 0 errors, 0 warnings.
- [ ] 5.3 Update `ESTADO.md` with completed implementation.
