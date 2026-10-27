# millefeuille

[![CI](https://github.com/numpex/spack-stack/actions/workflows/ci.yaml/badge.svg)](https://github.com/numpex/spack-stack/actions/workflows/ci.yaml)

Lean and opinionated deployment helpers for Spack. This repository contains:

- **ready-to-use Spack environments** for each software stack [NumPEx](https://numpex.org) in `projects/`;
- **a unified installer**, [`install.sh`](install.sh), which builds a stack on a supported
  HPC platform, combining the stack definition with site-specific configuration
  (externals, compilers, package repositories);
- **an OCI binary cache** on `ghcr.io/numpex/spack-stack`, continuously filled by CI, so
  that matching packages are downloaded instead of rebuilt from source.

![Overview](image.png)

This repository serves two kinds of users — most of this README is about the
second:

- **anywhere** (a container, another machine): [reuse the binaries built by
  CI](#reuse-the-ci-built-binaries);
- **on one of the supported HPC platforms**: [install a stack with
  `install.sh`](#install-a-stack-on-an-hpc-platform).

## Installation instructions

### Reuse the CI-built binaries

CI builds every `projects/` stack **generically**, and only that: on
GitHub-hosted ubuntu-24.04 runners, with the system compiler of the runner
image and `x86_64`/`x86_64_v3` targets, using the runner "site" configuration
in `.github/spack/` — no site-specific settings are involved. The resulting
packages are pushed to the public OCI binary cache on
`ghcr.io/numpex/spack-stack`, so they can benefit all users rather than a
single site: packages with a matching ABI (e.g. containers based on
ubuntu 24.04) are downloaded instead of rebuilt from source.

To point a Spack environment at the cache, add it as a mirror:

```yaml
mirrors:
  spack-stack:
    url: oci://ghcr.io/numpex/spack-stack
    binary: true
    source: false
    signed: false
```

For container images on top of these stacks, see [containerized/](containerized/).


### Install a stack on an HPC platform

`install.sh` combines the following inputs into a Spack environment named
`<project>-<arch>--<version>` (version from [`version.txt`](version.txt)):

| Input | Option | Files | Content |
|-------|--------|-------|---------|
| Stack | — | `common/*.yaml` | package repositories shared by all machines |
| Platform | `--platform` | `platforms/<site>/config.sh` | Spack location, parallel jobs, Slurm settings |
| Architecture | `--arch` | `platforms/<site>/<arch>/spack/*.yaml` | externals, package preferences, machine-specific repositories |
| Project | `--project` | `projects/<project>/spack.yaml` | the software stack to install |
| Project (optional) | — | `projects/<project>/spack/*.yaml` | project-specific repositories (e.g. `ai-inference` uses a `spack-packages` fork for `py-vllm`) |

Configuration is merged from the most specific layer to the most general one:
project, then machine, then stack. For instance, Adastra adds its
`patches_adastra` sub-repository to the package repositories defined in
`common/repos.yaml` (the `gyselax` fork of Spack, with the GYSELA recipes, and
the `builtin` repository pinned to the Spack release).

Example on CINES Adastra:

```console
$ ./install.sh --platform cines/adastra --arch mi300 --project <project>
```

On sites where compute nodes have no internet access (e.g. Jean-Zay), enable Slurm mode
with `--slurm-account <account>` (or the `SLURM_ACCOUNT` variable): sources are mirrored
from the login node, and `concretize`/`install` run on GPU compute nodes through `srun`.

Concurrent installations of the same environment are prevented by a lock file, and on
completion the installation tree is shared with the site group.

### Supported platforms

| Site | Machine | Architectures |
|------|---------|--------------|
| CINES | Adastra | `genoa` (CPU), `mi250`, `mi300` (AMD GPU) |
| IDRIS | Jean-Zay | `h100` (NVIDIA GPU, Slurm mode) |
| MDLS | Mandelbrot | `rtx6000` (NVIDIA GPU) |

The Adastra and Jean-Zay architectures also ship a `toolchain.cmake` with the recommended
compiler settings, reusable downstream with `cmake -C <toolchain.cmake>`.


## Planned features

- **Container images built by CI**: turn the generic CI builds into versioned
  container images published next to the binary cache, so container users get a
  runnable artifact instead of a mirror configuration. Two flavors are
  envisioned: a *lite* image with Spack and a minimal stack (read-only, usable
  as an `upstreams:` for local writable installations), and *release* images
  with the full stacks pre-installed.
- **Spack upstream interface for site installs**: generate the Spack
  configuration that exposes an installed stack (`upstreams.yaml`,
  `compilers.yaml`, `repos.yaml`, `packages.yaml`) next to the installation
  tree, so that developers build their own applications against the stack
  with their own Spack instance, without rebuilding its dependencies.
- **uenv integration**: distribute the stacks as
  [uenv](https://github.com/eth-cscs/uenv) images, mounted read-only as user
  environments on the machines that support it, for users who do not use
  Spack at all.
- **Per-target environments**: split the environment definitions along the
  accelerator axis (`cpu`, `cuda`, `rocm`) instead of relying only on
  site-level requirements such as `cuda_arch=120`, for the stacks that need
  genuinely different spec sets per target.

## Similar projects

[Spack-Manager](https://github.com/sandialabs/spack-manager) - a project and machine deployment model using Spack

[spack-configs](https://github.com/spack/spack-configs) - share Spack configuration files with other HPC sites

[E4S](https://github.com/E4S-Project/e4s) - the HPC-AI Software Ecosystem for Science

[Stackinator](https://github.com/eth-cscs/stackinator) - a tool for building a scientific software stack
