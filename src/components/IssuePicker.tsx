import type { LinearIssue } from "../types";
import { formatTotal } from "../lib/format";

interface IssuePickerProps {
  issues: LinearIssue[];
  selectedIssueId: string | null;
  totals: Record<string, number>;
  onSelect: (issueId: string) => void;
}

function priorityClass(priorityLabel: string): string {
  switch (priorityLabel) {
    case "Urgent":
      return "prio prio-urgent";
    case "High":
      return "prio prio-high";
    case "Medium":
      return "prio prio-medium";
    default:
      return "prio prio-low";
  }
}

export function IssuePicker({ issues, selectedIssueId, totals, onSelect }: IssuePickerProps) {
  return (
    <ul className="issue-list">
      {issues.map((issue) => {
        const isSelected = issue.id === selectedIssueId;
        const total = totals[issue.id] ?? 0;
        return (
          <li key={issue.id}>
            <button
              type="button"
              className={isSelected ? "issue issue-selected" : "issue"}
              onClick={() => onSelect(issue.id)}
              aria-pressed={isSelected}
            >
              <span className="issue-top">
                <span className="issue-id">{issue.identifier}</span>
                <span className={priorityClass(issue.priorityLabel)}>{issue.priorityLabel}</span>
              </span>
              <span className="issue-title">{issue.title}</span>
              <span className="issue-meta">
                <span className="issue-state">{issue.stateName}</span>
                {total > 0 && <span className="issue-total">{formatTotal(total)} logged</span>}
              </span>
            </button>
          </li>
        );
      })}
    </ul>
  );
}
