#! /bin/bash

# Copyright 2017-present Cisco Systems, Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# max_parallel_jobs calculates a number of parallel jobs N to run for
# a command like `make -j<N>`

# Often this does not actually help finish the command earlier if N is
# larger than the number of CPU cores on the system, so calculate a
# value of N no more than that number.

# Also, if N is so large that the processes started in parallel exceed
# the available memory on the system, it can cause the system to copy
# memory to and from swap space, which dramatically reduces
# performance.  Alternately, it can cause the kernel to kill
# processes, to reduce system memory usage, which causes the overall
# job to fail.  Thus we would like to calculate a value of N that is
# no more than:

# (currently free mem / expected mem used per parallel job)

# The caller must provide a value for "expected mem used per parallel
# job", because this code has no way to estimate that.

max_parallel_jobs() {
    local expected_mem_per_job_MBytes=$1
    local memtotal_KBytes=`head -n 1 /proc/meminfo | awk '{print $2;}'`
    local memtotal_MBytes=`expr ${memtotal_KBytes} / 1024`
    local max_jobs_for_mem=`expr ${memtotal_MBytes} / ${expected_mem_per_job_MBytes}`
    local max_jobs_for_processors=`grep -c '^processor' /proc/cpuinfo`
    1>&2 echo "Available memory (MBytes): ${memtotal_MBytes}"
    1>&2 echo "Expected memory used per job (MBytes): ${expected_mem_per_job_MBytes}"
    1>&2 echo "Max number of parallel jobs for available mem: ${max_jobs_for_mem}"
    1>&2 echo "Max number of parallel jobs for processors: ${max_jobs_for_processors}"
    if [ ${max_jobs_for_processors} -lt ${max_jobs_for_mem} ]
    then
	echo ${max_jobs_for_processors}
    elif [ ${max_jobs_for_mem} -ge 1 ]
    then
	echo ${max_jobs_for_mem}
    else
	echo 1
    fi
}

if [ -d .git -a -d midend ]
then
    echo "Found directories .git and midend"
else
    1>&2 echo "At least one of .git and midend directories is not present."
    1>&2 echo ""
    1>&2 echo "This command must be run from inside top level directory of"
    1>&2 echo "a clone of the Github repository https://github.com/p4lang/p4c"
    exit 1
fi

usage() {
    1>&2 echo "usage: $0 [ deletebuild | update | release | debug | bmv2 | full ]*"
    1>&2 echo ""
    1>&2 echo "    deletebuild - first delete build directory, if it exists"
    1>&2 echo "    release, debug - last one one cmd line controls whether RELEASE or DEBUG build are done for p4c"
    1>&2 echo "    bmv2, full - last one one cmd line controls whether only bmv2 and p4test back ends are built, or all back ends"
}

DO_DELETE_BUILD_DIR=0
DO_UPDATE_FIRST=0
BUILD_TYPE="Release"
BUILD_TARGETS="bmv2"
while [ $# -ge 1 ]
do
    case "$1" in
	deletebuild)
	    DO_DELETE_BUILD_DIR=1
	    ;;
	update)
	    DO_UPDATE_FIRST=1
	    ;;
	release)
	    BUILD_TYPE="Release"
	    ;;
	debug)
	    BUILD_TYPE="Debug"
	    ;;
	full)
	    BUILD_TARGETS="full"
	    ;;
	bmv2)
	    BUILD_TARGETS="bmv2"
	    ;;
	*)
	    1>&2 echo "Unknown command line option: $1"
	    1>&2 echo ""
	    usage
	    exit 1
	    ;;
    esac
    shift
done

echo "DO_UPDATE_FIRST=${DO_UPDATE_FIRST}"
echo "BUILD_TYPE=${BUILD_TYPE}"
echo "BUILD_TARGETS=${BUILD_TARGETS}"
#exit 0

if [ ${DO_UPDATE_FIRST} -eq 1 ]
then
    echo "Will update files before clean and build."
else
    echo "Will clean and build without updating any files."
fi

set -x

if [ ${DO_UPDATE_FIRST} -eq 1 ]
then
    # Get updates from master repo
    git pull

    # Recommended in p4c's README.md
    git submodule update --init --recursive
fi

if [ ${DO_DELETE_BUILD_DIR} -eq 1 -a -d build]
then
    echo "Deleting build directory"
    /bin/rm -fr build
fi

if [ -d build ]
then
    echo "Building in already-existing build directory"
else
    mkdir -p build
    echo "Building p4c from scratch"
fi

cd build
P4C_CMAKE_OPTS=""
PROCESSOR=`uname --machine`
case "${BUILD_TARGETS}" in
    full)
	P4C_CMAKE_OPTS="${P4C_CMAKE_OPTS} -DENABLE_BMV2=ON -DENABLE_P4TEST=ON -DENABLE_EBPF=ON -DENABLE_UBPF=ON -DENABLE_DPDK=ON -DENABLE_P4C_GRAPHS=ON -DENABLE_TEST_TOOLS=ON -DENABLE_DOCS=ON -DENABLE_P4FMT=ON -DENABLE_P4TC=ON -DENABLE_GTESTS=ON"
	;;
    bmv2)
	P4C_CMAKE_OPTS="${P4C_CMAKE_OPTS} -DENABLE_BMV2=ON -DENABLE_P4TEST=ON -DENABLE_EBPF=OFF -DENABLE_UBPF=OFF -DENABLE_DPDK=OFF -DENABLE_P4C_GRAPHS=OFF -DENABLE_TEST_TOOLS=OFF -DENABLE_DOCS=OFF -DENABLE_P4FMT=OFF -DENABLE_P4TC=OFF -DENABLE_GTESTS=OFF"
	;;
esac
cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} ${P4C_CMAKE_OPTS}
# Copied from p4c/Dockerfile
#cmake .. '-DCMAKE_CXX_FLAGS:STRING=-O3'

# Make all back ends, including:
# gtestp4c
# p4c-bm2-psa
# p4c-bm2-ss
# p4c-dpdk
# p4c-ebpf
# p4c-graphs
# p4c-ubpf
# p4test
MAX_PARALLEL_JOBS=`max_parallel_jobs 2048`
make -j${MAX_PARALLEL_JOBS}

# Make only the explicitly listed back ends:
#make -j${MAX_PARALLEL_JOBS} p4c-dpdk p4test p4c-bm2-ss

set +x
echo ""
echo "If you want to run p4c automated tests, run these commands:"
echo ""
echo "    cd build"
echo "    make check"
echo ""
echo "If you want to install these versions of p4c in system-wide"
echo "directories, e.g. /usr/local/bin, run the commands:"
echo ""
echo "    cd build"
echo "    sudo make install  # to install larger binaries with debug symbols included"
echo "    sudo make install/strip  # to install smaller binaries without debug symbols"
