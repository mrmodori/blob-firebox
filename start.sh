#!/bin/bash
#########################
# Firebox launch script #
#########################

# Exit on error.
set -euo pipefail

#################
# Display stuff #
#################

# Export display number to everywhere.
export DISPLAY=${DISPLAY:-:1}

# Doing X socket stuff.
if [ ! -d /tmp/.X11-unix ]; then
  echo "ERROR: /tmp/.X11-unix missing (should be created in image as 1777)."
  exit 1
fi

# Clean up prev crash/restart.
rm -f /tmp/.X1-lock || true

# Start a headless X server on $DISPLAY
Xvfb "$DISPLAY" -screen 0 1280x720x24 -nolisten tcp &

# Wait until Xvfb answers.
for i in {1..50}; do
  if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

############
# Programs #
############

#########
# BSPWM #
#########
# Start window manager.
bspwm &

###########
# Firefox #
###########

# Needed by Firefox.
if ! dbus-send --session --dest=org.freedesktop.DBus --type=method_call / org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
  eval "$(dbus-launch --sh-syntax)"
fi

# Launch Firefox once.
if ! pgrep -x firefox >/dev/null; then
  setsid -f firefox >/tmp/firefox.log 2>&1
fi

#############
# Tiger VNC #
#############
x0vncserver -display "$DISPLAY" \
  -rfbauth "$HOME/secret/vnc.pass" \
  -AlwaysShared=1 \
  -AcceptCutText=1 -SendCutText=1 \
  -SetPrimary=1 -SendPrimary=1

##########
# Tweaks #
##########

export MOZ_ENABLE_WAYLAND=0
export GDK_BACKEND=x11
export LIBGL_ALWAYS_SOFTWARE=1
export MOZ_WEBRENDER=0
export MOZ_X11_EGL=0

# Launch firefox again?
exec firefox
