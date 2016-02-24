%%%%%%%%%%%%%%%%%%%% CUT %%%%%%%%%%%%%%%%%%%%
%%%% debian/control
Source: @@PKG_NAME@@
Section: devel
Priority: optional
Maintainer: @@PKG_MAINTAINER@@
Build-Depends: debhelper (>= 9)
Standards-Version: 3.9.5
Homepage: @@PKG_SITE@@

Package: @@PKG_NAME@@
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}
Description: @@PKG_ONELINE@@

Package: @@PKG_NAME@@-indices
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}, @@PKG_NAME@@
Description: @@PKG_ONELINE@@ (Hackage indices only)

Package: @@PKG_NAME@@-stack
Architecture: amd64
Depends: ${shlibs:Depends}, ${misc:Depends}, @@PKG_NAME@@
Description: @@PKG_ONELINE@@ (Stack binary)

Package: @@PKG_NAME@@-downloads
Architecture: amd64
Depends: ${shlibs:Depends}, ${misc:Depends}, @@PKG_NAME@@
Description: @@PKG_ONELINE@@ (All downloads)

%%%%%%%%%%%%%%%%%%%% CUT %%%%%%%%%%%%%%%%%%%%
%%%% debian/build.sh
#!/bin/bash

set -e

src_dir=$(pwd)

mkdir -p ${DESTDIR}
cd ${DESTDIR}
mkdir -p usr/lib/@@PKG_NAME@@
cp -a ${src_dir}/helpers.sh usr/lib/@@PKG_NAME@@

mkdir -p ${DESTDIR}-stack/usr/bin
cd ${DESTDIR}-stack/usr/bin
zcat ${src_dir}/stack-bin.gz > stack
chmod a+x stack

mkdir -p ${DESTDIR}-downloads/usr/lib/@@PKG_NAME@@
cd ${DESTDIR}-downloads/usr/lib/@@PKG_NAME@@
tar -zxf ${src_dir}/stack-root-download-cache.tar.gz

mkdir -p ${DESTDIR}-indices/usr/lib/@@PKG_NAME@@
cd ${DESTDIR}-indices/usr/lib/@@PKG_NAME@@
tar -zxf ${src_dir}/stack-root-indices.tar.gz

%%%%%%%%%%%%%%%%%%%% CUT %%%%%%%%%%%%%%%%%%%%
%%%% debian/docs

%%%%%%%%%%%%%%%%%%%% CUT %%%%%%%%%%%%%%%%%%%%
%%%% debian/rules
#!/usr/bin/make -f

DPKG_EXPORT_BUILDFLAGS = 1
include /usr/share/dpkg/default.mk
%:
	dh $@

override_dh_auto_install:
	DESTDIR=$$(pwd)/debian/@@PKG_NAME@@ bash -x debian/build.sh

%%%%%%%%%%%%%%%%%%%% CUT %%%%%%%%%%%%%%%%%%%%
%%%% debian/changelog
@@PKG_NAME@@ (@@PKG_FULLVER@@.@@DISTRO@@) @@DISTRO@@; urgency=low

  * Ubuntu/Debian build. See upstream changelog.

 -- @@PKG_MAINTAINER@@  @@PKG_CHANGELOG_TIMESTAMP@@

%%%%%%%%%%%%%%%%%%%% CUT %%%%%%%%%%%%%%%%%%%%
%%%% debian/source/format
3.0 (quilt)

%%%%%%%%%%%%%%%%%%%% CUT %%%%%%%%%%%%%%%%%%%%
%%%% debian/compat
9
