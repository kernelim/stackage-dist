#!/bin/bash

set -u

t=${BASH_SOURCE[0]}
t=$(dirname ${t})
t=$(realpath ${t})

syntax() {
    echo "build-srpm -t [resolver] -t [type] -o [output directory] -n"
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

stack exec -- stack --help | grep relocate > /dev/null
if [[ "$?" != 0 ]] ; then
    echo "Need a newer Stack"
    exit -1
fi

export STACK_ROOT=${t}/stack-root

if [[ "$nocleanup" == "0" ]]; then
    rm -rf ${STACK_ROOT}
    mkdir -p ${STACK_ROOT}
fi

stack --no-system-ghc setup --resolver=${resolver}
stack unpack `stack --resolver=${resolver} list-build-plan` --fetch-only

make_srpm() {
    cleanups () {
	rm -rf ${RPM_TARGET_DIR}
    }

    RPM_TARGET_DIR=`mktemp --tmpdir -d XXXXXXrpm-packaging`
    mkdir -p ${RPM_TARGET_DIR}/{SPECS,SOURCES}

    PKG_NAME=stackage-dist
    SPEC_FILE=${RPM_TARGET_DIR}/SPECS/${PKG_NAME}.spec
    PKG_VERSION=1
    PKG_RELEASE=1

    cat `which stack` | gzip -c > ${RPM_TARGET_DIR}/SOURCES/stack-bin.gz
    tar --exclude stack-root/programs/\*/\*.tar.xz \
        -czf ${RPM_TARGET_DIR}/SOURCES/stack-root.tar.gz stack-root

    echo ${STACK_ROOT} >> ${RPM_TARGET_DIR}/SOURCES/stack-root-path.txt

    cat ${t}/stackage-dist.rpm.spec \
	| sed s/@@PKG_VERSION@@/${PKG_VERSION}/g \
	| sed s/@@PKG_NAME@@/${PKG_NAME}/g \
	| sed s/@@RESOLVER@@/${resolver}/g \
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
    tempdir=`mktemp --tmpdir -d XXXXXXsdeb-packaging`

    cleanups () {
	rm -rf ${tempdir}
    }

    PKG_NAME=stackage-dist-${resolver}
    PKG_VERSION=1.0
    PKG_RELEASE=1
    PKG_SITE=https://github.com/kernelim/stackage-dist
    PKG_ONELINE="Stackage dist"

    PKG_FULLVER=${PKG_VERSION}-${PKG_RELEASE}
    ARCHIVE_NAME=${PKG_NAME}-${PKG_FULLVER}
    PKG_CHANGELOG_TIMESTAMP=$(date +'%a, %e %b %Y %H:%M:%S %z')

    local dest=${tempdir}/${ARCHIVE_NAME}
    mkdir ${dest}
    cat `which stack` | gzip -c > ${dest}/stack-bin.gz
    cp ${t}/helpers.sh ${dest}/helpers.sh
    cd ${STACK_ROOT}
    tar -czf ${dest}/stack-root-download-cache.tar.gz download-cache
    tar --exclude indices/Hackage/packages \
	--exclude indices/Hackage/git-update \
	-czf ${dest}/stack-root-indices.tar.gz indices
    cd ${tempdir}

    tar -czf ${PKG_NAME}_${PKG_VERSION}.orig.tar.gz ${ARCHIVE_NAME}

    i=${tempdir}/spec
    for distro in ${distros}; do
        cp ${t}/stackage-dist.deb.spec ${i}
        sed -i 's/@@PKG_NAME@@/'"${PKG_NAME}"'/g' ${i}
        sed -i 's/@@PKG_CHANGELOG_TIMESTAMP@@/'"${PKG_CHANGELOG_TIMESTAMP}"'/g' ${i}
        sed -i 's/@@PKG_FULLVER@@/'"${PKG_FULLVER}"'/g' ${i}
        sed -i 's#@@PKG_SITE@@#'"${PKG_SITE}"'#g' ${i}
        sed -i 's/@@PKG_ONELINE@@/'"${PKG_ONELINE}"'/g' ${i}
        sed -i 's/@@PKG_MAINTAINER@@/'"${maintainer}"'/g' ${i}
        sed -i 's/@@DISTRO@@/'"${distro}"'/g' ${i}

        cd ${dest}
        python - <<EOF
import os

f = open("${i}", "r")
for part in f.read().split('%%%%%%%%%%%%%%%%%%%% CUT %%%%%%%%%%%%%%%%%%%%\n'):
    if part.startswith('%%%% '):
       p = part.find('\n')
       filename = part[5:p].strip()
       d = os.path.dirname(filename)
       if d and not os.path.exists(d): os.makedirs(d)
       open(filename, "w").write(part[p+1:])
EOF
        dpkg-buildpackage -S
    done

    cd ${tempdir}
    rm ${i}

    mkdir -p ${outdir}
    cp -v ${tempdir}/* ${outdir}
    cleanups
    return 0
}

make_s$pkgtype
X=$?

echo Done

exit $?
