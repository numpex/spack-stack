# spack-stack

Spack binary cache for NumPEx applications.

To benefit from the buildcache, simply add the following to your `spack.yaml` environment:

```yaml
spack:
  mirrors:
    spack-stack:
      url: oci://ghcr.io/numpex/spack-stack
```
