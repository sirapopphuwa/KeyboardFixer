# KeyboardFixer

KeyboardFixer is a native, offline macOS menu-bar utility that repairs text typed with the wrong keyboard layout selected. It converts by physical keyboard key and Shift state—not by translation, autocorrect, dictionaries, or AI.

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
- `Services/`: pasteboard, Carbon hotkey, and launch-at-login integration
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

KeyboardFixer reads the general pasteboard only when **Paste & Convert** is clicked or the enabled **Command-Shift-V** global shortcut is pressed. It never polls, logs, uploads, or stores clipboard history. The shortcut replaces clipboard text with the corrected result; it deliberately does not synthesize a paste into the active app, so Accessibility permission is unnecessary. Paste normally afterward with Command-V.

Automatic copying after **Paste & Convert** is on by default and can be disabled in Settings. Auto mode leaves uncertain clipboard text unchanged.

The shortcut uses Carbon's supported global hotkey registration behind `HotKeyService`. It is isolated from the converter so a future version can offer configurable key combinations or optional automatic paste without changing core logic.

## Launch at Login

The Settings toggle uses `SMAppService.mainApp`, Apple's modern ServiceManagement API. macOS may also show or manage the item under **System Settings → General → Login Items**. No deprecated helper-app or login-item hack is used.

## Privacy and security

KeyboardFixer has no networking, analytics, telemetry, clipboard history, or unnecessary permissions. All conversion occurs locally and deterministically.

## Running a locally built unsigned app

A local unsigned build may be blocked by Gatekeeper after being copied between machines. First try Control-clicking the app in Finder, choosing **Open**, and confirming once. You can also approve a blocked app in **System Settings → Privacy & Security**.

If the app is trusted and was downloaded as an archive, remove quarantine from this app only:

```bash
xattr -d com.apple.quarantine /Applications/KeyboardFixer.app
```

Do not disable Gatekeeper globally. A distributed release should be signed with an Apple Developer ID Application certificate, hardened, and notarized by Apple.
