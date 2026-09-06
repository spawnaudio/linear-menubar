import type { LinearIssue } from "../types";
import type { FocusTimer } from "../hooks/useFocusTimer";
import { formatClock } from "../lib/format";

interface TimerPanelProps {
  timer: FocusTimer;
  selectedIssue: LinearIssue | undefined;
}

export function TimerPanel({ timer, selectedIssue }: TimerPanelProps) {
  const hasSelection = Boolean(selectedIssue);

  return (
    <section className="timer-panel">
      <div className={timer.isRunning ? "clock clock-running" : "clock"}>
        {formatClock(timer.elapsedMs)}
      </div>
      <div className="clock-caption">
        {hasSelection ? (
          <>
            <span className="dot" data-running={timer.isRunning} />
            {timer.isRunning ? "Focusing on" : "Ready to focus on"}{" "}
            <strong>{selectedIssue?.identifier}</strong>
          </>
        ) : (
          "Pick an issue below to start a focus session"
        )}
      </div>

      <div className="controls">
        {timer.isRunning ? (
          <button type="button" className="btn btn-primary" onClick={timer.pause}>
            Pause
          </button>
        ) : (
          <button
            type="button"
            className="btn btn-primary"
            onClick={timer.start}
            disabled={!hasSelection}
          >
            Start
          </button>
        )}
        <button
          type="button"
          className="btn"
          onClick={timer.reset}
          disabled={!hasSelection || timer.elapsedMs === 0}
        >
          Reset
        </button>
        <button
          type="button"
          className="btn"
          onClick={timer.logSession}
          disabled={!hasSelection || timer.elapsedMs === 0}
        >
          Log
        </button>
      </div>
    </section>
  );
}
