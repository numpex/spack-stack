#!/bin/sh
#
# Container entrypoint.
#
# When started as root (the default), this script:
#   1. Remaps the in-image `pdi` user to the caller's UID/GID, taken from the
#      $HOST_UID / $HOST_GID environment variables. Pass them at run time, e.g.:
#          podman run -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) ...
#      This makes files created inside the container — and any bind-mounted
#      host directories — usable by the same user on both sides without
#      ownership headaches.
#   2. Activates the Spack environment.
#   3. Runs the PDI tutorial sanity check.
#   4. Drops privileges to `pdi` and execs the requested command.
#
# When started as a non-root user (`podman run --user ...`), steps 1 and 4 are
# skipped; we just activate Spack and exec the command directly.

set -e

SERVICE_USER="pdi"
SERVICE_HOME="/opt/${SERVICE_USER}"

activate_and_exec() {
    # Source the Spack environment, run the sanity check, then exec the CMD.
    . /opt/spack-environment/activate.sh
    /opt/environment_check_script.sh
    exec "$@"
}

if [ "$(id -u)" -ne 0 ]; then
    # Already running as a non-root user (e.g. via `podman run --user`).
    # Nothing to remap; just activate and run.
    activate_and_exec "$@"
fi

# Running as root: remap the pdi user to the caller's UID/GID.
HOST_UID="${HOST_UID:-1001}"
HOST_GID="${HOST_GID:-1001}"

current_uid="$(id -u  "${SERVICE_USER}")"
current_gid="$(id -g  "${SERVICE_USER}")"

if [ "${current_uid}" != "${HOST_UID}" ] || [ "${current_gid}" != "${HOST_GID}" ]; then
    # -o lets us reuse a UID/GID that already exists in the image. Useful when
    # HOST_UID/HOST_GID happen to collide with an existing system account.
    groupmod -o -g "${HOST_GID}" "${SERVICE_USER}"
    usermod  -o -u "${HOST_UID}" -g "${HOST_GID}" "${SERVICE_USER}"

    # Re-chown only directories that are guaranteed to be inside the image
    # layer. We deliberately do NOT chown /opt/tutorial: if the user bind-mounts
    # a host directory there, chown'ing it would alter ownership on the host
    # filesystem. Files created at build time under /opt/tutorial are read-only
    # for tutorial purposes, so leaving their UIDs stale is fine.
    chown -R "${SERVICE_USER}:${SERVICE_USER}" "${SERVICE_HOME}" "/var/log/${SERVICE_USER}"
fi

# `setpriv` is part of util-linux and is present in the gcc:15 base image.
# --init-groups picks up the supplementary groups of the target user.
# We export HOME explicitly because setpriv does not change it by default and
# we don't want the dropped shell inheriting root's $HOME=/root.
export HOME="${SERVICE_HOME}"

# The activate-and-exec sequence must run inside the unprivileged shell so that
# the PATH / LD_LIBRARY_PATH etc. set by Spack apply to the final process.
exec setpriv --reuid="${SERVICE_USER}" --regid="${SERVICE_USER}" --init-groups \
    /bin/sh -c '. /opt/spack-environment/activate.sh \
        && /opt/environment_check_script.sh \
        && exec "$@"' \
    sh "$@"
