# AI Screenshot Attachment

> A macOS browser-window screenshot utility for local AI agents, operator tooling, browser automation, evidence capture, and lightweight visual attachment workflows.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-black.svg)
![Shell](https://img.shields.io/badge/built%20with-Bash-121011?logo=gnu-bash)

**AI Screenshot Attachment** is a small, practical command-line utility that captures the active window of a browser on macOS, optionally opens a URL first, and returns a generated image path that can be fed into downstream tooling.

It is designed for setups where an AI assistant, local agent, QA script, browser workflow, or operator runtime needs a fast way to produce a screenshot attachment without a heavy GUI stack.

## Why this exists

This utility solves a narrow but useful problem:

- detect the user's default browser when possible
- target a specific browser application when needed
- optionally open a local or remote URL first
- bring the application to the foreground
- capture the target browser window into a PNG file
- return the file path so another script, tool, or agent can attach or process it

That makes it useful for:

- local AI agent screenshot attachments
- browser automation evidence capture
- HTML app QA snapshots
- localhost preview capture
- debugging visual state during agent runs
- operator workflows that need “open → capture → attach” behavior

## Core behavior

The script currently does the following:

1. Reads the user's default HTTPS handler from macOS LaunchServices on a best-effort basis.
2. Resolves the browser name from the browser bundle identifier using AppleScript.
3. Parses CLI flags for target app selection and optional URL opening.
4. Lists currently running GUI applications and marks recognized browsers.
5. Detects the current frontmost application.
6. Waits for the target app to become frontmost before capture.
7. Uses a Python + Quartz call path to locate the CGWindowID for the target app.
8. Uses `screencapture` to capture either the matched browser window or the frontmost window fallback.
9. Writes the screenshot to `/tmp/browser_screenshot_<timestamp>.png`.
10. Prints the saved path for easy piping into downstream automation.

## Features

- **Default browser detection** on macOS
- **Specific app targeting** for Safari, Chrome, Brave, Firefox, Arc, Edge, Opera, and Vivaldi patterns
- **Optional URL opening** before capture
- **Frontmost-window waiting** to reduce race conditions
- **Window ID targeting** instead of blind full-screen grabs when available
- **Simple stdout path output** for pipelines and agent tooling
- **No external web service required**

## Example usage

### Auto-target a browser

```bash
./screenshot.sh
```

### Target a specific browser

```bash
./screenshot.sh "Brave Browser"
```

### Force the default browser

```bash
./screenshot.sh --default
```

### Open a URL in a specific app, then capture it

```bash
./screenshot.sh --app "Safari" --url "http://localhost:5000/landing2"
```

### Open a local dev server in your default browser, then capture it

```bash
./screenshot.sh --default --url "http://localhost:3000"
```

## Requirements

- macOS
- Bash
- AppleScript / `osascript`
- `screencapture`
- Python 3
- Quartz access available to Python on the host system
- Accessibility / screen recording permissions as required by macOS

## Installation

### Clone the repo

```bash
git clone https://github.com/YOUR-USERNAME/ai-screenshot-attachment.git
cd ai-screenshot-attachment
chmod +x screenshot.sh
```

### Run directly

```bash
./screenshot.sh --default --url "http://localhost:3000"
```

## Output

The script writes a PNG file to a temporary path like:

```text
/tmp/browser_screenshot_1712345678.png
```

The final line of stdout is the saved path, which is useful in shell pipelines or AI tool wrappers.

## How it fits into AI workflows

This repo is especially useful when paired with:

- local AI agents that need screenshot attachments
- autonomous QA runners
- browser-based app testing
- repo demo capture scripts
- evidence generation for bug reports
- operator runtimes that chain shell tools together

Example wrapper pattern:

```bash
SCREENSHOT_PATH=$(./screenshot.sh --default --url "http://localhost:3000" | tail -n 1)
echo "Saved to: $SCREENSHOT_PATH"
# attach to your own downstream tool here
```

## Known limitations

- macOS-only in its current form
- depends on AppleScript and Quartz-compatible Python access
- browser detection is pattern-based, not a formal registry of supported apps
- frontmost-window behavior can still be affected by OS focus rules
- not yet packaged for Homebrew, pip, or signed distribution
- no retry/backoff policy beyond the current frontmost wait loop

## Roadmap

- Homebrew formula support
- optional output path flag
- optional delay flag before capture
- JSON output mode for agents
- richer error codes for orchestration systems
- multi-window selection
- optional full-screen or region mode
- GitHub release artifacts
- test harness for browser detection and focus timing

## Recommended repository topics

Use topics like these on GitHub for findability:

- `screenshot`
- `macos`
- `browser-automation`
- `bash`
- `cli`
- `agent-tools`
- `ai-tools`
- `automation`
- `computer-use`
- `qa-automation`
- `developer-tools`
- `visual-testing`

## Suggested GitHub repo settings

After pushing the repo, turn on or configure:

- Issues
- Discussions (optional but useful for user questions)
- Releases
- Topics
- Social preview image
- Sponsor button if you want monetization visibility
- Default labels and issue forms

A starter release tag could be:

```text
v0.1.0
```

Release title:

```text
AI Screenshot Attachment v0.1.0
```

## Security and permissions note

This script interacts with macOS windowing, focus, and screenshot behavior. Users may need to grant screen recording and accessibility permissions depending on system configuration.

## License

MIT
