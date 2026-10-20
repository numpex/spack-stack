#!/bin/bash

if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "This script must be sourced not executed."
    echo ". $0"
    exit 1
fi

# `module` may be missing in non-interactive shells (e.g. under srun)
if command -v module >/dev/null 2>&1; then module purge; fi

export SPACK_GROUP="${PROJECT}"
export SPACK_JOBS=96
SPACK_VERSION="$(tr -d '[:space:]' < "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/../../../spack-version.txt")"
export SPACK_VERSION
export SPACK_PREFIX=${ALL_CCFRSCRATCH}/adastra-spack-${SPACK_VERSION}

export PYTHONPYCACHEPREFIX="${ALL_CCFRSCRATCH}/pycache"
export SPACK_DISABLE_LOCAL_CONFIG=true

if [ -f "${SPACK_PREFIX}/share/spack/setup-env.sh" ]; then
    . "${SPACK_PREFIX}"/share/spack/setup-env.sh
fi
