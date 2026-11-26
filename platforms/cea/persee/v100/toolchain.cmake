# Toolchain to build applications against the Persee (v100) stack.
# Ported from toolchains/persee/v100/toolchain.cmake of the gysela-mini-app_io
# repository; the application keeps defining its own testing options.

# CMake options
set(CMAKE_BUILD_TYPE Release)

# Compiler options
# `nvcc_wrapper` (from Kokkos +wrapper) is on PATH once the environment is activated.
set(CMAKE_CXX_COMPILER nvcc_wrapper)
set(CMAKE_CXX_EXTENSIONS OFF) # Avoid a Kokkos warning that will force it to OFF anyway when compiling with nvcc
# The compile option ipa-sra triggers a segfault with nvcc. @tpadioleau reported it to NVIDIA. We then disable it.
# Using CUDA 12.9 triggers a spurious warning when compiling for NVIDIA Volta architectures. We then disable it.
set(CMAKE_CXX_FLAGS_INIT "-fno-ipa-sra -Wno-deprecated-gpu-targets")
set(CMAKE_CXX_FLAGS_INIT "${CMAKE_CXX_FLAGS_INIT} -Wall -Wno-sign-compare --Werror cross-execution-space-call -Xcudafe --diag_suppress=unsigned_compare_with_zero -Xcudafe --diag_suppress=integer_sign_change")
