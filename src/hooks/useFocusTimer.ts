import { useCallback, useEffect, useRef, useState } from "react";

const STORAGE_KEY = "linear-menubar:v1";

interface PersistedState {
  selectedIssueId: string | null;
  accumulatedMs: number;
  runningSince: number | null;
  totals: Record<string, number>;
}

const emptyState: PersistedState = {
  selectedIssueId: null,
  accumulatedMs: 0,
  runningSince: null,
  totals: {},
};

function loadState(): PersistedState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return emptyState;
    const parsed = JSON.parse(raw) as Partial<PersistedState>;
    return {
      selectedIssueId: parsed.selectedIssueId ?? null,
      accumulatedMs: parsed.accumulatedMs ?? 0,
      runningSince: parsed.runningSince ?? null,
      totals: parsed.totals ?? {},
    };
  } catch {
    return emptyState;
  }
}

export interface FocusTimer {
  selectedIssueId: string | null;
  isRunning: boolean;
  elapsedMs: number;
  totals: Record<string, number>;
  select: (issueId: string) => void;
  start: () => void;
  pause: () => void;
  reset: () => void;
  logSession: () => void;
}

function sessionElapsed(state: PersistedState, now: number): number {
  return state.accumulatedMs + (state.runningSince ? now - state.runningSince : 0);
}

export function useFocusTimer(): FocusTimer {
  const [state, setState] = useState<PersistedState>(loadState);
  const [now, setNow] = useState<number>(() => Date.now());
  const tick = useRef<number | null>(null);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }, [state]);

  useEffect(() => {
    if (state.runningSince === null) {
      if (tick.current !== null) {
        window.clearInterval(tick.current);
        tick.current = null;
      }
      return;
    }
    setNow(Date.now());
    tick.current = window.setInterval(() => setNow(Date.now()), 250);
    return () => {
      if (tick.current !== null) {
        window.clearInterval(tick.current);
        tick.current = null;
      }
    };
  }, [state.runningSince]);

  const select = useCallback((issueId: string) => {
    setState((prev) => {
      if (prev.selectedIssueId === issueId) return prev;
      // Commit any time tracked for the previous issue before switching.
      const committed = commit(prev, Date.now());
      return { ...committed, selectedIssueId: issueId, accumulatedMs: 0, runningSince: null };
    });
  }, []);

  const start = useCallback(() => {
    setState((prev) => {
      if (prev.runningSince !== null || prev.selectedIssueId === null) return prev;
      return { ...prev, runningSince: Date.now() };
    });
  }, []);

  const pause = useCallback(() => {
    setState((prev) => {
      if (prev.runningSince === null) return prev;
      const nowMs = Date.now();
      return {
        ...prev,
        accumulatedMs: prev.accumulatedMs + (nowMs - prev.runningSince),
        runningSince: null,
      };
    });
  }, []);

  const reset = useCallback(() => {
    setState((prev) => ({
      ...prev,
      accumulatedMs: 0,
      runningSince: prev.runningSince === null ? null : Date.now(),
    }));
  }, []);

  const logSession = useCallback(() => {
    setState((prev) => ({ ...commit(prev, Date.now()), accumulatedMs: 0, runningSince: null }));
  }, []);

  return {
    selectedIssueId: state.selectedIssueId,
    isRunning: state.runningSince !== null,
    elapsedMs: sessionElapsed(state, now),
    totals: state.totals,
    select,
    start,
    pause,
    reset,
    logSession,
  };
}

function commit(state: PersistedState, now: number): PersistedState {
  const elapsed = sessionElapsed(state, now);
  if (state.selectedIssueId === null || elapsed <= 0) return state;
  const prevTotal = state.totals[state.selectedIssueId] ?? 0;
  return {
    ...state,
    totals: { ...state.totals, [state.selectedIssueId]: prevTotal + elapsed },
  };
}
