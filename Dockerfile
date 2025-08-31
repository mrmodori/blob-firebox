FROM archlinux:latest

# Install needed packages.
RUN pacman -Sy --noconfirm \
    firefox \
    xorg-server-xvfb \
    x11vnc \
    bspwm \
    mesa \
    xorg-xdpyinfo \
    dbus \
    xdg-user-dirs \
    tigervnc \
 && pacman -Scc --noconfirm

# X socket dir as root.
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

# Silence dbus warnings.
RUN dbus-uuidgen > /etc/machine-id || true

# Create user + home before we touch ownerships/files.
RUN useradd -m -u 1000 firefox && \
    mkdir -p /home/firefox/.mozilla && \
    chown -R 1000:1000 /home/firefox

# put files in the firefox home, not /root.
COPY --chown=1000:1000 start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# move these AFTER setting HOME/USER or use absolute paths:
COPY --chown=1000:1000 user-dirs.dirs /home/firefox/.config/user-dirs.dirs
RUN mkdir -p /home/firefox/outbox

# Switch to non admin user.
USER firefox
ENV HOME=/home/firefox

# bspwm config stays.
RUN mkdir -p $HOME/.config/bspwm && \
    printf '#!/bin/sh\nbspc monitor -d 1\n' > $HOME/.config/bspwm/bspwmrc && \
    chmod +x $HOME/.config/bspwm/bspwmrc

ENTRYPOINT ["/usr/local/bin/start.sh"]
