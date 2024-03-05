#!/bin/sh

cd $HOME
git clone https://github.com/darchr/simple-vectorizable-benchmarks
cd simple-vectorizable-benchmarks
git checkout arm+kvm
git pull
cd permutating_scatter
make -f makefiles/Makefile-hw clean
make -f makefiles/Makefile-hw M5_BUILD_PATH=$HOME/gem5/util/m5/build/arm64/ M5OPS_HEADER_PATH=$HOME/gem5/include/

