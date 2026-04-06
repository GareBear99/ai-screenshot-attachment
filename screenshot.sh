#!/bin/bash

# Enhanced screenshot script with app detection
# Usage:
#   ./screenshot.sh                     # auto-target browser (prefers default)
#   ./screenshot.sh "Brave Browser"      # target specific app
#   ./screenshot.sh --default            # force default browser
#   ./screenshot.sh --app "Safari" --url "http://localhost:5000/landing2"
# Flags:
#   --default       Use system default browser
#   --app NAME      Target a specific application name
#   --url URL       Open URL in target app before screenshot

SCREENSHOT_PATH="/tmp/browser_screenshot_$(date +%s).png"

# Get default browser bundle id (best-effort)
DEFAULT_BROWSER_BUNDLEID=$(defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | \
  awk '/LSHandlerURLScheme = https;/{flag=1} flag && /LSHandlerRoleAll/{print $3; exit}')
DEFAULT_BROWSER_BUNDLEID=${DEFAULT_BROWSER_BUNDLEID//;/}
DEFAULT_BROWSER_BUNDLEID=${DEFAULT_BROWSER_BUNDLEID//\"/}

# Resolve default browser app name from bundle id (if possible)
resolve_app_name_from_bundleid() {
  local bid="$1"
  if [ -z "$bid" ]; then echo ""; return; fi
  # Try AppleScript first
  local name
  name=$(osascript -e "try
  tell application id \"$bid\" to return name
  on error
  return \"\"
  end try")
  echo "$name"
}
DEFAULT_BROWSER_NAME=$(resolve_app_name_from_bundleid "$DEFAULT_BROWSER_BUNDLEID")

# Parse args
TARGET_APP=""
OPEN_URL=""
FORCE_DEFAULT=false
while [ $# -gt 0 ]; do
  case "$1" in
    --default)
      FORCE_DEFAULT=true; shift ;;
    --app)
      TARGET_APP="$2"; shift 2 ;;
    --url)
      OPEN_URL="$2"; shift 2 ;;
    *)
      # Back-compat single positional app name
      if [ -z "$TARGET_APP" ]; then TARGET_APP="$1"; fi
      shift ;;
  esac
done

echo "========================================"
echo "Running Applications:"
if [ -n "$DEFAULT_BROWSER_NAME$DEFAULT_BROWSER_BUNDLEID" ]; then
  echo "(Default browser: ${DEFAULT_BROWSER_NAME:-unknown} ${DEFAULT_BROWSER_BUNDLEID:+($DEFAULT_BROWSER_BUNDLEID)})"
fi
echo "========================================"

