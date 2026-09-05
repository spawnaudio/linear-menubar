import type { IssuesResult } from "../types";
import { sampleIssues } from "../data/sampleIssues";

/**
 * Loads issues from the Electron/Linear bridge when available, otherwise
 * returns bundled sample issues so the UI works in a plain browser.
 */
export async function loadIssues(): Promise<IssuesResult> {
  if (window.linear?.isElectron) {
    try {
      return await window.linear.fetchIssues();
    } catch (err) {
      console.error("Falling back to sample issues:", err);
    }
  }
  return { source: "sample", issues: sampleIssues };
}
