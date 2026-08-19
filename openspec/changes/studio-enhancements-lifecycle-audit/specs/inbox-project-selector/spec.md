# INBOX Project Selector & Notification Duration Specification

## Purpose

Allow scanning and switching among multiple local projects in `INBOX/`, and ensure UI feedback (Snackbars / Banners) does not block or linger longer than 1 second.

## Requirements

### Requirement: Local INBOX Scanner and Dropdown Selector

The system MUST scan the `INBOX/` directory for valid subdirectories and provide a project selector dropdown in the Analizador screen.

#### Scenario: Multiple projects in INBOX
- GIVEN `INBOX/` contains multiple project folders (e.g. `afinar_de_oido`, `calca_app`)
- WHEN the user opens the Analizador screen
- THEN a dropdown allows choosing the active project immediately without re-typing local paths.

### Requirement: Quick Snackbars Duration

The system MUST limit Snackbar and MaterialBanner display durations to a maximum of 1 second (1000ms).

#### Scenario: Displaying status feedback
- GIVEN any operation completed in the UI
- WHEN a ScaffoldMessenger snackbar is triggered
- THEN its duration is set to `const Duration(milliseconds: 1000)` and auto-dismisses swiftly.
