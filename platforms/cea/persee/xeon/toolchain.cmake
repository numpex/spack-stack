# Toolchain to build applications against the Persee (xeon) stack.
# Ported from toolchains/persee/xeon/toolchain.cmake of the gysela-mini-app_io
# repository; the application keeps defining its own testing options.

# CMake options
set(CMAKE_BUILD_TYPE Release)

# Compiler options
set(CMAKE_CXX_COMPILER g++)
set(CMAKE_C_COMPILER gcc)
set(CMAKE_Fortran_COMPILER gfortran)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_FLAGS_INIT "-Wall -Wno-sign-compare -Wno-unused-but-set-variable")
