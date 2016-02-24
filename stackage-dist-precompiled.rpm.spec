%bcond_with debug
%bcond_without many_deps

Name:           @@PKG_NAME@@
Version:        @@PKG_VERSION@@
Release:        @@PKG_RELEASE@@%{?dist}
Summary:        Pre-compilation of Stackage
Group:          System Environment/Development Tools
License:        Various
URL:            https://www.stackage.org

BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Source0:        project.tar.gz
Source1:        fix-bins.py
Source2:        install-ghc.py
Source3:        helpers.sh

BuildRequires:  stackage-dist-@@RESOLVER@@-downloads
BuildRequires:  stackage-dist-@@RESOLVER@@-stack
BuildRequires:  stackage-dist-@@RESOLVER@@-indices

%if @@BATCH_NR@@ > 1
BuildRequires:  stackage-dist-@@RESOLVER@@-precompiled-boot1
BuildRequires:  stackage-dist-@@RESOLVER@@-ghc
%endif
%if @@BATCH_NR@@ > 2
BuildRequires:  stackage-dist-@@RESOLVER@@-precompiled-boot2
%endif
%if @@BATCH_NR@@ > 3
BuildRequires:  stackage-dist-@@RESOLVER@@-precompiled-boot3
%endif
%if @@BATCH_NR@@ > 4
BuildRequires:  stackage-dist-@@RESOLVER@@-precompiled-boot4
%endif

BuildRequires:  git
BuildRequires:  chrpath
BuildRequires:  python
BuildRequires:  gmp-devel

%if 0%{?fedora} >= 24
# GHC builds need tinfo.so.5
BuildRequires:  ncurses-compat-libs
%endif

%if %{with many_deps}
BuildRequires:  ImageMagick-devel
BuildRequires:  R-devel
BuildRequires:  SDL2-devel
BuildRequires:  bzip2-devel
BuildRequires:  cairo-devel
BuildRequires:  fftw-devel
BuildRequires:  fftw2-devel
BuildRequires:  freeglut-devel
BuildRequires:  gd-devel
BuildRequires:  glib2-devel
BuildRequires:  gnutls-devel
BuildRequires:  gsl-devel
BuildRequires:  gtk2-devel
BuildRequires:  gtk3-devel
BuildRequires:  leveldb-devel
BuildRequires:  libX11-devel
BuildRequires:  libXcursor-devel
BuildRequires:  libXi-devel
BuildRequires:  libXinerama-devel
BuildRequires:  libXrandr-devel
BuildRequires:  libcurl-devel
BuildRequires:  libfreenect-devel
BuildRequires:  libgsasl-devel
BuildRequires:  libicu-devel
BuildRequires:  libidn-devel
BuildRequires:  libpcap-devel
BuildRequires:  libsndfile-devel
BuildRequires:  libsqlite3x-devel
BuildRequires:  libxml2-devel
BuildRequires:  libzip-devel
BuildRequires:  mesa-libGL-devel
BuildRequires:  ncurses-devel
BuildRequires:  nettle-devel
BuildRequires:  openssl-devel
BuildRequires:  pango-devel
BuildRequires:  pcre-devel
BuildRequires:  postgresql-devel
BuildRequires:  systemd-devel
BuildRequires:  zeromq-devel
BuildRequires:  zlib-devel
%endif

%global debug_package %{nil}
%define stackage_dist() \
    cd xxxxxxxxxxxxxxxxxxxxxxxx/project \
    set +o posix \
    source %{_sourcedir}/helpers.sh \
    stackage-dist-%{1}-b %{_prefix}/%{_lib}/stackage-dist-@@RESOLVER@@ @@RESOLVER@@ $(pwd) \

%description
Requires:       @@PKG_NAME@@-manifest

%package manifest
Summary:        Pre-compilation of Stackage (Manifest)

%description manifest
Pre-compilation of Stackage (Manifest)

%if @@BATCH_NR@@ == 1
%package -n @@PKG_BASE_NAME@@-ghc
Summary:        Pre-compilation of Stackage (GHC)
License:        New BSD License
URL:            http://www.haskell.org/ghc

%description -n @@PKG_BASE_NAME@@-ghc
Pre-compilation of Stackage (GHC)
%endif

%prep

tar -zxf %{_sourcedir}/project.tar.gz
mkdir xxxxxxxxxxxxxxxxxxxxxxxx
mv project xxxxxxxxxxxxxxxxxxxxxxxx

%stackage_dist setup

%build

%stackage_dist env

stack -v list-build-plan --no-terminal --resolver=$RESOLVER > packages.txt

%if @@BATCH_NR@@ > 1
stackage-setup-extra-package-dbs stack.yaml
%endif

%if %{with debug}
%if @@BATCH_NR@@ > 1
echo mtl-compat > packages.txt
echo pretty-show >> packages.txt
%else
echo exceptions > packages.txt
echo ghc-parser >> packages.txt
%endif
%endif

start_time=`date +%s`
time_limit=14400
end_time=$(($start_time + $time_limit))

while read p; do
    date
    stack install $p --no-terminal --resolver=$RESOLVER || true
    cur_time=`date +%s`
    if (( $cur_time >= $end_time )) ; then
	echo Time limit reached.
	break
    fi
done < packages.txt

%install

%stackage_dist env

INSTALLED_STACKAGE_ROOT=$RPM_BUILD_ROOT/${STACKAGE_DIST_ROOT}
mkdir -p ${INSTALLED_STACKAGE_ROOT}

mv ${STACK_ROOT}/snapshots ${INSTALLED_STACKAGE_ROOT}/snapshots

%if @@BATCH_NR@@ == 1
python %{_sourcedir}/install-ghc.py ${STACK_ROOT} $RPM_BUILD_ROOT ${STACKAGE_DIST_ROOT}/ghc
%endif

cd ${INSTALLED_STACKAGE_ROOT}/snapshots
PKGDB_DIR=$(find . -name pkgdb)
cd ${PKGDB_DIR}/..

mv pkgdb pkgdb.precompiled

cd pkgdb.precompiled
rm -f package.cache
for i in *.conf ; do
    if [[ "$i" != '*.conf' ]] ; then
        sed -i s\#${STACK_ROOT}\#${STACKAGE_DIST_ROOT}\#g $i
    fi
done

cd ${INSTALLED_STACKAGE_ROOT}/snapshots
(find \! -type d ; (find -type d | tac)) | \
    xargs -l1 -I %% python %{_sourcedir}/fix-bins.py %% ${STACK_ROOT} ${STACKAGE_DIST_ROOT}
find . > ../snapshots.manifest.@@BATCH_NR@@

%files
%{_prefix}/%{_lib}/stackage-dist-@@RESOLVER@@/snapshots

%if @@BATCH_NR@@ == 1
%files -n @@PKG_BASE_NAME@@-ghc
%{_prefix}/%{_lib}/stackage-dist-@@RESOLVER@@/bin
%{_prefix}/%{_lib}/stackage-dist-@@RESOLVER@@/ghc
%endif

%files manifest
%{_prefix}/%{_lib}/stackage-dist-@@RESOLVER@@/snapshots.manifest.@@BATCH_NR@@

%changelog
