# Proposal: ErBolamm Studio Enhancements & Lifecycle Audit

## Intent

ErBolamm Studio requires end-to-end reliability when preparing and publishing projects to prevent store rejections (e.g. Apple Guideline 2.3.3), provide visual feedback on pipeline progress across all modules via NavigationRail badges, allow selecting among multiple local INBOX projects, clarify INBOX.md decision paths, and provide a contextual, agent-aware terminal operating inside the active project directory.

## Scope

### In Scope
- **Store Metadata & Release Notes Auditor**: Multi-language "What's New" generator with 1-click batch copy (Android) and per-language copy (iOS), plus screenshot validator detecting outdated legacy sizes (5.5", 4.7", 9.7").
- **NavigationRail Project Status Indicators**: Dynamic badge/icon indicators (green: complete, yellow: partial, grey: pending) across all studio views based on the active project state.
- **INBOX Multi-Project Selector & Fast Snackbars**: Dropdown to select among local `INBOX/` projects alongside GitHub URL and Google Drive downloads; cap notification banners to max 1 second.
- **Project Classification & INBOX.md Rule Extension**: Automatic project type recognition, fallback prompt with custom rule creation for unknown types, transparent descriptions for INBOX Step 2 decisions, and `promo/` completeness verification.
- **Voice/Music/Market Pipeline Integration**: Voice indicator logic (cloned + used in video), genre-aware procedural music suggestions, Market competitor research feeding copy/video scripts, and animation instructions.
- **Contextual Agent-Aware Terminal**: Terminal executing in active project `cwd` with auto-detection of macOS CLI tools (`gentle-ai`, `opencode`, `claude`, `codex`, `pi`, `flutter`, `gh`).
- **`AGENTS.md` and Obsolete File Review**: Establish canonical `AGENTS.md` declaring `ESTADO.md` as single source of truth and propose cleanup for obsolete files.

### Out of Scope
- Full native cloud deployment for iOS without Xcode / App Store Connect web interface.
- Automatic paid ad campaign publishing to social platforms (TikTok/Meta API ad buys).

## Capabilities

### New Capabilities
- `store-metadata-auditor`: Release notes generator & App Store/Play Store screenshot structure compliance validator.
- `navigation-status-indicators`: Real-time visual progress checks on NavigationRail based on active project state.
- `inbox-project-selector`: Local directory scanner and switcher for multi-project `INBOX/` workspaces.
- `contextual-agent-terminal`: Project-scoped terminal runner detecting installed AI coding agents and CLI tools.

### Modified Capabilities
- `analyzer-rules-engine`: Support for custom project rule creation and detailed Step 2 decision definitions.
- `pipeline-voice-music-market`: Integration of market research findings into narration scripts and music generation.

## Approach

1. **State & Registry Extension**: Extend `ProjectMonitor` and `RepoAnalysis` to expose a computed `PipelineProgress` object (statuses for Analyzer, Orchestrator, Voice, Market, Music, Animation, Publisher, Terminal).
2. **UI & NavigationRail Update**: Update `AdaptiveNavigation` to display colored status dots/badges on navigation destinations reflecting the active project's progress.
3. **Analyzer Enhancement**: Add directory scanner for `INBOX/` subdirectories with dropdown selector, and tune `ScaffoldMessenger` snackbar durations to 1s.
4. **Metadata & Release Notes View/Widget**: Add dedicated helper in Publisher/Orchestrator to format "What's New" strings for Play Store & App Store Connect, validating screenshot folders against legacy size traps.
5. **Contextual Terminal**: Update `TerminalService` to accept and track dynamic `cwd` (defaulting to selected `INBOX/<project>`), detecting binaries via `which` on macOS.
6. **Governance & Documentation**: Create root `AGENTS.md` and document file hygiene recommendations.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/core/navigation/` | Modified | Add status indicators and badge rendering to NavigationRail destinations |
| `lib/features/analyzer/` | Modified | Add INBOX project dropdown, custom rule prompt, reduce snackbar display time |
| `lib/features/terminal/` | Modified | Support active project cwd and installed agent detector (`gentle-ai`, `opencode`, `claude`, `pi`, `codex`) |
| `lib/features/publisher/` | Modified | Add Release Notes formatter & App Store screenshot validator |
| `lib/features/voice/` & `music/` | Modified | Status validation logic (voice clone + video usage, contextual music suggestions) |
| `AGENTS.md` | New | Canonical guide for agents declaring `ESTADO.md` and `INBOX.md` hierarchy |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Missing tools on host machine | Med | Graceful degradation: show status badges as grey and explain tool installation steps |
| Terminal cwd execution sandbox breach | Low | Enforce strict sandbox guard restricting operations within active project or studio root |

## Rollback Plan

Revert git branch commits or restore specific feature files; all existing core models remain backwards-compatible.

## Dependencies

- macOS host shell utilities (`which`, `zsh`).
- Local filesystem access to `INBOX/`.

## Success Criteria

- [ ] NavigationRail shows real-time green/yellow/grey indicators for the active project.
- [ ] User can switch between multiple projects in `INBOX/` with one click from Analizador.
- [ ] Release notes & screenshot auditor formats strings and alerts on legacy screenshot sizes.
- [ ] Terminal executes commands inside selected project `cwd` and lists detected AI tools.
- [ ] `AGENTS.md` exists and guides all AI agents into `ESTADO.md`.
- [ ] Flutter analyze and tests pass with 0 warnings.
