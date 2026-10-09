#!/bin/bash

## Use this script after sourcing PDI

## To build PDI, from pdi root directory :
# mkdir build && cd build
# cmake \
# 	-DCMAKE_INSTALL_PREFIX=$PWD/../../install_pdi \
# 	-DBUILD_BENCHMARKING=OFF \
# 	-DBUILD_DECL_HDF5_PLUGIN=ON \
# 	-DBUILD_DECL_NETCDF_PLUGIN=OFF \
# 	-DBUILD_FORTRAN=OFF \
# 	-DBUILD_HDF5_PARALLEL=ON \
# 	-DBUILD_MPI_PLUGIN=ON \
# 	-DBUILD_NETCDF_PARALLEL=OFF \
# 	-DBUILD_PYCALL_PLUGIN=ON \
# 	-DBUILD_PYTHON=ON \
# 	-DBUILD_SERIALIZE_PLUGIN=ON \
# 	-DBUILD_SET_VALUE_PLUGIN=ON \
# 	-DBUILD_TESTING=OFF \
# 	-DBUILD_TRACE_PLUGIN=ON \
# 	-DBUILD_USER_CODE_PLUGIN=ON \
# 	-DBUILD_SHARED_LIBS=ON \
# 	-DUSE_HDF5=EMBEDDED \
# 	-DUSE_paraconf=EMBEDDED \
# 	-DUSE_yaml=EMBEDDED \
# 	..
# make -j8
# make install
## Then to source PDI :
# source $PWD/../../install_pdi/share/pdi/env.sh


echo "           _ _   _         _             _       _ "
echo " _ __   __| (_) | |_ _   _| |_ ___  _ __(_) __ _| |"
echo "| '_ \ / _\` | | | __| | | | __/ _ \| '__| |/ _\` | |"
echo "| |_) | (_| | | | |_| |_| | || (_) | |  | | (_| | |"
echo "| .__/ \__,_|_|  \__|\__,_|\__\___/|_|  |_|\__,_|_|"
echo "|_|                                                "
echo ""

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "$1 is installed."
    else
        echo "$1 is NOT installed."
        exit 1
    fi
}

check_command gcc
check_command cmake

check_command mpicc
check_command mpirun

check_command python3

check_command pdirun

pdirun_binary=$(whereis pdirun | awk '{print $2}')
pdirun_directory=$(dirname "$pdirun_binary")
cd "$(dirname "$pdirun_directory")/lib/" > /dev/null
find_output=$(find . -name "libpdi_*")

plugins_to_check=("mpi" "trace" "hdf5" "pycall" "user_code" )

for plugin in "${plugins_to_check[@]}"; do
    if ! grep -q "$plugin" <<< "$find_output"; then
        echo "PDI is missing its '$plugin' plugin."
        exit 1
    fi
done
cd - > /dev/null

echo ""
echo "################"
echo "All required tools are installed, and no plugins are missing to PDI."
echo "THIS ENVIRONMENT IS OK FOR THE PDI TUTORIAL."
echo "################"
echo ""

# for users with mac linking error:
# dyld[76918]: Library not loaded: @rpath/libpdi.1.dylib
# fix: 
# export DYLD_LIBRARY_PATH=$pdirun_directory/../lib

cd /opt/tutorial/00_begin/solution
mkdir build && cd build
cp ../config.yml .
cmake ..

# Only run make if CMake succeeded
if [ -f "Makefile" ]; then
    make
else
    echo "ERROR: Makefile was not generated! CMake likely failed."
    exit 1
fi

# Run the program if it was built
if [ -f "./main" ]; then
    mpirun -np 4 ./main
else
    echo "ERROR: ./main executable was not built!"
    exit 1
fi

cd ..
rm -rf build
cd ../..
