# KeyboardFixer

KeyboardFixer is a native, offline macOS menu-bar utility that repairs text typed with the wrong keyboard layout selected. It converts by physical keyboard key and Shift state—not by translation, autocorrect, dictionaries, or AI.

Version 2.1 adds reliable one-step selected-text replacement: highlight an editable text selection in most apps and press **Command-Shift-X**. KeyboardFixer reads and replaces the selection through macOS Accessibility APIs. A clipboard-based compatibility fallback is used only for apps that do not expose their selection through Accessibility. Secure fields are intentionally unsupported.

```text
z,vpkdlihk'cvr
→
ผมอยากสร้างแอพ
```

The same mapping works in reverse, from Thai Kedmanee output back to English (US) keystrokes.

## Requirements

- macOS 13 Ventura or newer
- Xcode with the macOS SDK and command-line tools
- No network connection or third-party packages

## How it works

Each layout maps a `KeyboardKey`—a physical key plus its Shift state—to one Unicode scalar. Conversion performs three deterministic steps:

1. Find the source layout key that emits the input scalar.
2. Keep that exact physical key and Shift state.
3. Emit the destination layout scalar for the same key.

Reverse tables are generated automatically. They store every matching key rather than using `Dictionary(uniqueKeysWithValues:)`, so a layout with duplicate output never crashes. Candidates are ordered by `PhysicalKey.allCases`, with unshifted before shifted, giving a stable fallback. Thai-to-English-to-Thai round-trip tests cover every unambiguous mapping.

The low-level converter iterates `String.UnicodeScalarView`. This is intentional: Thai tone marks and combining vowels are separate keyboard outputs even when Swift's `Character` model groups them into extended grapheme clusters. KeyboardFixer does not normalize text, and preserves scalar order exactly. Spaces, tabs, newlines, emoji, and scalars missing from the source layout pass through unchanged.

Auto detection scores Latin letters and Thai Unicode scalars strongly. Digits, whitespace, and punctuation are neutral, so punctuation-only text is never enough to trigger conversion. Short or mixed-script input is considered uncertain and remains unchanged until a direction is selected manually. Manual English → Thai and Thai → English modes always apply the deterministic keyboard mapping, including to URLs or code.

## Architecture

- `KeyboardFixerApp.swift`: menu-bar and Settings scenes
- `MenuBarView.swift`, `SettingsView.swift`: native SwiftUI interface
- `AppModel.swift`: UI state and user actions
- `Converter/`: layouts, scalar converter, and conservative detector
- `Models/`: physical key and conversion-mode types
- `Services/`: pasteboard snapshots, direct Accessibility selection access, Carbon hotkeys, and launch-at-login integration
- `KeyboardFixerTests/`: mapping, round-trip, Unicode, and detector tests

The UI uses `MenuBarExtra` and has no normal launch window. `LSUIElement` in `Info.plist` keeps the app out of the Dock while it remains running in the menu bar.

## Build and run

Open `KeyboardFixer.xcodeproj` in Xcode, select the **KeyboardFixer** scheme, and press Run. The keyboard icon appears in the menu bar.

For a command-line Release build:

```bash
./scripts/build.sh
```

The unsigned app is produced at:

```text
build/Build/Products/Release/KeyboardFixer.app
```

Core converter tests can also run through Swift Package Manager:

```bash
swift test
```

Run the full Xcode unit-test suite with:

```bash
xcodebuild -project KeyboardFixer.xcodeproj -scheme KeyboardFixer -configuration Debug -derivedDataPath build CODE_SIGNING_ALLOWED=NO test
```

## Install

```bash
./scripts/install.sh
```

The script builds Release and copies the result to `/Applications/KeyboardFixer.app`, requesting administrator access only when `/Applications` is not writable.

## Clipboard and shortcut behavior

KeyboardFixer reads the general pasteboard only when **Paste & Convert**, **Command-Shift-V**, or the Command-Shift-X compatibility fallback is explicitly invoked. It never polls, logs, uploads, or stores clipboard history.

- **Command-Shift-V** converts clipboard text without Accessibility permission. Paste normally afterward with Command-V.
- **Command-Shift-X** reads highlighted text through Accessibility, converts it, and replaces the selection directly. It requires Accessibility permission.

If an app does not expose its selection through Accessibility, KeyboardFixer falls back to Copy/Paste. It snapshots the existing clipboard and restores it only if no other process changed the clipboard in the meantime, preventing newer clipboard content from being overwritten.

Selected-text replacement operates on plain text. In rich-text editors, the replacement normally adopts the formatting at the insertion point; formatting that varied inside the original selection may not be retained.

Automatic copying after **Paste & Convert** is on by default and can be disabled in Settings. Auto mode leaves uncertain clipboard text unchanged.

Both shortcuts use Carbon's supported global hotkey registration behind `HotKeyService`. Automatic replacement runs only on an explicit shortcut press; the app does not monitor typing or selected text continuously.

## Accessibility permission for selected-text replacement

The first time Command-Shift-X is pressed, macOS prompts for Accessibility access. Enable KeyboardFixer under **System Settings → Privacy & Security → Accessibility**, then press the shortcut again. The permission is used only after the user invokes the shortcut to read and replace the current selection, or to send Copy/Paste for the compatibility fallback. It does not grant KeyboardFixer network access, and KeyboardFixer does not retain the selected text.

## Launch at Login

The Settings toggle uses `SMAppService.mainApp`, Apple's modern ServiceManagement API. Launch at Login defaults to on for the installed app, can be disabled in Settings, and macOS may also show or manage it under **System Settings → General → Login Items**. No deprecated helper-app or login-item hack is used.

## Privacy and security

KeyboardFixer has no networking, analytics, telemetry, clipboard history, or unnecessary permissions. All conversion occurs locally and deterministically.

## Running a locally built unsigned app

A local unsigned build may be blocked by Gatekeeper after being copied between machines. First try Control-clicking the app in Finder, choosing **Open**, and confirming once. You can also approve a blocked app in **System Settings → Privacy & Security**.

If the app is trusted and was downloaded as an archive, remove quarantine from this app only:

```bash
xattr -d com.apple.quarantine /Applications/KeyboardFixer.app
```

Do not disable Gatekeeper globally. A distributed release should be signed with an Apple Developer ID Application certificate, hardened, and notarized by Apple.
