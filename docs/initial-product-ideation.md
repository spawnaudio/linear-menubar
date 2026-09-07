# Initial Product Ideation

## Original Product Idea

Create a macOS menu bar app that integrates with Linear and helps turn one issue into a focused, time-boxed work session.

The user selects a Linear issue, sets a duration, and starts the session. When Start is clicked, the app updates the Linear issue to the team’s active working status and opens a small floating timer that stays above other windows while counting down.

## Core Interaction

1. Choose a Linear issue.
2. Set a focus duration.
3. Click Start.
4. Update the issue in Linear to Working or In Progress.
5. Show a compact floating countdown timer above other windows.
6. Hover over the timer to reveal quick controls.
7. Add more time, pause/resume the timer, or open the main app window.
8. Keep the app available from the macOS menu bar.

## Design Direction

- Menu bar first: the app should stay close at hand without requiring a full application window.
- Small floating timer: the active session should remain visible while other work is in progress.
- Low friction: the primary view should focus on one issue and one timer.
- Minimal clutter: controls should appear contextually on hover.
- Time-boxed work: the timer should make the current work period visible and bounded.
- Linear-aware workflow: starting a session should communicate that the selected issue is actively being worked on.

## Initial Linear Decision

When the user clicks Start, the selected Linear issue should be moved into an active working state. The app should prefer the team’s equivalent of “Working” or “In Progress”, depending on the statuses available to that team.

## Reference Products

- [Locu](https://locu.app) — reference for connecting focused work sessions to tasks.
- [DeskMinder](https://deskminder.appps.od.ua) — reference for a compact menu bar and floating timer experience.

## Initial Product Boundary

The first version should focus on:

- A native macOS menu bar app.
- Linear issue selection.
- A configurable countdown timer.
- A floating always-on-top timer.
- Hover controls for adding time and pausing.
- A quick path back to the main app.
- Linear status updates when a focus session begins.

Future decisions such as automatic issue completion, time logging, comments, OAuth onboarding, browser extensions, and AI features should be evaluated separately after the core focus loop is working.
