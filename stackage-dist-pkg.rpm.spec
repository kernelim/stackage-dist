%define pkg_lib   @@HAS_LIB@@

Name:           @@PKG_NAME@@
Version:        @@PKG_VERSION@@
Release:        @@PKG_RELEASE@@%{?dist}
Summary:        Pre-compilation of a Stackage package
Group:          System Environment/Development Tools
License:        Various
URL:            https://www.stackage.org

BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Source0:        nothing.txt

BuildRequires:  stackage-dist-snapshot-@@RESOLVER@@
BuildRequires:  stackage-dist-ghc-7.10.3
BuildRequires:  stackage-dist-indices
BuildRequires:  stackage-dist-source-cache-@@RESOLVER@@

BuildRequires:  git
BuildRequires:  chrpath
BuildRequires:  gmp-devel

%if 0%{?fedora} >= 24
# GHC builds need tinfo.so.5
BuildRequires:  ncurses-compat-libs
BuildRequires:  glibc-langpack-en
%endif

@@BUILD_REQUIRES@@
# @@REQUIRES@@

%description

%if 0%{?pkg_lib}
%package lib
Summary:        Pre-compilation of a Stackage package
Requires: @@PKG_NAME@@
%description lib

%package devel
Summary:        Pre-compilation of a Stackage package
Requires: @@PKG_NAME@@-lib
Requires: stackage-dist-snapshot-@@RESOLVER@@
Requires: stackage-dist-ghc-7.10.3
@@DEVEL_REQUIRES@@

%description devel
%endif

%prep

%build

## Either unset LDFLAGS (which seems to be '-Wl,-Bsymbolic-functions -Wl,-z,relro' in
## launchpad) or:

%define stackage_dist \
	export LC_ALL=en_US.UTF-8 \
        export LANG=en_US.UTF-8 \
        export LANGUAGE=en_US.UTF-8 \
	export STACK_SYSTEM_ROOT=%{_libexecdir}/stackage-dist \
        export STACK_ROOT=`pwd`/stack-root \
        export PATH=${STACK_SYSTEM_ROOT}/bin:$PATH \
        unset LDFLAGS

%stackage_dist

mkdir -p $STACK_ROOT
mkdir -p $STACK_ROOT/global-project

echo "resolver: @@RESOLVER@@" >  $STACK_ROOT/global-project/stack.yaml
echo "flags: {}"              >> $STACK_ROOT/global-project/stack.yaml
echo "extra-package-dbs: []"  >> $STACK_ROOT/global-project/stack.yaml
echo "packages: []"           >> $STACK_ROOT/global-project/stack.yaml
echo "extra-deps: []"         >> $STACK_ROOT/global-project/stack.yaml

echo "{}" > $STACK_ROOT/config.yaml


%install
%stackage_dist

stack --resolver=@@RESOLVER@@ -v install @@NAME@@

INSTALLED_STACKAGE_ROOT=$RPM_BUILD_ROOT/%{_libexecdir}/stackage-dist
mkdir -p $INSTALLED_STACKAGE_ROOT
cp -a $STACK_ROOT/snapshots $INSTALLED_STACKAGE_ROOT
rm -f $(find $INSTALLED_STACKAGE_ROOT -name package.cache)
stack relocate \
      $INSTALLED_STACKAGE_ROOT \
      %{_libexecdir}/stackage-dist \
      --source $STACK_ROOT

empty_package_file=%{_libexecdir}/stackage-dist/snapshots/x86_64-linux/@@RESOLVER@@/7.10.3/.empty-package-@@NAME@@

%if 0%{?pkg_lib}
find $RPM_BUILD_ROOT -name \*.so \
    | sed "s#$RPM_BUILD_ROOT##g" \
    > lib.files
if [[ ! -s lib.files ]] ; then
    touch $RPM_BUILD_ROOT/${empty_package_file}
    echo ${empty_package_file} >> lib.files
fi

find $RPM_BUILD_ROOT \-name \*.a \
     -o -name \*.hi \
     -o -name \*.h \
     -o -name \*.conf \
     -o -name \*.dyn_hi \
    | sed "s#$RPM_BUILD_ROOT##g" \
	  > devel.files
if [[ ! -s devel.files ]] ; then
    touch $RPM_BUILD_ROOT/${empty_package_file}
    echo ${empty_package_file} >> devel.files
fi

[ -x ${INSTALLED_STACKAGE_ROOT}/snapshots/*/*/*/lib/*/*/include ] && \
    (echo '%{_libexecdir}/stackage-dist/snapshots/*/*/*/lib/*/*/include' >> devel.files)

%endif

echo -n > main.files

for extradir in doc bin share installed-packages; do
    [ -x ${INSTALLED_STACKAGE_ROOT}/snapshots/*/*/*/${extradir} ] && \
	(echo '%{_libexecdir}/stackage-dist/snapshots/*/*/*/'${extradir} >> main.files )
done

if [[ ! -s main.files ]] ; then
    touch $RPM_BUILD_ROOT/${empty_package_file}
    echo ${empty_package_file} >> main.files
fi

%files -f main.files

%if 0%{?pkg_lib}
%files lib -f lib.files
%files devel -f devel.files

%define ghc_pkg_recache \
	export PATH=%{_libexecdir}/stackage-dist/programs/x86_64-linux/ghc-7.10.3/bin:$PATH \
        SNAPDIR=%{_libexecdir}/stackage-dist/snapshots/x86_64-linux/@@RESOLVER@@/7.10.3 \
        PKGDB=${SNAPDIR}/pkgdb \
        ghc-pkg --package-db=${PKGDB} recache

%post devel
%ghc_pkg_recache

%postun devel
%ghc_pkg_recache
%endif

%changelog
