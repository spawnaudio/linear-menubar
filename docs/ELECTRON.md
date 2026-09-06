# Electron and browser prototype

This is a separate experimental stopwatch implementation. For the native macOS floating countdown and automatic Linear status updates, follow the [main setup guide](../README.md). The two apps have separate settings and session storage.

A small utility app to set a timer linked to a Linear Issue, to help with ADHD task management.

Pick one Linear issue, start a focus timer, and let the app track the time you
spend per issue. It lives in the system menubar (tray) as an Electron app, and
the same UI can be run in a browser during development.

## Features

- Focus timer (stopwatch) bound to a single Linear issue at a time.
- Start / Pause / Reset, plus **Log** to commit a session to that issue's total.
- Per-issue time totals, persisted locally across restarts.
- Live Linear data when a `LINEAR_API_KEY` is provided; otherwise the app runs
  on bundled sample issues so it works with zero configuration.
- ADHD-friendly UI: one big timer, one selected task, minimal clutter.

## Tech stack

- **Renderer:** React + TypeScript, built with Vite.
- **Shell:** Electron menubar (tray popover) via the [`menubar`](https://github.com/maxogden/menubar) package.
- **Linear:** [`@linear/sdk`](https://github.com/linear/linear) (loaded in the Electron main process).

## Prerequisites

- Node.js 22+
- npm 10+

## Getting started

```bash
npm install
```

### Run the UI in a browser (fastest for development)

```bash
npm run dev
```

Then open http://127.0.0.1:5173. This serves the exact menubar popover UI as a
web page using the bundled sample issues — no Electron or Linear key required.

### Run the Electron menubar app

```bash
# development (loads the Vite dev server; run `npm run dev` alongside)
npm run electron:dev

# production (builds the renderer + main, then launches Electron)
npm run start
```

## Connecting to Linear

Create a personal API key in Linear (Settings → Security & access → Personal API
keys) and provide it via environment variable before launching Electron:

```bash
export LINEAR_API_KEY="lin_api_..."
npm run start
```

With a key set, the app loads your assigned issues. Without one, it shows sample
issues and displays a "Sample data" badge.

## Scripts

| Script | Description |
| --- | --- |
| `npm run dev` | Vite dev server for the renderer (browser). |
| `npm run build` | Build the renderer (`dist/`) and Electron main (`dist-electron/`). |
| `npm run typecheck` | Type-check the renderer and Electron sources. |
| `npm run lint` | ESLint over the project. |
| `npm run electron:dev` | Build the main process and launch Electron in dev mode. |
| `npm run start` | Full build + launch Electron in production mode. |

## Project layout

```
electron/         Electron main process, preload bridge, and Linear service
src/              React renderer (components, hooks, timer logic)
scripts/          Build helpers (asset copy)
.cursor/          Cloud Agent development environment configuration
```
