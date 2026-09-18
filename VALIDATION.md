# Validation — 18 September 2026

Environment: Xcode 26.6, Apple Swift 6.3.3, arm64 macOS. Deployment target: macOS 14.

## Passed

- Release build of the native SwiftUI application.
- Debug build and all 7 XCTest methods, covering more than 20 individual search queries and catalog integrity.
- Hebrew and English natural-language ranking, Windows key combinations, modifier aliases, punctuation keys, Hebrew vowel-mark removal and final-letter normalization.
- One-character fuzzy matching, unknown/empty queries, deterministic ordering, result limits.
- Catalog contains 77 unique records with both language titles/descriptions, keywords, category and Mac shortcut. Windows mappings are optional where no direct equivalent is supplied.
- Packaged executable installation check loaded all 77 records.
- App bundle property list validation and local code-signature verification.
- Earlier UI build: app opened, initial empty search view contained 77-shortcut count and examples, search field was the focused accessibility element. Settings opened and Hebrew RTL layout was visually inspected. Hotkey registration toggle changed to enabled without a registration error.

## Not fully verified

- The final UI build could not be reopened: automatic approval review required explicit action-time user permission to run the locally built app.
- End-to-end copy, arrow-key selection, Escape, repeated popover focus and the final Control–Option–K global shortcut therefore still require a final UI smoke test. Earlier UI automation had intermittent timeouts, and did not establish global hotkey delivery.
- Launch at Login uses SMAppService, but no actual logout/login was performed and no login item was enabled during testing.
- The local app is ad-hoc signed, not notarized for public distribution. The supplied binary targets Apple Silicon; source can be rebuilt on Intel.

The global hotkey opens a separate floating window sharing the search UI. Clicking the menu bar icon opens the MenuBarExtra window. This distinction is intentional and uses public APIs only.

## Compact layout update

- Reduced both search surfaces from 480×600 to 400×460 points; reduced padding, row spacing, and result typography.
- Search alignment now follows the interface language, with explicit leading alignment in RTL for Hebrew. Typing English no longer flips the Hebrew search field to LTR.
- Release build and bundled 77-record installation check passed after the update. This layout update has not been visually verified in the running app.

## Native RTL search-field correction

Replaced the SwiftUI TextField with an NSTextField bridge. The placeholder has an explicit paragraph alignment and base writing direction; the active NSTextView field editor receives explicit right alignment, RTL paragraph direction and typing attributes. Updating cell formatting during editing was found to detach the shared editor, so cell configuration occurs only before editing and live formatting is applied to the editor itself.

All 8 tests pass, including an AppKit regression test using a real field editor in an offscreen window. It covers empty, Hebrew, English and mixed input, retains the editing session, and verifies switching back to LTR. Release build and bundled catalog check also pass. No new on-screen visual verification was performed.

## Appearance settings

Added persisted Dark / Light / System selection (default: System) in Settings. Applies to SwiftUI search/settings surfaces and the native application appearance, including the floating search panel and AppKit field editor. System clears the override so macOS changes can propagate. Release build, installation check, and all 8 existing regression tests pass. The new appearance controls have not been visually tested on screen.
