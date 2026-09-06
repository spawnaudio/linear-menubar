import { contextBridge, ipcRenderer } from "electron";
import type { IssuesResult } from "./types";

contextBridge.exposeInMainWorld("linear", {
  isElectron: true,
  hasApiKey: (): Promise<boolean> => ipcRenderer.invoke("linear:hasApiKey"),
  fetchIssues: (): Promise<IssuesResult> => ipcRenderer.invoke("linear:fetchIssues"),
});
