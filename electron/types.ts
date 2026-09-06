// Electron-side copy of the shared shapes. Kept separate from the renderer's
// src/types.ts so the main process compiles as a self-contained CommonJS unit
// (rootDir = electron) without pulling DOM/global augmentations into the build.
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
