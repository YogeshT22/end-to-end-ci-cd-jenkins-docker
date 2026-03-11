#!/bin/bash
# docker-entrypoint.sh
# -----------------------------------------------------------------------
# Fixes the docker group GID at container start-up to match the GID of
# the host's /var/run/docker.sock. This is necessary because the host
# socket GID is not known at image build time (it differs per machine).
#
# Without this, the jenkins user cannot reach the Docker API even though
# it is a member of the 'docker' group inside the container.
# -----------------------------------------------------------------------
set -euo pipefail

SOCK=/var/run/docker.sock

if [ -S "$SOCK" ]; then
    HOST_GID=$(stat -c '%g' "$SOCK")
    CURRENT_GID=$(getent group docker | cut -d: -f3)

    if [ "$HOST_GID" != "$CURRENT_GID" ]; then
        echo "[entrypoint] Adjusting docker group GID: ${CURRENT_GID} -> ${HOST_GID}"
        sudo groupmod -g "$HOST_GID" docker
    else
        echo "[entrypoint] docker group GID already matches host (${HOST_GID}), no change needed"
    fi
else
    echo "[entrypoint] WARNING: ${SOCK} not found - Docker builds will not work"
fi

# Drop privileges are already handled - jenkins user runs this script.
# Exec the real Jenkins entrypoint.
exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"
