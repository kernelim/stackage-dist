#!/bin/bash

STACKAGE_DIST_HELPER_MAJOR_VER=1

stackage-dist-env() {
    STACKAGE_DIST_ROOT=$(dirname $BASH_SOURCE[0])
    RESOLVER=$1
    local stack_root_base=$2

    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US.UTF-8

    ## Either unset LDFLAGS (which seems to be '-Wl,-Bsymbolic-functions -Wl,-z,relro' in
    ## launchpad) or:
    unset LDFLAGS

    # OR:
    #
    # export CFLAGS="-fPIC ${CFLAGS}"
    # export CXXFLAGS="-fPIC ${CXXFLAGS}"
    # export FCFLAGS="-fPIC ${FCFLAGS}"
    # export FFLAGS="-fPIC ${FFLAGS}"
    # export GCJFLAGS="-fPIC ${GCJFLAGS}"
    # export OBJCFLAGS="-fPIC ${OBJCFLAGS}"
    # export OBJCXXFLAGS="-fPIC ${OBJCXXFLAGS}"

    export PATH=${STACKAGE_DIST_ROOT}/bin:$PATH
    export STACK_ROOT=${stack_root_base}/.stack
}

stackage-dist-setup() {
    stackage-dist-env "$@"
    local src_path=$2

    mkdir -p ${STACK_ROOT} || exit -1
    cat << EOF > ${STACK_ROOT}/config.yaml
download-cache-paths:
- ${STACKAGE_DIST_ROOT}/download-cache
- ${STACK_ROOT}/download-cache
EOF

    mkdir -p ${STACK_ROOT}/download-cache  || exit -1
    mkdir -p ${STACK_ROOT}/indices/Hackage  || exit -1
    ln -s ${STACKAGE_DIST_ROOT}/indices/Hackage/* ${STACK_ROOT}/indices/Hackage/  || exit -1

    stack setup --no-terminal --resolver=$RESOLVER  || exit -1

    cd ${src_path}
    if [[ -e stack-work-downloads.tar.gz ]] ; then
	mkdir -p .stack-work  || exit -1
	cd .stack-work  || exit -1
	tar -zxf ../stack-work-downloads.tar.gz  || exit -1
    fi
    cd - > /dev/null
}
