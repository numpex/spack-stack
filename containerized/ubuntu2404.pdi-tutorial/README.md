# `containerized/ubuntu2404.pdi-tutorial`

This recipe allows to build a container including all dependencies needed by the following tutorial: https://github.com/pdidev/tutorial/blob/tutorial_HPCAsia/README.md.

The resulting container can be downloaded using one of the following commands:

```bash
# Podman
podman pull ghcr.io/thomas-bouvier/numpex-pdi-tutorial:latest
```

You can also target the version that was used at HPCAsia 2026 specifically using tag `HPCAsia2026`.

## Build this container yourself

Spack provides the `spack containerize > Dockerfile` command, allowing to transform a `spack.yaml` file given as input into a Dockerfile.

Use one of the following commands to generate a container recipe:

```console
# Docker
spack containerize > Dockerfile

# Apptainer
spack containerize > Apptainer.def
```

This will generate a Docker or Singularity recipe depending on the value set in the yaml config:

```yaml
container:
  # docker | singularity
  format: singularity
```

Finally, use one of these commands to generate a container:

```bash
# Podman
podman build -t ghcr.io/thomas-bouvier/numpex-pdi-tutorial:latest --format docker .

# Apptainer
apptainer build Apptainer.sif Apptainer.def
```
