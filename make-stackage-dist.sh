#!/bin/bash

set -u

RESOLVER=lts-5.0

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

while getopts "o:nt:m:d:" o; do
    case "${o}" in
        o)
            outdir=${OPTARG}
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

    PKG_NAME=stackage-dist-${RESOLVER}
    SPEC_FILE=${RPM_TARGET_DIR}/SPECS/${PKG_NAME}.spec
    PKG_VERSION=1
    PKG_RELEASE=1

    cat `which stack` | gzip -c > ${RPM_TARGET_DIR}/SOURCES/stack-bin.gz
    cd ${STACK_ROOT}
    tar -czf ${RPM_TARGET_DIR}/SOURCES/stack-root-download-cache.tar.gz download-cache
    tar --exclude indices/Hackage/packages \
	--exclude indices/Hackage/git-update \
	-czf ${RPM_TARGET_DIR}/SOURCES/stack-root-indices.tar.gz indices
    cp ${t}/helpers.sh ${RPM_TARGET_DIR}/SOURCES/helpers.sh

    cat ${t}/stackage-dist.rpm.spec \
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

make_sdeb() {
    tempdir=`mktemp --tmpdir -d XXXXXXsdeb-packaging`

    cleanups () {
	rm -rf ${tempdir}
    }

    PKG_NAME=stackage-dist-${RESOLVER}
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
