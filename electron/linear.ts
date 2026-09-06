import type { IssuesResult, LinearIssue } from "./types";

const sampleFallback: LinearIssue[] = [
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
];

export function hasApiKey(): boolean {
  return Boolean(process.env.LINEAR_API_KEY);
}

/**
 * Fetches the current user's assigned issues from Linear. `@linear/sdk` is an
 * ESM package, so it is imported dynamically to stay compatible with the
 * CommonJS Electron main process. Falls back to sample data if no key is set.
 */
export async function fetchIssues(): Promise<IssuesResult> {
  const apiKey = process.env.LINEAR_API_KEY;
  if (!apiKey) {
    return { source: "sample", issues: sampleFallback };
  }

  const { LinearClient } = await import("@linear/sdk");
  const client = new LinearClient({ apiKey });
  const viewer = await client.viewer;
  const assigned = await viewer.assignedIssues({ first: 25 });

  const issues: LinearIssue[] = [];
  for (const issue of assigned.nodes) {
    const state = await issue.state;
    issues.push({
      id: issue.id,
      identifier: issue.identifier,
      title: issue.title,
      url: issue.url,
      stateName: state?.name ?? "Unknown",
      stateType: state?.type ?? "unstarted",
      priorityLabel: issue.priorityLabel,
    });
  }

  return { source: "live", issues };
}
