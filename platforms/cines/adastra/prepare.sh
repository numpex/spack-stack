#!/bin/bash

# Ensures the script is not being sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "This script must be executed, not sourced!" >&2
    return 1
fi

set -eu

module purge

TOOLCHAIN_ROOT_DIRECTORY="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]:-${0}}")")"

ADASTRA_SPACK_GROUP="adastra-spack"
ADASTRA_SPACK_JOBS=96
ADASTRA_SPACK_VERSION="1.2.2"
ADASTRA_SPACK_PREFIX=${ALL_CCFRSCRATCH}/adastra-spack-${ADASTRA_SPACK_VERSION}
export SPACK_DISABLE_LOCAL_CONFIG=true
export PYTHONDONTWRITEBYTECODE=True

if [ ! -d "${ADASTRA_SPACK_PREFIX}" ]; then
    mkdir --parents "${ADASTRA_SPACK_PREFIX}"
    chmod g+s "${ADASTRA_SPACK_PREFIX}"
    git clone --branch v${ADASTRA_SPACK_VERSION} --depth 1 https://github.com/spack/spack.git "${ADASTRA_SPACK_PREFIX}"
fi

. ${ADASTRA_SPACK_PREFIX}/share/spack/setup-env.sh

for arch in genoa mi250 mi300; do
    for env in gysela; do
        env_file="${TOOLCHAIN_ROOT_DIRECTORY}/${arch}.${env}/spack.yaml"

        echo "Preparing the Spack environment ${arch}.${env}"

        spack env remove --yes-to-all "${arch}.${env}"
        spack env create "${arch}.${env}" "${env_file}"

        spack env activate "${arch}.${env}"
        spack repo update
        spack concretize --quiet
        spack spec --install-status --namespaces
        spack install --jobs "${ADASTRA_SPACK_JOBS}"
        spack env deactivate
    done
done

find "${ADASTRA_SPACK_PREFIX}" \( -type d -type f \) -user "${USER}" \
    -exec chgrp "${ADASTRA_SPACK_GROUP}" {} + \
    -exec chmod g+rwX {} +
