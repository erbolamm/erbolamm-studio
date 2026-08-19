# Store Metadata & Release Notes Auditor Specification

## Purpose

Provide a release metadata assistant that formats multi-language "What's New" release notes (with 1-click copy for Android and iOS) and audits screenshot assets in `promo/screenshots/` to prevent App Store Guideline 2.3.3 rejections caused by legacy screenshot sizes.

## Requirements

### Requirement: Multi-language Release Notes Formatting

The system MUST allow generating and copying "What's New" text for Google Play Store and Apple App Store Connect in all supported languages (ES, EN, DE, FR, IT, PT).

#### Scenario: Copy Android Release Notes
- GIVEN a project with generated release notes in `promo/copy-pack.md` or version metadata
- WHEN the user clicks "Copiar Todo para Android"
- THEN the system copies formatted release notes with language tags or in batch format to clipboard
- AND displays a confirmation feedback for 1 second.

#### Scenario: Copy iOS Release Notes per language
- GIVEN a selected language in the metadata auditor dropdown
- WHEN the user clicks "Copiar para App Store"
- THEN the system copies only the single language text to clipboard
- AND displays a 1-second confirmation toast.

### Requirement: Store Screenshot Legacy Size Auditor

The system MUST inspect `promo/screenshots/store/` and `promo/screenshots/appstore/` to identify and alert if obsolete device sizes (5.5-inch, 4.7-inch, 4-inch, 3.5-inch, iPad 9.7-inch, iPad Pro 2nd Gen) exist or if mandatory sizes (iPhone 6.7" and iPad 13") are missing.

#### Scenario: Legacy screenshot detection
- GIVEN a project with folders or files matching legacy display dimensions
- WHEN the auditor evaluates screenshot structure
- THEN it MUST return a Warning status detailing the risk of Apple Guideline 2.3.3 rejection
- AND recommend deleting legacy sizes so App Store Connect uses auto-scaling from 6.7" and 13".
