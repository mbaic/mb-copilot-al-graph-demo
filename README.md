# MB AL Graph Demo

This extension is a small, working example of **graph engineering** for Business Central AL development.

Graph engineering chains several checks into fixed stations, in a fixed order. Each station has its own check. A bookmark file records the current station. A run can pause. A run can resume. It does not start over.

Read the background post first: [Graph Engineering: Wiring Loops Together in AL Delivery](https://mbaic.github.io/2026/07/06/graph-engineering-business-central-al/).

## What this extension adds to VS Code

This extension adds five things to Copilot Chat:

1. **Three custom agents.** `al-graph-code`, `al-graph-verify`, `al-graph-review`. Each agent runs one station.
2. **A slash command**, `/al-graph-start`. Type this command to start the Code station.
3. **Handoff buttons.** Each agent ends its turn with a button. The button hands off to the next agent, with a pre-filled prompt. You click the button. No agent moves to the next station on its own.
4. **A bookmark file**, `state.json`. It records which station finished, and the result. You can stop a run and resume it later at the correct station, instead of redoing finished work.
5. **A hard attempt limit.** The Verify station tries the build 3 times. On the 4th try, a script blocks the build tool and stops the run. The limit is code, not a request to the model.

This extension does not add a new AI model. It does not add a new compiler. It uses the tools that the AL Language extension already gives to Copilot: `al_build` and `al_getdiagnostics`. This extension adds the graph around them, and one enforcement script.

## Before you start

You need:

- Visual Studio Code, a recent version. Custom agents, handoffs, and hooks are **Preview** features. Update VS Code if you do not see the behavior this README describes.
- The **AL Language** extension, version 17.0 or later.
- **GitHub Copilot Chat**, installed and signed in.
- An AL project open in VS Code, with `app.json` at its root.
- Copilot Chat set to **Agent** mode.

You do not need Node.js, npm, or any build tool to use this extension. You only need these tools if you want to change the extension and repackage it.

## Install

1. Go to the [Releases](../../releases) page of this repository.
2. Download the file `mb-al-graph-demo-<version>.vsix`.
3. Open VS Code.
4. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) to open the Command Palette.
5. Type **Extensions: Install from VSIX** and press Enter.
6. Select the downloaded `.vsix` file.
7. Reload VS Code if it asks you to.
8. **Copy the attempt-limit hook into your AL project.** This step is required. See the next section.

### Copy the hook into your project

VS Code documents one confirmed location for a hook file: a `.github/hooks/` folder inside your own open workspace. An installed extension has no confirmed way to register a hook by itself, so this extension cannot do this step for you.

Do this once, for each AL project where you want the attempt limit to apply:

1. Open this repository on GitHub, in the `.github/hooks/` folder.
2. Download `hooks.json`, `al-graph-limit.sh`, and `al-graph-limit.ps1`.
3. In your AL project, create a folder named `.github/hooks/` at the project root, if it does not already exist.
4. Copy the three files into that folder. Keep the file names exactly as they are.

If your AL project already has a `.github/hooks/` folder from another tool, add these three files to it. Do not replace files you do not recognize.

## Try it

1. Open an AL project with the hook copied in as described above.
2. Open Copilot Chat.
3. Type this command and press Enter:

   ```
   /al-graph-start add a Discount % decimal field to table extension Sales Line Ext, expose it on page extension Sales Line Page Ext, and add a ValidateDiscountPct procedure that errors outside 0-100
   ```

4. The Code agent writes the field, the page exposure, and the validation procedure.
5. Copilot shows a button: **Send to Verify**. Read the diff first. Click the button when you are ready.
6. The Verify agent builds the project and reads the diagnostics. It reports pass or fail. On a fail, it offers a **Send back to Code** button with the error pre-filled. This can happen up to 3 times. On the 4th try, the hook blocks the build and the run stops on its own.
7. On a pass, Copilot shows a button: **Send to Review**. Click it.
8. The Review agent compares the diff against your original request. It reports "approved," or it lists what is missing. Review never edits a file.
9. On approval, Review tells you the change is ready. **You still do the last step by hand:** open Source Control, read every line of the diff, and commit and push it yourself.

Stop the run at any point. Close VS Code. Open it again later. Check `state.json` at the root of your project. It names the last finished station. Start your next prompt at that station instead of from Code.

## What is inside this repository

