# Navigation Status Indicators Specification

## Purpose

Expose dynamic, visual progress badges (green: complete, yellow: warning/partial, grey: pending) on NavigationRail destinations reflecting the active project's state.

## Requirements

### Requirement: Real-time Navigation Progress Status

The system MUST compute and render status badges on navigation items (Analyzer, Orchestrator, Voice, Market, Music, Animation, Publisher, Terminal) for the active project.

#### Scenario: All steps completed
- GIVEN an active project with analysis, promo assets, voice-in-video, music, and valid release metadata
- WHEN the user views the NavigationRail
- THEN each corresponding icon displays a green checkmark or badge.

#### Scenario: Partial voice setup
- GIVEN a project with a cloned voice profile but without a rendered video using that voice
- WHEN the user inspects the Voice navigation item
- THEN the icon displays a yellow status badge indicating incomplete integration.
