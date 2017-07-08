#!/bin/bash

set -e -u -x

export GOPATH=$PWD/garden-runc-release
export PATH=$PATH:$GOPATH/bin

pushd garden-runc-release
  (
    set -e -u -x
    git submodule update --init --recursive

    export GOPATH=$PWD

    go install code.cloudfoundry.org/guardian/cmd/dadoo
    go install code.cloudfoundry.org/guardian/cmd/init

    pushd src/github.com/opencontainers/runc
      make static BUILDTAGS="seccomp"
      cp runc /usr/bin
    popd

    pushd src/code.cloudfoundry.org/guardian/rundmc/nstar
      make
      mv nstar /usr/bin
    popd

    cp bin/{init,dadoo} /usr/bin
  )
popd

# must be built with 'daemon' flag because of docker packages :|
go build \
  -tags daemon \
  -o /usr/bin/gdn \
  code.cloudfoundry.org/guardian/cmd/gdn

git clone https://github.com/cloudfoundry/grootfs.git $GOPATH/src/code.cloudfoundry.org/grootfs
cd $GOPATH/src/code.cloudfoundry.org/grootfs
git submodule update --init --recursive
make

cp ./{grootfs,drax,tardis} /usr/bin
