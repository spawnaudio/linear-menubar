# Build & Verification Resources

## Purpose

This document collects the resources needed to build, test, inspect, and validate Linear Focus. The native Swift macOS app is the primary product track; the Electron/React implementation is a separate experimental prototype.

## Native Build Resources

- `Package.swift` — Swift package configuration; requires macOS 14+ and Swift 6.
- `scripts/build-app.sh` — builds and packages the native macOS app.
- `scripts/toolchain.sh` — selects the Xcode or Xcode-beta toolchain.
- `scripts/make-icon.swift` — generates the app icon.
- `Resources/Info.plist` — app bundle and menu bar configuration.
- `build/Linear Focus.app` — generated locally built and ad-hoc-signed app.
- `.build/` — generated Swift build artifacts.

Build commands:

```sh
zsh scripts/build-app.sh
zsh scripts/build-app.sh debug
open "build/Linear Focus.app"
```

Requirements:

- macOS 14 or newer.
- Xcode with a Swift 6 toolchain.
- Developer ID signing and notarization are not included in the development build.

## Native Verification Resources

- `scripts/test.sh` — runs the Swift test suite.
- `Tests/FocusCoreTests/FocusSessionTests.swift` — timer state, expiry, pause/resume, extension, persistence, and history coverage.
- `Tests/FocusCoreTests/LinearClientTests.swift` — mocked GraphQL requests, pagination, errors, status selection, and status updates.
- `VALIDATION.md` — recorded verification results and remaining gaps.
- `build/previews/` — generated native UI smoke-test screenshots.

Test command:

```sh
zsh scripts/test.sh
```

Native UI smoke test:

```sh
"build/Linear Focus.app/Contents/MacOS/LinearFocus" --smoke-test "$PWD/build/previews"
```

Recorded results:

- 19 automated tests passed.
- Release app built and locally signed.
- Native UI smoke test passed.
- Floating panel behavior and configuration were checked.
- Eight native UI renders were visually reviewed.
- Bundle signing and Info.plist validation passed.
- Shell syntax and `git diff --check` passed.

## Native App Source Under Test

- `Sources/FocusCore/LinearClient.swift` — Linear GraphQL client.
- `Sources/FocusCore/Models.swift` — timer and Linear domain models.
- `Sources/LinearFocus/AppModel.swift` — application state and session coordination.
- `Sources/LinearFocus/FloatingTimer.swift` — floating timer panel.
- `Sources/LinearFocus/Keychain.swift` — Keychain credential storage.
- `Sources/LinearFocus/LinearFocusApp.swift` — app and menu bar entry point.
- `Sources/LinearFocus/MainView.swift` — issue selection and session UI.
- `Sources/LinearFocus/SettingsView.swift` — Linear connection and timer settings.
- `Sources/LinearFocus/Theme.swift` — visual styling.

## Electron/React Prototype Resources

This is an independent experimental implementation with separate settings and session storage.

- `package.json` and `package-lock.json` — Node dependencies and scripts.
- `src/` — React renderer, issue picker, timer panel, timer hook, sample data, and styles.
- `electron/` — Electron main process, preload bridge, Linear SDK integration, and types.
- `scripts/copy-assets.mjs` — copies prototype assets during build.
- `electron/assets/iconTemplate.png` — menubar icon.
- `vite.config.ts`, `tsconfig.json`, `tsconfig.electron.json`, `.eslintrc.cjs` — development configuration.
- `docs/ELECTRON.md` — prototype setup and command reference.
- `.cursor/environment.json` — Cursor Cloud Agent environment configuration.

Prototype requirements:

- Node.js 22 or newer.
- npm 10 or newer.

Prototype commands:

```sh
npm install
npm run dev
npm run typecheck
npm run lint
npm run build
npm run electron:dev
npm run start
```

## External References

- [GitHub repository](https://github.com/spawnaudio/linear-menubar)
- [Linear GraphQL API](https://linear.app/developers/graphql)
- [Linear API and webhook documentation](https://linear.app/docs/api-and-webhooks)
- [Linear personal API key settings](https://linear.app/settings/account/security)
- [Electron menubar package](https://github.com/maxogden/menubar)
- [Linear JavaScript SDK](https://github.com/linear/linear)
- [Locu](https://locu.app) — product inspiration.
- [DeskMinder](https://deskminder.appps.od.ua) — product inspiration.

## Remaining Verification

Live or device-specific validation is still required for:

- Live Linear status mutations.
- Keychain behavior with a real API key.
- Physical sleep/wake behavior.
- Dragging between real displays and full-screen applications.
- VoiceOver and accessibility behavior.
- Intel Macs and older supported macOS versions.
- Developer ID signing and notarization.
- Confirming that a finished session leaves the issue in progress.
