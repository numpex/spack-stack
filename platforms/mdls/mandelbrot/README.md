# Mandelbrot

Huge RAM space on this machine.

```console
spack config --scope defaults:base add config:build_stage:/rtx/USER/spack-stage
```

You may set `install_tree` to your user's scratch:

```bash
spack config --scope defaults:base add config:install_tree:root:/mdlsstorage/data/scratch/USER/spack-opt
```
