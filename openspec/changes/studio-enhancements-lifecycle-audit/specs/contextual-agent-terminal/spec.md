# Contextual Agent-Aware Terminal Specification

## Purpose

Provide a project-aware terminal environment that automatically sets its working directory (`cwd`) to the active project folder and detects installed AI coding agents and development CLI tools on macOS.

## Requirements

### Requirement: Active Project Directory Context

The terminal system MUST execute shell commands in the directory of the currently active project (e.g. `INBOX/<project_name>`) with fallback to the studio workspace root.

#### Scenario: Running command in active project
- GIVEN the active project is `afinar_de_oido` inside `INBOX/`
- WHEN the user executes a command or quick action in the Terminal screen
- THEN the command executes with `cwd = /path/to/erbolamm-studio/INBOX/afinar_de_oido`.

### Requirement: macOS Tool and Agent Detection

The system MUST probe the host environment for installed tools and AI coding agents (`gentle-ai`, `opencode`, `claude`, `codex`, `pi`, `flutter`, `dart`, `gh`) and display their availability.

#### Scenario: Tool availability discovery
- GIVEN the macOS host has `gentle-ai` and `flutter` in `$PATH`
- WHEN the Terminal screen initializes
- THEN it displays active status chips for detected tools and enables quick invocation buttons.
