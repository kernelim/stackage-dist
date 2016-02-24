#!/bin/bash

STACKAGE_DIST_HELPER_MAJOR_VER=1

stackage-dist-env-b() {
    STACKAGE_DIST_ROOT=$1
    RESOLVER=$2
    local stack_root_base=$3

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
    export PATH=${STACK_ROOT}/bin:$PATH
}

stackage-generate-package-db() {
    local db_path=$1
    local stack_yaml=$2

    local pkgdb_path=$STACK_ROOT/pkgdb

    if [[ ! -d ${pkgdb_path} ]] ; then
	ghc-pkg init ${pkgdb_path}
	for i in ${db_path}/*.conf ; do
	    b=`basename $i`
	    ghc-pkg --package-db=${pkgdb_path} register $i --force
	    case $b in
                cpphs-*)
		    if [[ -x bin/cpphs ]] ; then
			ln -s `realpath bin/cpphs` ${STACK_ROOT}/bin/cpphs
		    fi
                    ;;
	    esac
	done
    fi

    cat << EOF >> ${stack_yaml}
extra-package-dbs:
- ${pkgdb_path}
EOF
}

stackage-setup-extra-package-dbs() {
    local resolver_snapshots_root=${STACKAGE_DIST_ROOT}/snapshots/x86_64-linux/$RESOLVER
    if [[ -d ${resolver_snapshots_root} ]] ; then
	ghc_ver=`ls -1 ${resolver_snapshots_root}`
	if [[ -d ${resolver_snapshots_root}/${ghc_ver} ]] ; then
	    d=$(realpath $1)
	    cd ${resolver_snapshots_root}/${ghc_ver}
	    if [[ -x pkgdb.precompiled ]] ; then
		stackage-generate-package-db pkgdb.precompiled $d
	    elif [[ -x pkgdb ]] ; then
		stackage-generate-package-db pkgdb $d
	    fi
	    cd - > /dev/null
	fi
    fi
}

stackage-dist-setup-b() {
    stackage-dist-env-b "$@"
    local src_path=$3

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

    mkdir -p ${STACK_ROOT}/bin || exit -1
    mkdir -p ${STACK_ROOT}/global-project || exit -1
    stackage-setup-extra-package-dbs ${STACK_ROOT}/global-project/stack.yaml

    cd ${src_path}
    if [[ -e stack-work-downloads.tar.gz ]] ; then
	mkdir -p .stack-work  || exit -1
	cd .stack-work  || exit -1
	tar -zxf ../stack-work-downloads.tar.gz  || exit -1
    fi
    cd - > /dev/null
}

stackage-dist-setup() {
    stackage-dist-setup-b $(dirname $BASH_SOURCE[0]) $@
}

stackage-dist-env() {
    stackage-dist-env-b $(dirname $BASH_SOURCE[0]) $@
}
