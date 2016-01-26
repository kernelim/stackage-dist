#!/bin/bash

set -u

RESOLVER=lts-5.0

t=${BASH_SOURCE[0]}
t=$(dirname ${t})
t=$(realpath ${t})

syntax() {
    echo "build-srpm -o [output directory] -n"
}

outdir=""
nocleanup=0
while getopts "o:n" o; do
    case "${o}" in
        o)
            outdir=${OPTARG}
            ;;
	n)
	    nocleanup=1
	    ;;
        *)
            syntax
            exit 1
            ;;
    esac
done

if [ -z "$outdir" ] ; then
    echo error: no output directory specified
    echo
    syntax
    exit 1
fi

export STACK_ROOT=${t}/stackroot

if [[ "$nocleanup" == "0" ]]; then
    rm -rf ${STACK_ROOT}
    mkdir -p ${STACK_ROOT}
fi

cat << EOF > ${STACK_ROOT}/config.yaml
download-cache-paths:
- ${STACK_ROOT}/download-cache
EOF

mkdir -p ${STACK_ROOT}/download-cache

rm -rf All
mkdir All
cd All

cat << EOF > stack.yaml
resolver:            ${RESOLVER}
EOF

cat << EOF > All.cabal
name:                All
version:             0.1
synopsis:            All
description:         Please see README.md
homepage:            All
license:             PublicDomain
author:              Automatic
maintainer:          x@x.com
copyright:           2016 Automatic
category:            Console
build-type:          Basic
cabal-version:       >= 1.10

executable all
  hs-source-dirs:      .
  main-is:             Main.hs
  default-language:    Haskell2010
  build-depends:       base
EOF

cat << EOF > Main.hs
main = print "Hello"
EOF

cat << EOF > Setup.hs
import           Distribution.Simple

main :: IO ()
main = defaultMain
EOF

stack setup
stack list-build-plan | awk -F" " '{print "             , " $1}' >> All.cabal || exit -1
stack build --dry-run --prefetch
cd -

make_srpm() {
    cleanups () {
	rm -rf ${RPM_TARGET_DIR}
    }

    RPM_TARGET_DIR=`mktemp --tmpdir -d XXXXXXrpm-packaging`
    mkdir -p ${RPM_TARGET_DIR}/{SPECS,SOURCES}

    PKG_NAME=stackage-${RESOLVER}-src
    SPEC_FILE=${RPM_TARGET_DIR}/SPECS/${PKG_NAME}.spec
    PKG_VERSION=1
    PKG_RELEASE=1

    cat `which stack` | gzip -c > ${RPM_TARGET_DIR}/SOURCES/stack-bin.gz
    cd ${STACK_ROOT}
    tar -czf ${RPM_TARGET_DIR}/SOURCES/stack-root-download-cache.tar.gz download-cache
    tar --exclude indices/Hackage/packages \
	--exclude indices/Hackage/git-update \
	-czf ${RPM_TARGET_DIR}/SOURCES/stack-root-indices.tar.gz indices

    cat ${t}/stackage-src.spec \
	| sed s/@@PKG_VERSION@@/${PKG_VERSION}/g \
	| sed s/@@PKG_NAME@@/${PKG_NAME}/g \
	| sed s/@@PKG_RELEASE@@/${PKG_RELEASE}/g > ${SPEC_FILE}

    (rpmbuild -bs \
	     --define "_topdir ${RPM_TARGET_DIR}" \
	     ${SPEC_FILE} \
	    || (cleanups ; exit 1)) || return -1

    mkdir -p ${outdir}
    cp -v ${RPM_TARGET_DIR}/SRPMS/* ${outdir}
    cleanups
    return 0
}

make_srpm
X=$?

echo Done

exit $?
