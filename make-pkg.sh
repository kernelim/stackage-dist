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

make_srpm() {
    cleanups () {
	rm -rf ${RPM_TARGET_DIR}
    }

    RPM_TARGET_DIR=`mktemp --tmpdir -d XXXXXXrpm-packaging`
    mkdir -p ${RPM_TARGET_DIR}/{SPECS,SOURCES}

    PKG_NAME=All
    SPEC_FILE=${RPM_TARGET_DIR}/SPECS/${PKG_NAME}.spec
    PKG_VERSION=1
    PKG_RELEASE=1

    cd ${t}
    tar --exclude All/.stack-work \
	-czf ${RPM_TARGET_DIR}/SOURCES/all-pkg.tar.gz All

    cat ${t}/package.spec \
	| sed s/@@PKG_VERSION@@/${PKG_VERSION}/g \
	| sed s/@@PKG_NAME@@/${PKG_NAME}/g \
	| sed s/@@RESOLVER@@/${RESOLVER}/g \
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

echo Done