| File | Purpose |
|------|---------|
| `agents/al-graph-code.agent.md` | The Code station. Writes or edits AL objects for one small change. |
| `agents/al-graph-verify.agent.md` | The Verify station. Builds the project and reads diagnostics. No edit tool. |
| `agents/al-graph-review.agent.md` | The Review station. Checks the diff against the requirement. No edit tool. |
| `prompts/al-graph-start.prompt.md` | The `/al-graph-start` slash command. |
| `.github/hooks/hooks.json` | Registers the attempt-limit script. Copy this folder into your own AL project. |
| `.github/hooks/al-graph-limit.sh` | The attempt-limit script, for macOS and Linux. |
| `.github/hooks/al-graph-limit.ps1` | The attempt-limit script, for Windows. |
| `package.json` | The extension manifest. Contributes the three agents and the prompt. No compiled code. |

## How the attempt limit works

Before the Verify agent runs the AL build tool, VS Code runs the script you copied into `.github/hooks/al-graph-limit.sh` (or `.ps1` on Windows). The script does four things:

1. It checks whether the current tool call is a build.
2. If it is, the script adds 1 to a counter for this chat session.
3. If the counter is 3 or lower, the script allows the build, and writes the attempt number and station name to `state.json`.
4. If the counter is higher than 3, the script blocks the build, writes "blocked" to `state.json`, and tells the agent why.

This means the limit holds even if the model ignores its own instructions. The block happens in the script, not in the model's judgment.

The Code and Review stations write their own part of `state.json` using their own edit permission and their own instructions. This part is a prompt-level rule, not a script-enforced one. Trust it the same way you trust the "never commit" rule below: normally reliable, not a hard guarantee. The one hard guarantee in this extension is the Verify attempt limit.

## What this demo does not do

This demo matches the scope of the background post. It does not go further:

- It handles **one small change** at a time. It does not run several changes in parallel. The background post rules this out on purpose.
- Verify checks the **compiler only**. It does not run test codeunits. The loop-engineering demo this graph builds on has the same limit, for the same reason: keep the demo small.
- It does not cap Review rejections at a fixed number. Only the Verify-to-Code cycle has a script-enforced limit, matching the background post's "up to three tries" language, which applies to Verify only.
- It does not add a cost cap. The background post names a cost cap as a future step. This demo does not add one: VS Code hooks give no documented way to read token cost, so a cost cap here would be a guess dressed up as a feature.
- It **never merges a pull request.** It never publishes to Business Central. Review approval means the change is ready for a human. It does not mean the change is live.
- Nothing in this extension touches a live Business Central tenant. All three stations run on your local project files.

## Troubleshooting

**The `/al-graph-start` command does not appear.**
Confirm the extension is installed and enabled. Open the Command Palette and run **Chat: Open Customizations** to see all loaded agents and prompts.

**A handoff button does not appear at the end of a turn.**
Handoffs are a newer Preview feature than the loop-engineering demo used. Update VS Code. If the button still does not appear, ask the agent by name instead: type `@al-graph-verify` (or `@al-graph-review`) and describe what to do, using the same wording the handoff prompt would have used.

**The attempt limit does not stop the agent after 3 tries.**
Confirm you completed "Copy the hook into your project" above. A hook bundled inside an installed extension is not confirmed to load on its own; the `.github/hooks/` folder in your own workspace is the one confirmed location. Run **Developer: Show Agent Debug Logs** and look for `al-graph-limit`. Some organizations turn off agent hooks by policy. Ask your VS Code administrator if this applies to you.

**`state.json` looks wrong or out of date.**
The Verify station's part of the file is script-written and should always be accurate. The Code and Review stations' parts are agent-written, by instruction. If an agent skips this step, edit the file by hand: it is plain JSON.

**Copilot cannot find `al_build` or `al_getdiagnostics`.**
Update the AL Language extension to version 17.0 or later. These tools ship with the AL extension, not with this demo.

## Background reading

- [Graph Engineering: Wiring Loops Together in AL Delivery](https://mbaic.github.io/2026/07/06/graph-engineering-business-central-al/) — the concept this extension demonstrates.
- [Loop Engineering: Give Your AL Copilot a Repeat Button](https://mbaic.github.io/2026/07/03/loop-engineering-business-central-al/) — the single-station pattern this graph chains together.
- [The AL Coding Harness: Your Custom Dashboard](https://mbaic.github.io/2026/06/29/small-agent-harness-business-central-al/) — background on custom agents and instructions for AL.
- [mb-copilot-al-loop-demo](https://github.com/mbaic/mb-copilot-al-loop-demo) — the loop-engineering demo this graph builds on. The Verify station's attempt-limit script follows the same design as that demo's hook.

## License

MIT. See [LICENSE](LICENSE).
