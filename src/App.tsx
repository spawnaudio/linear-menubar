import { useEffect, useMemo, useState } from "react";
import type { IssueSource, LinearIssue } from "./types";
import { loadIssues } from "./lib/issues";
import { useFocusTimer } from "./hooks/useFocusTimer";
import { IssuePicker } from "./components/IssuePicker";
import { TimerPanel } from "./components/TimerPanel";

export default function App() {
  const [issues, setIssues] = useState<LinearIssue[]>([]);
  const [source, setSource] = useState<IssueSource>("sample");
  const [loading, setLoading] = useState<boolean>(true);
  const timer = useFocusTimer();

  useEffect(() => {
    let active = true;
    loadIssues().then((result) => {
      if (!active) return;
      setIssues(result.issues);
      setSource(result.source);
      setLoading(false);
    });
    return () => {
      active = false;
    };
  }, []);

  const selectedIssue = useMemo(
    () => issues.find((issue) => issue.id === timer.selectedIssueId),
    [issues, timer.selectedIssueId],
  );

  return (
    <div className="app">
      <header className="app-header">
        <div className="brand">
          <span className="brand-mark" aria-hidden="true" />
          <div>
            <h1>Linear Menubar</h1>
            <p>Focus timer for one issue at a time</p>
          </div>
        </div>
        <span className={source === "live" ? "badge badge-live" : "badge"}>
          {source === "live" ? "Live Linear" : "Sample data"}
        </span>
      </header>

      <TimerPanel timer={timer} selectedIssue={selectedIssue} />

      <div className="issues-header">
        <h2>{source === "live" ? "Your assigned issues" : "Example issues"}</h2>
      </div>

      {loading ? (
        <p className="empty">Loading issues…</p>
      ) : issues.length === 0 ? (
        <p className="empty">No issues to show.</p>
      ) : (
        <IssuePicker
          issues={issues}
          selectedIssueId={timer.selectedIssueId}
          totals={timer.totals}
          onSelect={timer.select}
        />
      )}
    </div>
  );
}
