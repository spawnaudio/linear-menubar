# Linear Focus

A native macOS menu bar app for focusing on one Linear issue at a time. Select an issue, set a duration, and start a small floating countdown.

## Use the app

1. Open **Linear Focus.app** in the `build` folder after building it (instructions below).
2. Choose **Try it with demo issues** to explore the timer, or **Connect to Linear** to use your own issues.
3. For Linear, open [Settings → Account → Security & access](https://linear.app/settings/account/security). Create a personal API key with **Read** and **Write** permissions, optionally limited to your teams. Paste it into the app’s Settings and click **Connect to Linear**.
4. Select an assigned issue and choose 15, 25, 45, or 60 minutes, or enter a custom duration of 1–480 minutes.
5. Click **Start focusing**. With status updates enabled, Linear is updated successfully before the countdown starts.
6. Drag the floating timer anywhere on your screen. Hover to reveal **+5 min**, **Pause / Resume**, and **Open**.
7. When time is up, extend the session or click **Finish**. Session history is stored on this Mac.

Closing the main window keeps the app in the menu bar. Click its scope icon to reopen the app or access timer controls. Quitting preserves a running or paused session: running time continues while the app is closed, and paused time stays paused.

## What is included

- SwiftUI interface with an AppKit menu bar item and draggable, nonactivating floating panel.
- A single session shared by the main window, floating timer, and menu bar.
- Live Linear GraphQL integration: open issues assigned to you, manual refresh, pagination, search within loaded issues, issue links, and team-specific active statuses.
- Start updates the issue to a status in Linear’s `started` category. Automatic selection prefers **Working**, then **In Progress**, then the first active status by position. An already active issue keeps its current status unless you select an override in Settings.
- Pause, resume, extend, end, completion sound, local session history, and restoration after sleep or relaunch.
- API keys in macOS Keychain; session data in local app preferences. No server, telemetry, or third-party dependencies.
- Explicit demo mode with sample issues and separate demo history. Demo actions never call Linear.

Finishing or ending a timer **does not mark the Linear issue done**. Pause and extension only change the timer. A failed status update leaves the session unstarted and displays an error. Issues already completed or canceled in Linear are not reopened by Start.

## Build

Requires macOS 14 or newer and Xcode with a Swift 6 toolchain. The scripts prefer Xcode (or Xcode-beta) and respect an explicit `DEVELOPER_DIR`. The app uses only Apple frameworks. The standalone Command Line Tools supplied with this Mac had test-framework/plugin problems, so verification uses Xcode.

```sh
zsh scripts/build-app.sh
open "build/Linear Focus.app"
```

The build script creates a locally ad-hoc-signed app bundle. This is a development build for your Mac; distribution to other people requires Developer ID signing and notarization. A personal API key is appropriate for this personal version; a distributed product should use Linear OAuth.

For a faster development build:

```sh
zsh scripts/build-app.sh debug
```

## Verify

```sh
zsh scripts/test.sh
```

Tests cover timer expiry after missed ticks, paused time, extensions during every phase, persisted running and paused sessions, history accounting, status selection, HTTP/GraphQL errors, pagination, and status updates through a mocked network transport. They do not change real Linear issues.

The app also includes an isolated native UI smoke test. It creates sample sessions, checks panel configuration, and renders eight app-only screenshots without reading Keychain or calling Linear:

```sh
"build/Linear Focus.app/Contents/MacOS/LinearFocus" --smoke-test "$PWD/build/previews"
```

## Current boundaries

- Shows issues assigned to the connected user. Search applies to loaded issues; use **Load more issues** when needed.
- Changes made elsewhere in Linear appear after **Refresh**. The issue’s current status is checked again on Start when status updates are enabled.
- The timer uses a persisted deadline. Sleep and app downtime count toward a running session; pause first if you want to exclude them.
- The panel floats above normal application windows and is configured for all Spaces and full-screen apps. macOS system overlays and some exclusive full-screen surfaces can take precedence. Real multi-monitor and full-screen behavior should be checked on your setup.
- Completion remains visible and can play a sound while the app is running. There is no background alarm when the app is quit.
- No OAuth onboarding, login-at-startup option, automatic issue completion, or Linear time-log/comment creation in this version.

## Source layout

- `Sources/FocusCore`: timer state and Linear API client.
- `Sources/LinearFocus`: native windows, views, application state, and Keychain storage.
- `Tests/FocusCoreTests`: deterministic timer and mocked API tests.
- `Resources/Info.plist`: menu bar app bundle configuration.
- `scripts/build-app.sh`: local macOS app packaging.

References: [Locu](https://locu.app), [DeskMinder](https://deskminder.appps.od.ua), [Linear API](https://linear.app/developers/graphql), [Linear key permissions](https://linear.app/docs/api-and-webhooks).

## Electron and browser prototype

The repository also includes a separate Electron/React stopwatch prototype and a Cursor Cloud Agent development environment. See the [Electron setup guide](docs/ELECTRON.md) for Node.js requirements, browser preview, and Electron commands. Its timer and session storage are independent of the native macOS app.
