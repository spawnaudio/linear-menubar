# Verification — 6 September 2026

Built and checked on an Apple silicon Mac running macOS 27 using the installed Xcode-beta toolchain.

| Check | Result |
| --- | --- |
| `zsh scripts/test.sh` | 19 tests passed across the timer and mocked Linear API suites |
| `zsh scripts/build-app.sh` | Release app built and locally signed |
| Native UI smoke test | Passed: start, pause, extend while paused, restore saved state, resume, expiry, save history, and show/hide panel |
| Panel configuration | Floating window level, all Spaces, full-screen auxiliary behavior, visible while inactive, and no keyboard focus capture checked |
| Visual review | Eight native renders inspected: issue selection, active session, collapsed timer, hover controls, finished timer, history, settings, and welcome |
| Bundle verification | `codesign --verify --deep --strict` and Info.plist validation passed |
| Source checks | Shell script syntax and `git diff --check` passed |

The UI test uses an isolated preferences suite and demo data. It does not read Keychain or call Linear. Rendered screenshots are in `build/previews`.

Not yet verified: a live Linear account and status mutation, Keychain behavior with a real API key, physical sleep/wake, dragging between real displays and full-screen applications, VoiceOver, Intel Macs, and older macOS versions. Timer recovery after elapsed wall time and saved-state restoration are covered by tests. Developer ID signing and notarization are not included.

To perform the live Linear check, connect a scoped Read/Write personal key in Settings, select an assigned issue you intend to work on, start a short session, and verify its active status in Linear. Pause and add time from the floating timer, then finish the session and confirm the issue stays in progress. Close and reopen the app during another session to check restoration on your setup.
