# Persee

Persee is the GyselaX team's cluster at CEA, with two node types:

- `xeon`: CPU nodes
- `v100`: nodes with NVIDIA V100 GPUs (Volta, compute capability 7.0)

Deploy a stack on the machine:

```console
./install.sh --platform cea/persee --arch xeon --project mini-app-io        # checkpointing mini-app
./install.sh --platform cea/persee --arch v100 --project mini-app-insitu   # Deisa in-situ analytics (GPU)
```

The environment produced by a deploy is named `<project>-<arch>--<version>`
(`version.txt`); activate it with `spack env activate` and build applications
with the `toolchain.cmake` shipped next to the arch directory.

This platform supersedes the hand-maintained environments previously installed
under `/data/gyselarunner/` (`gysela-io-env-deisa`, `gysela-io-env-deisa-cuda`,
built with a frozen Spack 1.1.1), which can be retired once the corresponding
projects are deployed here.

## Runtime notes (carried over from the previous deployment)

- Load the compiler module used by the stack: `module load gcc/13`.
- The hdf5 package injects its environment-view `lib` path into
  `LD_LIBRARY_PATH` at activation, which causes spurious segfaults for system
  executables: snapshot and restore `LD_LIBRARY_PATH` around
  `spack env activate`.
- `spack env activate` can skip loading the runtime environment (PYTHONPATH)
  when it emits warnings: prepend the environment view `site-packages`
  explicitly if the Spack-installed Python packages are not visible.
- Kokkos profiling tools: prepend `$(spack location -i kokkos-tools)/lib64`
  to `LD_LIBRARY_PATH`.
- OpenMP pinning: `OMP_PROC_BIND=spread`, `OMP_PLACES=threads`,
  `OMP_NUM_THREADS=16` on xeon nodes, `8` on v100 nodes.
- On v100 nodes, several MPI ranks share one GPU and each rank embeds a
  Python/JAX runtime (PDI pycall): export
  `XLA_PYTHON_CLIENT_PREALLOCATE=false` so JAX does not preallocate ~75% of
  the device memory per process.

## Status

Draft platform definition: the facts marked `TODO(persee-operators)` in
`config.sh` and under `xeon/`, `v100/` must be filled in by the machine
operators (compiler version and prefix behind `gcc/13`, storage and group
sharing, micro-architecture targets, CUDA setup, CI runner for the binary
cache). The runtime notes above were extracted from the `persee` environment
scripts of the `gysela-mini-app_io` repository.
