# Containerized Spack environments

This README is a rough guide on how to build containerized Spack environments.

## Saving up space

Dockerfiles [produced by `spack containerize`](https://spack.readthedocs.io/en/latest/containers.html#generating-recipes-for-docker-and-singularity) leverage multi-stage builds. With multi-stage builds, you use multiple FROM statements in your Dockerfile. Each FROM instruction can use a different base, and each of them begins a new stage of the build. You can selectively copy artifacts from one stage to another, leaving behind everything you don't want in the final image. This is a great way to reduce the size of final containers. In this project, I use the following image for the the build process:

```bash
# Build stage with Spack v1.2 pre-installed and ready to be used
FROM docker.io/spack/ubuntu-noble:1.2 AS builder
```

The base and final images can be selected from the `spack.yaml` file as follows:

```yaml
container:
  # docker | singularity
  format: docker
  images:
    build: docker.io/spack/ubuntu-noble:1.2
    final: docker.io/ubuntu:noble
```

Of course you can modify the generated Dockerfile manually. In fact, I created a user manually in the final image as follows:

```dockerfile
ENV SERVICE_NAME="pdi"

RUN groupadd --gid 1001 $SERVICE_NAME \
    && useradd -u 1001 -g $SERVICE_NAME --shell /bin/false --no-create-home --home-dir /opt/$SERVICE_NAME $SERVICE_NAME \
    && mkdir -p /opt/$SERVICE_NAME /var/log/$SERVICE_NAME \
    && chown -R $SERVICE_NAME:$SERVICE_NAME /opt/$SERVICE_NAME /var/log/$SERVICE_NAME /entrypoint.sh /opt/environment_check_script.sh /opt/tutorial
```

To save space, gather all instructions in a single RUN command.

[dive](https://github.com/wagoodman/dive) is useful to explore each layer in an image, helping identify ways to shrink its size:

```bash
# Podman
dive ghcr.io/thomas-bouvier/numpex-pdi-tutorial:latest --source podman
```

## Using a binary cache to speed up image builds

Docker images are built with layers stacked on top of each other. Each layer represents a specific modification to the filesystem. The `spack install` command, although installing the entire Spack environment declared in `spack.yaml`, corresponds to a single Docker instruction <-> layer. As a result, failing to install a single package invalidates the entire Spack environment installation, and all packages will need to be recompiled.

Binary caches can be useful to tackle this issue, as packages already compiled will be downloaded from the given mirror instead of getting compiled again. You should not need to set environment variables `OCI_USERNAME_VARIABLE` and `OCI_PASSWORD_VARIABLE` which are usually only needed to push new binaries to the buildcache:

```yaml
mirrors:
  numpex-spack-mirror:
    url: oci://ghcr.io/thomas-bouvier/numpex-spack-mirror
    access_pair:
      id_variable: OCI_USERNAME_VARIABLE
      secret_variable: OCI_PASSWORD_VARIABLE
```

Please note that the buildcache mechanism will not be present in the final image. This is solely used to speed up the image build process.

My advice is to build all packages in an interactive Podman session using the same environment that will be embedded in the Dockerfile, so that you can leverage the binarycache more effectively and patch broken recipes if needed. Once packages are built, they can be pushed to the buildcache using `spack buildcache push` to be reused by the Dockerfile.

```bash
podman run \
    -v /path/to/my-spack-envs:/root/my-spack-envs \
    -it docker.io/spack/ubuntu-noble:1.2
```

Once inside the interactive container session run:

```bash
spack env activate my-spack-envs/generic/pdi-tutorial/cpu.ubuntu2404.spack
spack install
```

Once the compilation is successful, push all binaries to your buildcache:

```bash
OCI_USERNAME_VARIABLE=aaa OCI_PASSWORD_VARIABLE=zzz spack buildcache push --update-index --tag latest numpex-spack-mirror
```

You can finally launch the real build in a non-interactive way (binaries will be retrieved from the buildcache). Build with the Dockerfile as input:

```bash
spack containerize > Dockerfile
podman build -t ghcr.io/thomas-bouvier/numpex-pdi-tutorial:latest --format docker .
```

## Patching Spack packages

When preparing images under a deadline, you will sometimes need to include Spack packages that have not been upstreamed in `spack-packages` yet. In this case, you should configure a custom Spack package repository in the build stage of your Dockerfile. COPY the missing Spack recipes from the local project to the image to include them in the custom Spack repository:

```dockerfile
COPY ./custom_packages /root/custom_packages
RUN spack repo add ~/custom_packages/spack_repo/tbouvier/patches
```

If building in an interactive container first:

```bash
podman run \
    -v /path/to/my-spack-envs:/root/my-spack-envs \
    -v ./custom_packages:/root/custom_packages \
    -it docker.io/spack/ubuntu-noble:1.2

spack env activate my-spack-envs/generic/pdi-tutorial/cpu.ubuntu2404.spack
spack repo add ~/custom_packages/spack_repo/tbouvier/patches
spack install
```

## Out of memory

If the image build fails because of an Out of Memory error, add flags `--verbose --j1` to your `spack install`:

```dockerfile
spack install --fail-fast --verbose -j1
```

## Tricks to run the actual container

The final image can be ran as a container as follows:

```bash
podman run -it ghcr.io/thomas-bouvier/numpex-pdi-tutorial:HPCAsia2026
```

User `pdi` that we configured earlier is available inside the container. To edit some code on your host machine using VSCodium for instance, you should use a volume as follows:

```console
podman run -v /path/to/tour/local/sources:/opt/pdi -it ghcr.io/thomas-bouvier/numpex-pdi-tutorial:HPCAsia2026
```

If this command doesn't work as it is, contact your sysadmin; they probably spend part of their time implementing security measures that annoy people. One way is to check if your user ID is standard with `id -u`. If it is very high, this is probably not the case.
