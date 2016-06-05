#!/bin/bash

set -u

t=${BASH_SOURCE[0]}
t=$(dirname ${t})
t=$(realpath ${t})

syntax() {
    echo "build-srpm -t [type] -o [output directory] -n"
}

outdir=""
nocleanup=0
pkgtype=
maintainer=
distros=

while getopts "o:r:nt:m:d:" o; do
    case "${o}" in
        o)
            outdir=${OPTARG}
            ;;
        r)
            resolver=${OPTARG}
            ;;
        t)
            pkgtype=${OPTARG}
            ;;
        m)
            maintainer=${OPTARG}
            ;;
	n)
	    nocleanup=1
	    ;;
	d)
	    distros=${OPTARG}
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

case $pkgtype in
    rpm)
    ;;
    deb)
	if [[ "$maintainer" == "" ]] ; then
	    echo "Maintainer needs to be given for type 'deb'"
	    exit -1
	fi
	if [[ "$distros" == "" ]] ; then
	    echo error: no output directory specified
	    echo
	    syntax
	    exit 1
	fi
    ;;
    *)
	echo "Need to specify proper package type"
	exit -1
esac

make_srpm() {
    cleanups () {
	rm -rf ${RPM_TARGET_DIR}
    }

    RPM_TARGET_DIR=`mktemp --tmpdir -d XXXXXXrpm-packaging`
    mkdir -p ${RPM_TARGET_DIR}/{SPECS,SOURCES}

    PKG_BASE_NAME=stackage-dist-${RESOLVER}
    PKG_NAME=${PKG_BASE_NAME}-precompiled-boot${BATCH_NR}
    SPEC_FILE=${RPM_TARGET_DIR}/SPECS/${PKG_NAME}.spec
    PKG_VERSION=1
    PKG_RELEASE=1
    echo > ${RPM_TARGET_DIR}/SOURCES/nothing.txt

    cat ${t}/stackage-dist-precompiled.rpm.spec \
	| sed s/@@RESOLVER@@/${RESOLVER}/g \
	| sed s/@@BATCH_NR@@/${BATCH_NR}/g \
	| sed s/@@PKG_VERSION@@/${PKG_VERSION}/g \
	| sed s/@@PKG_BASE_NAME@@/${PKG_BASE_NAME}/g \
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

make_sdeb() {
    echo "Not yet supported"
    exit -1
}

make_s$pkgtype
X=$?

echo Done

exit $?