# List all running GUI applications  
osascript -e 'tell application "System Events" to get name of every application process whose background only is false' 2>/dev/null | tr ',' '\n' | sed 's/^ //g' | while read app; do
  if [[ "$app" =~ (Brave|Chrome|Firefox|Safari|Arc|Vivaldi|Edge|Opera) ]]; then
    # Compare bundle id to mark default accurately
    app_bid=$(osascript -e "try
      tell application \"$app\" to id
      on error
      return \"\"
      end try")
    if [ -n "$DEFAULT_BROWSER_BUNDLEID" ] && [ "$app_bid" = "$DEFAULT_BROWSER_BUNDLEID" ]; then
      echo "  • $app [DEFAULT BROWSER]"
    else
      echo "  • $app [Browser]"
    fi
  else
    echo "  • $app"
  fi
done

echo "========================================"
echo ""

# Helper: get current frontmost app name
frontmost_app() {
  osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null
}

# Helper: wait until app is frontmost (timeout seconds)
wait_frontmost() {
  local app="$1"; local timeout="${2:-5}"; local waited=0
  while [ $waited -lt $timeout ]; do
    fm=$(frontmost_app)
    if [ "$fm" = "$app" ]; then return 0; fi
    sleep 0.2; waited=$((waited+1))
  done
  return 1
}

# Function to get window ID for an app
get_window_id() {
    local app_name="$1"
    # Use Python to get the CGWindowID
    python3 - <<PYEOF
import subprocess
import json

app_name = "$app_name"

# Get window list from CGWindowListCopyWindowInfo
result = subprocess.run(
    ['python3', '-c', '''
import Quartz
import json
windows = Quartz.CGWindowListCopyWindowInfo(
    Quartz.kCGWindowListOptionOnScreenOnly | Quartz.kCGWindowListExcludeDesktopElements,
    Quartz.kCGNullWindowID
)
print(json.dumps([dict(w) for w in windows]))
'''],
    capture_output=True,
    text=True
)

if result.returncode == 0:
    windows = json.loads(result.stdout)
    for window in windows:
        if window.get('kCGWindowOwnerName') == app_name and window.get('kCGWindowLayer') == 0:
            print(window['kCGWindowNumber'])
            break
PYEOF
}

# Decide target app
if [ "$FORCE_DEFAULT" = true ] && [ -n "$DEFAULT_BROWSER_NAME" ]; then
  TARGET_APP="$TARGET_APP"; [ -z "$TARGET_APP" ] && TARGET_APP="$DEFAULT_BROWSER_NAME"
fi

if [ -z "$TARGET_APP" ]; then
  # Auto-detect running browser (prefer default if running)
  RUNNING_BROWSERS=$(osascript -e 'tell application "System Events" to get name of every application process whose background only is false' 2>/dev/null | tr ',' '\n' | sed 's/^ //g' | grep -iE 'Chrome|Firefox|Safari|Brave|Arc|Edge|Opera|Vivaldi' || true)
  if [ -n "$DEFAULT_BROWSER_NAME" ] && echo "$RUNNING_BROWSERS" | grep -qx "$DEFAULT_BROWSER_NAME"; then
    TARGET_APP="$DEFAULT_BROWSER_NAME"
  else
    TARGET_APP=$(echo "$RUNNING_BROWSERS" | head -1)
  fi
fi

# If we still don't have a target, fallback to default by bundle id
if [ -z "$TARGET_APP" ] && [ -n "$DEFAULT_BROWSER_BUNDLEID" ]; then
  echo "Launching default browser by bundle id: $DEFAULT_BROWSER_BUNDLEID"
  if [ -n "$OPEN_URL" ]; then
    open -b "$DEFAULT_BROWSER_BUNDLEID" "$OPEN_URL"
  else
    open -b "$DEFAULT_BROWSER_BUNDLEID"
  fi
  TARGET_APP=$(resolve_app_name_from_bundleid "$DEFAULT_BROWSER_BUNDLEID")
fi

if [ -z "$TARGET_APP" ]; then
  echo "Error: Could not determine a target application to capture."; exit 1
fi

echo "📸 Target application: $TARGET_APP${DEFAULT_BROWSER_NAME:+ $( [ "$TARGET_APP" = "$DEFAULT_BROWSER_NAME" ] && echo "[DEFAULT]" )}"

# Bring app frontmost (and optionally open URL)
if [ -n "$OPEN_URL" ]; then
  open -a "$TARGET_APP" "$OPEN_URL"
else
  open -a "$TARGET_APP"
fi

# Wait until it is truly frontmost
if ! wait_frontmost "$TARGET_APP" 25; then
  fm=$(frontmost_app)
  echo "Error: $TARGET_APP did not become frontmost (frontmost is: $fm)."; exit 1
fi

# Get window ID and capture
WINDOW_ID=$(get_window_id "$TARGET_APP")
if [ -n "$WINDOW_ID" ]; then
  echo "Found window ID: $WINDOW_ID"
  screencapture -l "$WINDOW_ID" -x "$SCREENSHOT_PATH" 2>/dev/null
else
  echo "Window ID not found; capturing frontmost $TARGET_APP"
  screencapture -o -x "$SCREENSHOT_PATH" 2>/dev/null
fi

echo ""
echo "✅ Screenshot saved to: $SCREENSHOT_PATH"
echo "$SCREENSHOT_PATH"
