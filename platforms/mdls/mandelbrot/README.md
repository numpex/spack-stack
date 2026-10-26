# Mandelbrot

Huge RAM space on this machine.

```console
spack config --scope defaults:base add config:build_stage:/rtx/USER/spack-stage
```

You may set `install_tree` to your user's scratch:

```bash
spack config --scope defaults:base add config:install_tree:root:/mdlsstorage/data/scratch/USER/spack-opt
```

## rtx6000 AI stacks

The `ai-inference` and `ai-stack` projects are configured for the RTX 6000
GPUs through `rtx6000/spack/`:

- the system `gcc@11.5.0` (`/usr`) is used as the compiler — nothing is built
  from source except the software stack itself;
- CUDA is built by Spack from the 12 series (`cuda: require '@12'` picks the
  latest 12.x, matching the old hand-written environments): check with
  `nvidia-smi` that the driver supports it, and tighten the requirement if the
  driver is older;
- the builtin package repository is the
  [thomas-bouvier/spack-packages](https://github.com/thomas-bouvier/spack-packages)
  fork (branch `feat/add-py-vllm`), which provides `py-vllm` and its
  dependencies.

The first `--step install` of these projects on this machine is the real test
of the toolchain: nothing has been built through this path yet.

Note: because this builtin repository differs from upstream `spack-packages`,
mixing this setup with others under the same `$HOME` can confuse Spack's
package caches. Run `spack clean -m` when switching between the two.
