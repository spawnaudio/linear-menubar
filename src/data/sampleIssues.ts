import type { LinearIssue } from "../types";

// Used when no Linear API key is configured, so the app is fully usable
// (and demonstrable) without any secrets. Set LINEAR_API_KEY to load real
// assigned issues instead.
export const sampleIssues: LinearIssue[] = [
  {
    id: "sample-1",
    identifier: "ADHD-101",
    title: "Write the weekly status update",
    url: "https://linear.app/",
    stateName: "In Progress",
    stateType: "started",
    priorityLabel: "Urgent",
  },
  {
    id: "sample-2",
    identifier: "ADHD-102",
    title: "Review the onboarding flow designs",
    url: "https://linear.app/",
    stateName: "Todo",
    stateType: "unstarted",
    priorityLabel: "High",
  },
  {
    id: "sample-3",
    identifier: "ADHD-103",
    title: "Reply to the accessibility audit thread",
    url: "https://linear.app/",
    stateName: "Todo",
    stateType: "unstarted",
    priorityLabel: "Medium",
  },
  {
    id: "sample-4",
    identifier: "ADHD-104",
    title: "Break the migration ticket into subtasks",
    url: "https://linear.app/",
    stateName: "Backlog",
    stateType: "backlog",
    priorityLabel: "Low",
  },
];
