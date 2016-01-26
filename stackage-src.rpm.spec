Name:           @@PKG_NAME@@
Version:        @@PKG_VERSION@@
Release:        @@PKG_RELEASE@@%{?dist}
Summary:        Asset package for Stackage
Group:          System Environment/Development Tools
License:        BSD
URL:            https://www.stackage.org
Source0:        stack-bin.gz
Source1:        stack-root-download-cache.tar.gz
Source2:        stack-root-indices.tar.gz
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description

%global debug_package %{nil}

%package indices
Summary:        Asset package for Stackage (Hackage indices only)
Requires: %name
BuildArch: noarch
%description indices
Asset package for Stackage (Hackage indices only)

%package stack
Summary:        Asset package for Stackage (Stack binary)
Requires: %name
%description stack
Asset package for Stackage (Stack binary)

%package downloads
Summary:        Asset package for Stackage (All downloads)
Requires: %name
%description downloads
Asset package for Stackage (All downloads)

%prep

unpack_root=$(pwd)
mkdir -p ${unpack_root}/.stack
cd ${unpack_root}/.stack

mkdir bin
zcat %{_sourcedir}/stack-bin.gz > bin/stack
chmod a+x bin/stack

tar -zxf %{_sourcedir}/stack-root-download-cache.tar.gz
tar -zxf %{_sourcedir}/stack-root-indices.tar.gz

%build

unpack_root=$(pwd)
export STACK_ROOT=

%install

unpack_root=$(pwd)
STACKAGE_ROOT=$RPM_BUILD_ROOT/%{_prefix}/%{_lib}/%name
mkdir -p ${STACKAGE_ROOT}/
mv ${unpack_root}/.stack/* ${STACKAGE_ROOT}/

SHARE_DIR=$RPM_BUILD_ROOT/%{_prefix}/share/%name
mkdir -p ${SHARE_DIR}
echo > ${SHARE_DIR}/stamp

%files
%{_prefix}/share/%name

%files downloads
%{_prefix}/%{_lib}/%name/download-cache*

%files stack
%{_prefix}/%{_lib}/%name/bin/stack

%files indices
%{_prefix}/%{_lib}/%name/indices*

%changelog