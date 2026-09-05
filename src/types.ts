export interface LinearIssue {
  id: string;
  identifier: string;
  title: string;
  url: string;
  stateName: string;
  stateType: string;
  priorityLabel: string;
}

export type IssueSource = "live" | "sample";

export interface IssuesResult {
  source: IssueSource;
  issues: LinearIssue[];
}

/**
 * Bridge exposed by the Electron preload script. It is absent when the
 * renderer runs as a plain web page (e.g. `vite dev` in a browser), in which
 * case the app falls back to bundled sample issues.
 */
export interface LinearBridge {
  isElectron: true;
  hasApiKey: () => Promise<boolean>;
  fetchIssues: () => Promise<IssuesResult>;
}

declare global {
  interface Window {
    linear?: LinearBridge;
  }
}
