Name:           @@PKG_NAME@@
Version:        @@PKG_VERSION@@
Release:        @@PKG_RELEASE@@%{?dist}
Summary:        Asset package for Stackage
Group:          System Environment/Development Tools
License:        BSD
URL:            https://www.stackage.org
Source0:        stack-bin.gz
Source1:        stack-root.tar.gz
Source2:        stack-root-path.txt
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description

%global debug_package %{nil}

%package snapshot-@@RESOLVER@@
Summary:        Asset package
Requires: %name
Requires: git

%description snapshot-@@RESOLVER@@
Asset package for Stackage

%package ghc-7.10.3
Summary:        Asset package
Requires:       gmp-devel
Requires:       %name

%if 0%{?fedora} >= 24
# GHC builds need tinfo.so.5
Requires:       ncurses-compat-libs
BuildRequires:  glibc-langpack-en
%endif

%description ghc-7.10.3
Asset package for Stackage

%package indices
Summary:        Asset package
Requires: %name

%description indices
Asset package for Stackage

%package source-cache-@@RESOLVER@@
Summary:        Asset package
Requires: %name

%description source-cache-@@RESOLVER@@
Asset package for Stackage

%prep

tar -zxf %{_sourcedir}/stack-root.tar.gz

mkdir bin
zcat %{_sourcedir}/stack-bin.gz > bin/stack
chmod a+x bin/stack

%build

%install

STACKAGE_DIST_ROOT=$RPM_BUILD_ROOT/%{_libexecdir}/%{name}
mkdir -p ${STACKAGE_DIST_ROOT}/
mv stack-root/* ${STACKAGE_DIST_ROOT}/
bin/stack relocate ${STACKAGE_DIST_ROOT} %{_libexecdir}/%{name} \
	  --source=$(cat %{_sourcedir}/stack-root-path.txt)
mv bin ${STACKAGE_DIST_ROOT}/

%files
%{_libexecdir}/%{name}/bin/stack
%{_libexecdir}/%{name}/config.yaml
%{_libexecdir}/%{name}/global-project

%files snapshot-@@RESOLVER@@
%{_libexecdir}/%{name}/build-plan
%{_libexecdir}/%{name}/build-plan-cache
%{_libexecdir}/%{name}/snapshots

%files ghc-7.10.3
%{_libexecdir}/%{name}/programs/x86_64-linux/ghc-7.10.3.installed
%{_libexecdir}/%{name}/programs/x86_64-linux/ghc-7.10.3

%files indices
%{_libexecdir}/%{name}/indices/Hackage/00-index.*
%{_libexecdir}/%{name}/indices/Hackage/git-update

%files source-cache-@@RESOLVER@@
%{_libexecdir}/%{name}/indices/Hackage/packages

%changelog
