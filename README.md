# MB AL Graph Demo

A free VS Code extension that demonstrates **graph engineering** for Business Central AL: three chained Copilot agents (Code, Verify, Review), a resumable `state.json` bookmark, and an attempt limit that a hook enforces. You must copy the hook into your AL project. See [Install the hook](#install-the-hook).

This extension showcases the pattern from [graph-engineering-business-central-al](https://mbaic.github.io/2026/07/06/graph-engineering-business-central-al/) — extending the proven design from [mb-copilot-al-loop-demo](https://github.com/mbaic/mb-copilot-al-loop-demo) with a three-station graph topology and script-enforced resumability.

## What is it?

Three custom Copilot agents running in sequence:

1. **Code** — Edits AL objects to satisfy a requirement. Writes the bookmark.
2. **Verify** — Compiles the project and reads diagnostics. A hook caps the attempts at 3 per session (after you [install the hook](#install-the-hook)).
3. **Review** — Checks the diff against the requirement. Read-only; approves or sends back to Code.

Each transition between stations is a manual handoff (a button click), so a human is always in control. When Verify hits an error, you click to send it back to Code with the error text pre-filled. When Review finds a gap, the same loop resumes from Code.

## Installation

1. Download the latest `.vsix` file from [Releases](https://github.com/mbaic/mb-copilot-al-graph-demo/releases).
2. In VS Code, run **Extensions: Install from VSIX**. Select the file.
3. Open your AL project.
4. Install the hook. See [Install the hook](#install-the-hook).

## Install the hook

The attempt limit works only when the hook is in your AL project.
VS Code does not load hooks from an installed extension.
An extension has no contribution point for hooks.
If you do not install the hook, the Verify agent can build more than 3 times.

### Requirements

- Use the **Local** session target in Copilot Chat. The hook is written for the Local hook format. Other session targets can use different hook formats. This hook is not tested on them.
- Set `chat.useHooks` to `true`. This setting is on by default.
- Trust the workspace. VS Code does not run workspace hooks in an untrusted workspace.
- macOS and Linux only: install `jq`. The hook script needs it.

### Copy the hook files

1. Open the [`.github/hooks`](https://github.com/mbaic/mb-copilot-al-graph-demo/tree/main/.github/hooks) folder in this repository.
2. Copy these three files to `.github/hooks/` in your AL project:
   - `hooks.json`
   - `al-graph-limit.sh`
   - `al-graph-limit.ps1`
3. macOS and Linux only: make the script executable.

   ```bash
   chmod +x .github/hooks/al-graph-limit.sh
   ```

4. In VS Code, run **Chat: Configure Hooks** from the Command Palette. Make sure the hook is in the list.
5. Commit the three files if you want your team to use the limit.

### Start the graph

1. Open the Copilot Chat panel (**Ctrl+Shift+I** / **Cmd+Shift+I**).
2. Type `/al-graph-start` and describe your requirement: *"Add a new field to the Item table."*

The Code agent runs, edits your files, then offers a handoff button to Verify.

### Verify and Review

Click the button (or type `@al-graph-verify`) to move to Verify. It compiles the project. If it builds:
- You see a "Send to Review" button.
- Click it (or `@al-graph-review`) for the Review agent to check the diff.

If the build fails, you get:
- The error from the diagnostic tool.
- A "Send back to Code" button with the error text pre-filled.
- Click it to loop back and fix the issue.

Once Review approves, you're ready to commit the change and open a pull request.

## State and resumability

The graph writes and reads `state.json` at your workspace root:

```json
{
  "node": "code | verify | review",
  "result": null,
  "attempt": 0,
  "limit": 3,
  "commit": null,
  "updated": "2026-09-02T12:00:00Z"
}
```

- **`node`**: Which station last ran.
- **`attempt` / `limit`**: Managed by the hook (Verify only). The hook must be installed.
- **`result`**: `pending`, `pass`, `fail`, or `blocked`.
- **`commit`**: You fill this in by hand after committing (e.g., `"abc123"`).
- **`updated`**: ISO 8601 timestamp of the last change.

If you interrupt the graph and come back later, each agent checks the state and can skip ahead or resume from where it stopped.

## What this extension does NOT do

- **No auto-commit.** You review and commit by hand, like a real workflow.
- **No cost cap.** Cost tracking is future work; the attempt limit is code-enforced, a cost cap is not yet.
- **No Review retry cap.** The post specifies three tries for Verify only. Review loops back on request, with no hard limit.
- **No publish or merge.** No agent touches your remote repo or tenant. "Approved" means "ready for a human," and nothing more.

## Troubleshooting

### Handoff buttons don't appear

Type the agent name directly: `@al-graph-verify`, `@al-graph-review`, or `@al-graph-code`.

### The hook does not run

- Run **Chat: Configure Hooks**. Make sure `al-graph-limit` is in the list.
- Make sure the session target is **Local**.
- Make sure `chat.useHooks` is `true` and you trust the workspace.
- Open the **Output** panel. Select the **GitHub Copilot Chat Hooks** channel. Read the errors.
- Open **Developer: Show Agent Debug Logs**. Find an `al_build` call. Make sure its `tool_name` is exactly `al_build`. The hook checks this name.
- macOS and Linux only: make sure `jq` is installed and the script is executable.
- Windows only: make sure PowerShell can run the script (`-ExecutionPolicy Bypass`).

> **Warning:** If the hook script fails, VS Code shows a warning and lets the tool call continue. The limit is then not enforced.

### I need more than 3 attempts

Change `LIMIT=3` in `al-graph-limit.sh`. Change `$Limit = 3` in `al-graph-limit.ps1`. Use the same number in both files.

### state.json ends up in the wrong place

The hook writes `state.json` to the working directory (`cwd`) that VS Code gives to the hook. If that resolves somewhere unexpected, check your VS Code workspace settings and confirm the workspace folder path is correct.

## Development and testing

Build the extension:

```bash
npm install -g @vscode/vsce
vsce package
```

Install the `.vsix` with **Extensions: Install from VSIX**. Test it in a real AL project. Copy the hook into the project first.

### Test checklist

1. Confirm all three agents load in Copilot Chat customizations.
2. Run `/al-graph-start` with a small, intentional error (reference a nonexistent field).
3. Verify that Code edits only AL files and creates `state.json`.
4. Trigger 4 consecutive failing builds. Confirm the hook blocks the 4th `al_build`. Open **Developer: Show Agent Debug Logs** and find the `PreToolUse` event with `permissionDecision: deny`.
5. Try to trick Review into editing a file (it should refuse).

## Known limitations

- This design has never been end-to-end tested in a real VS Code install. Treat it as structurally plausible and more carefully grounded than its predecessor, but still functionally unverified until you run it.
- VS Code hooks are a Preview feature. Their behavior can change.
- The hook is a code check, but it is not a hard guarantee. If the script fails, VS Code continues the tool call.
- The `/al-graph-start` prompt file is not loaded in Agent Host sessions. Use the Local session target.
- The `tools: ['search']` limit on Review has not been independently confirmed. Before you rely on it as a safety boundary, test that Review genuinely cannot edit files.
- Multiple agents in one extension add their descriptions to every chat session, used or not — a known VS Code behavior noted in the linked blog post.

## License

MIT — same as [mb-copilot-al-loop-demo](https://github.com/mbaic/mb-copilot-al-loop-demo).

## See also

- [Graph Engineering for Business Central AL](https://mbaic.github.io/2026/07/06/graph-engineering-business-central-al/) — the blog post behind this design.
- [mb-copilot-al-loop-demo](https://github.com/mbaic/mb-copilot-al-loop-demo) — the loop-engineering predecessor.
- [mb-al-ai-toolkit](https://github.com/mbaic/mb-al-ai-toolkit) — related AL/Copilot tooling.
