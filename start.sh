#!/bin/bash
#########################
# Firebox launch script #
#########################

# Exit on error.
set -euo pipefail

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

log "=== Firebox start script initiated ==="

#################
# Display stuff #
#################

# Export display number to everywhere.
export DISPLAY=${DISPLAY:-:1}

# Doing X socket stuff.
if [ ! -d /tmp/.X11-unix ]; then
  log "ERROR: /tmp/.X11-unix missing (should be created in image as 1777)."
  exit 1
fi

log "Using DISPLAY=$DISPLAY"

# Clean up prev crash/restart.
rm -f /tmp/.X1-lock || true

# Start a headless X server on $DISPLAY
Xvfb "$DISPLAY" -screen 0 1280x720x24 -nolisten tcp &
log "Started Xvfb on $DISPLAY (PID=$!)"

# Wait until Xvfb answers.
for i in {1..50}; do
  if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

log "Xvfb ready"

############
# Programs #
############

#########
# BSPWM #
#########
# Start window manager.
bspwm &
log "Started bspwm (PID=$!)"

###########
# Firefox #
###########

# Clean Firefox crash lock (safe, does not delete profile data)

# Needed by Firefox.
if ! dbus-send --session --dest=org.freedesktop.DBus --type=method_call / org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
  eval "$(dbus-launch --sh-syntax)"
fi
log "DBus session ready"

#############
# Tiger VNC #
#############
x0vncserver -display "$DISPLAY" \
  -rfbauth "$HOME/secret/vnc.pass" \
  -AlwaysShared=1 \
  -AcceptCutText=1 -SendCutText=1 \
  -SetPrimary=1 -SendPrimary=1 &
log "Started x0vncserver (PID=$!)"

#####################
# Websocify - noVNC #
#####################
websockify --web=/opt/novnc 6080 localhost:5900 &
log "Started websockify (PID=$!)"

##########
# Tweaks #
##########

export MOZ_ENABLE_WAYLAND=0
export GDK_BACKEND=x11
export LIBGL_ALWAYS_SOFTWARE=1
export MOZ_WEBRENDER=1
export MOZ_X11_EGL=1

######################
# The container loop #
######################

###########
# Firefox #
###########

clean_firefox_lock() {
  # Detect default Firefox profile dir (works whether it’s in $HOME/.mozilla/firefox or a bind mount)
  local FF_PROFILES_INI="${FF_PROFILES_INI:-$HOME/.mozilla/firefox/profiles.ini}"
  local FF_PROFILE_REL FF_PROFILE_DIR

  if [ -f "$FF_PROFILES_INI" ]; then
    FF_PROFILE_REL=$(awk -F= '
      /^\[Profile/ {insec=1; def=0; path=""}
      insec && $1=="Default" && $2==1 {def=1}
      insec && $1=="Path" {path=$2}
      /^\[/ && NR>1 { if (def && path!="") {print path; exit} insec=0 }
      END { if (def && path!="") print path }
    ' "$FF_PROFILES_INI")
    if [ -n "$FF_PROFILE_REL" ]; then
      FF_PROFILE_DIR="$HOME/.mozilla/firefox/$FF_PROFILE_REL"
    fi
  fi

  # Fallback if detection fails (OPTIONAL: set your known path here)
  FF_PROFILE_DIR="${FF_PROFILE_DIR:-/data/self/firebox/profile/firefox/vy8d4ivu.default-release}"

  rm -f "$FF_PROFILE_DIR/lock" "$FF_PROFILE_DIR/.parentlock" 2>/dev/null || true
}

# Optional: quiet sandbox EPERM warnings in containers
export MOZ_DISABLE_CONTENT_SANDBOX=1

log "Starting Firefox loop"
while true; do
  clean_firefox_lock
  log "Launching Firefox (log appended to /tmp/firefox.log)"

  # Let firefox fail without killing the loop (because set -e is on)
  set +e
  firefox >>/tmp/firefox.log 2>&1
  EXIT_CODE=$?
  set -e

  log "Firefox exited with code $EXIT_CODE"
  sleep 5
done

