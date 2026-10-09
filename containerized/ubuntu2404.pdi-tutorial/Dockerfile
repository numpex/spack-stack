# https://github.com/spack/spack/tree/develop/share/spack/templates/container

# Build stage with Spack pre-installed and ready to be used
FROM docker.io/spack/ubuntu-noble:1.2 AS builder


# Spack's base image relies on the docker-shell wrapper to source setup-env.sh
# before each RUN, which is required for commands like `spack env activate`.
# This is a Docker-format directive, so this image must be built with
# `podman build --format docker ...` (or with Docker).
SHELL ["docker-shell"]

COPY custom_packages /root/custom_packages/

RUN ls ~/custom_packages/spack_repo/tbouvier/patches

RUN spack repo add ~/custom_packages/spack_repo/tbouvier/patches && \
    spack repo list


# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir -p /opt/spack-environment && \
set -o noclobber \
&&  (echo spack: \
&&   echo '  concretizer:' \
&&   echo '    unify: true' \
&&   echo '  # add package specs to the `specs` list' \
&&   echo '  specs:' \
&&   echo '  - group: compiler' \
&&   echo '    specs:' \
&&   echo '    - gcc@15.3' \
&&   echo '  - group: app' \
&&   echo '    needs: [compiler]' \
&&   echo '    specs:' \
&&   echo '    - cmake' \
&&   echo '    - kokkos' \
&&   echo '    - python@3.13 +tkinter' \
&&   echo '    - pdi~fortran' \
&&   echo '    - pdiplugin-decl-hdf5' \
&&   echo '    - pdiplugin-mpi' \
&&   echo '    - pdiplugin-pycall' \
&&   echo '    - pdiplugin-trace' \
&&   echo '    - pdiplugin-user-code' \
&&   echo '    - pdiplugin-set-value' \
&&   echo '    - py-ray' \
&&   echo '    - py-deisa ^py-dask ~dataframe' \
&&   echo '    - py-pandas ~performance' \
&&   echo '    - py-distributed' \
&&   echo '    - py-bokeh' \
&&   echo '    - py-matplotlib' \
&&   echo '    - py-mpi4py' \
&&   echo '    - py-pip' \
&&   echo '    - py-pytest' \
&&   echo '    - git' \
&&   echo '    - gdb' \
&&   echo '    - vim' \
&&   echo '    - nano' \
&&   echo '    - gcc@15.3' \
&&   echo '    - gmake' \
&&   echo '  config:' \
&&   echo '    template_dirs:' \
&&   echo '    - templates' \
&&   echo '    install_tree:' \
&&   echo '      root: /opt/software' \
&&   echo '  repos:' \
&&   echo '    builtin:' \
&&   echo '      branch: releases/v2026.06' \
&&   echo '  mirrors:' \
&&   echo '    numpex-spack-mirror:' \
&&   echo '      url: oci://ghcr.io/thomas-bouvier/numpex-spack-mirror' \
&&   echo '      access_pair:' \
&&   echo '        id_variable: OCI_USERNAME_VARIABLE' \
&&   echo '        secret_variable: OCI_PASSWORD_VARIABLE' \
&&   echo '  view: /opt/views/view') > /opt/spack-environment/spack.yaml

# Install the software, remove unnecessary deps
RUN cd /opt/spack-environment && spack env activate . && spack install --fail-fast && spack gc -y

# Modifications to the environment that are necessary to run
RUN cd /opt/spack-environment && \
    spack env activate --sh -d . > activate.sh



# Clone tutorial
RUN git clone -b tutorial_HPCAsia https://github.com/pdidev/tutorial.git /root/tutorial


# Bare OS image to run the installed executables
FROM docker.io/ubuntu:noble

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software
COPY --from=builder /opt/views /opt/views

RUN { \
      echo '#!/bin/sh' \
      && echo '.' /opt/spack-environment/activate.sh \
      && echo 'exec "$@"'; \
    } > /entrypoint.sh \
&& chmod a+x /entrypoint.sh \
&& ln -s /opt/views/view /opt/view


COPY --from=builder /root/tutorial /opt/tutorial




# The runtime image is bare ubuntu:noble; install glibc's development files so
# that Spack's gcc can link C/C++ programs (it needs crt1.o, crti.o, headers,
# etc. from libc-dev). Also install make so the tutorial's CMake-generated
# Makefiles can be driven; cmake itself comes from the Spack view.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Sanity check script (runs at every container start, after Spack activation).
COPY environment_check_script.sh /opt/environment_check_script.sh

# Custom entrypoint that remaps the `pdi` user to the caller's UID/GID at run
# time (via $HOST_UID / $HOST_GID), so bind-mounted host volumes keep correct
# ownership on both sides. Overwrites the entrypoint produced by the parent
# template (which only sourced the Spack activation script).
COPY entrypoint.sh /entrypoint.sh

# pdi user/group created with placeholder UID/GID 1001. The entrypoint remaps
# them to $HOST_UID / $HOST_GID at run time.
ENV SERVICE_NAME="pdi"

RUN chmod +x /opt/environment_check_script.sh /entrypoint.sh \
    && groupadd --gid 1001 $SERVICE_NAME \
    && useradd -u 1001 -g $SERVICE_NAME --shell /bin/bash --no-create-home --home-dir /opt/$SERVICE_NAME $SERVICE_NAME \
    && mkdir -p /opt/$SERVICE_NAME /var/log/$SERVICE_NAME \
    && chown -R $SERVICE_NAME:$SERVICE_NAME /opt/$SERVICE_NAME /var/log/$SERVICE_NAME /opt/environment_check_script.sh /opt/tutorial

# Intentionally NO `USER` directive: the entrypoint must start as root so it
# can call usermod/groupmod, then drops privileges to $SERVICE_NAME via setpriv
# before exec'ing the CMD.

WORKDIR /opt/tutorial

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/bin/bash" ]

