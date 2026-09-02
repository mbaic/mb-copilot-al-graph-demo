# Changelog

## 0.1.0 — Unreleased

- MB AL Graph Demo extension for Business Central AL
- Three chained custom agents: al-graph-code, al-graph-verify, al-graph-review
- Handoff buttons between stations, requiring a human click at every transition
- `/al-graph-start` slash command to start the graph at the Code station
- A resumable `state.json` bookmark, partly script-written (Verify), partly agent-written (Code)
- A hard attempt limit of 3 on the Verify station, enforced by a workspace hook you copy into your AL project
- Cross-platform hook scripts: bash (macOS/Linux) and PowerShell (Windows)
