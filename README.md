# MB AL Graph Demo

A free VS Code extension that demonstrates **graph engineering** for Business Central AL: three chained Copilot agents (Code, Verify, Review), a resumable `state.json` bookmark, and a real, code-enforced retry limit.

This extension showcases the pattern from [graph-engineering-business-central-al](https://mbaic.github.io/2026/07/06/graph-engineering-business-central-al/) — extending the proven design from [mb-copilot-al-loop-demo](https://github.com/mbaic/mb-copilot-al-loop-demo) with a three-station graph topology and script-enforced resumability.

## What is it?

Three custom Copilot agents running in sequence:

1. **Code** — Edits AL objects to satisfy a requirement. Writes the bookmark.
2. **Verify** — Compiles the project and reads diagnostics. Attempts capped at 3 per session by a workspace hook.
3. **Review** — Checks the diff against the requirement. Read-only; approves or sends back to Code.

Each transition between stations is a manual handoff (a button click), so a human is always in control. When Verify hits an error, you click to send it back to Code with the error text pre-filled. When Review finds a gap, the same loop resumes from Code.

## Installation

1. Download the latest `.vsix` from [Releases](https://github.com/mbaic/mb-copilot-al-graph-demo/releases).
2. In VS Code, run **Extensions: Install from VSIX** and select the file.
3. Open an AL project workspace.

## First use

### Copy the hook into your project

The extension includes workspace hooks that enforce the attempt limit. Copy them into your AL project:

```bash
cp -r .github/hooks <your-al-project>/.github/
```

On Windows, you can do this manually: copy the `.github/hooks/` folder from this repo into your AL project's `.github/` folder.

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
- **`attempt` / `limit`**: Managed by the workspace hook (Verify only).
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

### The hook doesn't fire

- Confirm `.github/hooks/` exists in your AL project.
- Check that the hook files have execute permissions (`chmod +x .github/hooks/al-graph-limit.sh` on macOS/Linux).
- On Windows, ensure PowerShell's execution policy allows the script (`-ExecutionPolicy Bypass`).

### Attempt limit reached, but I need more tries

Edit `.github/hooks/hooks.json` and change the `LIMIT=3` value in both `.sh` and `.ps1` scripts. The limit is enforced locally in your workspace hook, not by the extension.

### state.json ends up in the wrong place

The hook tries to write to the workspace root (`.`). If that resolves somewhere unexpected, check your VS Code workspace settings and confirm the workspace folder path is correct.

## Development and testing

Build the extension:

```bash
npm install -g @vscode/vsce
vsce package
```

Install the `.vsix` via **Extensions: Install from VSIX** and test against a real AL project with the hook copied in.

### Test checklist

1. Confirm all three agents load in Copilot Chat customizations.
2. Run `/al-graph-start` with a small, intentional error (reference a nonexistent field).
3. Verify that Code edits only AL files and creates `state.json`.
4. Trigger 4 consecutive failing builds to confirm the hook blocks the 4th attempt.
5. Try to trick Review into editing a file (it should refuse).

## Known limitations

- This design has never been end-to-end tested in a real VS Code install. Treat it as structurally plausible and more carefully grounded than its predecessor, but still functionally unverified until you run it.
- The `tools: ['search']` limit on Review has not been independently confirmed. Before you rely on it as a safety boundary, test that Review genuinely cannot edit files.
- Multiple agents in one extension add their descriptions to every chat session, used or not — a known VS Code behavior noted in the linked blog post.

## License

MIT — same as [mb-copilot-al-loop-demo](https://github.com/mbaic/mb-copilot-al-loop-demo).

## See also

- [Graph Engineering for Business Central AL](https://mbaic.github.io/2026/07/06/graph-engineering-business-central-al/) — the blog post behind this design.
- [mb-copilot-al-loop-demo](https://github.com/mbaic/mb-copilot-al-loop-demo) — the loop-engineering predecessor.
- [mb-al-ai-toolkit](https://github.com/mbaic/mb-al-ai-toolkit) — related AL/Copilot tooling.
