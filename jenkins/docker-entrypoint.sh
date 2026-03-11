#!/bin/bash
# docker-entrypoint.sh
# -----------------------------------------------------------------------
# Runs as ROOT so it can call groupmod directly (no sudo needed).
# After fixing the docker group GID it uses gosu to re-exec as the
# jenkins user with a fresh group credential set that includes the
# corrected docker GID.  exec-ing via gosu is the only reliable way to
# pass updated supplementary groups to the Jenkins JVM — simply calling
# `exec jenkins.sh` after groupmod does NOT refresh the process groups.
# -----------------------------------------------------------------------
set -euo pipefail

SOCK=/var/run/docker.sock

if [ -S "$SOCK" ]; then
    HOST_GID=$(stat -c '%g' "$SOCK")
    CURRENT_GID=$(getent group docker | cut -d: -f3)

    if [ "$HOST_GID" != "$CURRENT_GID" ]; then
        echo "[entrypoint] Adjusting docker group GID: ${CURRENT_GID} -> ${HOST_GID}"
        groupmod -g "$HOST_GID" docker
    else
        echo "[entrypoint] docker group GID already matches host (${HOST_GID}), no change needed"
    fi
    echo "[entrypoint] docker.sock permissions: $(ls -la $SOCK)"
    echo "[entrypoint] jenkins groups after fix: $(id jenkins)"
else
    echo "[entrypoint] WARNING: ${SOCK} not found - Docker builds will not work"
fi

# Re-exec as jenkins user via gosu so the JVM inherits a fresh group list
# that includes the (possibly updated) docker GID.
exec gosu jenkins /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"
