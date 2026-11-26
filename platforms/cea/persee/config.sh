#!/bin/bash

# Guard against direct execution. Only meaningful under bash: zsh sets $0 to
# the sourced file, so the test cannot distinguish there.
if [ -n "${BASH_VERSION:-}" ] && [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "This script must be sourced not executed."
    echo ". $0"
    exit 1
fi
self="$(readlink -f -- "${BASH_SOURCE[0]:-$0}")"

# Persee: the GyselaX team's cluster at CEA. Local cluster, no allocation
# variables (unlike the CINES/IDRIS sites)

# TODO(persee-operators): group owning the shared Spack installation (cf. the
# `all:permissions` block in the arch `spack/packages.yaml`). The previous
# deployment shared a single account (`gyselarunner`).
export SPACK_GROUP="TODO-persee-group"
export SPACK_JOBS=16
SPACK_VERSION="$(tr -d '[:space:]' < "$(dirname -- "${self}")/../../../spack-version.txt")"
export SPACK_VERSION
# TODO(persee-operators): storage location for Spack and its installations
# (the previous deployment lived under /data/gyselarunner).
export SPACK_PREFIX="/data/${USER}/persee-spack-${SPACK_VERSION}"

export PYTHONPYCACHEPREFIX="/tmp/${USER}/pycache"
export SPACK_DISABLE_LOCAL_CONFIG=true

if [ -f "${SPACK_PREFIX}/share/spack/setup-env.sh" ]; then
    . "${SPACK_PREFIX}"/share/spack/setup-env.sh
fi
