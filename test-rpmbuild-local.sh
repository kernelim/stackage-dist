#!/bin/bash

set -u

t=${BASH_SOURCE[0]}
t=$(dirname ${t})
t=$(realpath ${t})

syntax() {
    echo "testbuild-pkgs -i <input-dir> -n"
}

inputdir=""
keep=0
while getopts "i:k" o; do
    case "${o}" in
        i)
            inputdir=${OPTARG}
            ;;
        k)
            keep=1
            ;;
        *)
            syntax
            exit 1
            ;;
    esac
done

if [ -z "$inputdir" ] ; then
    echo error: no input directory specified
    echo
    syntax
    exit 1
fi

test_srpm() {
    cleanups () {
	rm -rf ${RPM_TARGET_DIR}
    }

    RPM_TARGET_DIR=`mktemp --tmpdir -d XXXXXXrpm-packaging-testing`

    SRPM_FILE=${inputdir}/*.src.rpm
    rpm --define "_topdir ${RPM_TARGET_DIR}" -i ${inputdir}/*.src.rpm
    find ${RPM_TARGET_DIR}

    sudo unshare -n sudo -u ${USER} rpmbuild -ba \
	     --define "_topdir ${RPM_TARGET_DIR}" \
	     ${RPM_TARGET_DIR}/SPECS/*.spec \

    if [[ "$keep" == "0" ]] ; then
        cleanups
    fi

    return 0
}

test_srpm
