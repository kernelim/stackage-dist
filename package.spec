Name:           @@PKG_NAME@@
Version:        @@PKG_VERSION@@
Release:        @@PKG_RELEASE@@%{?dist}
Summary:        Trying to build using LTS
Group:          System Environment/Development Tools
License:        BSD
URL:            https://website.com
Source0:        all-pkg.tar.gz
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildRequires:  stackage-dist-@@RESOLVER@@-downloads
BuildRequires:  stackage-dist-@@RESOLVER@@-stack
BuildRequires:  stackage-dist-@@RESOLVER@@-indices

#-----
BuildRequires:  git
BuildRequires:  libicu-devel
BuildRequires:  zlib-devel
BuildRequires:  openssl-devel
BuildRequires:  gmp-devel
BuildRequires:  pcre-devel

%description

%global debug_package %{nil}

%prep

tar -zxf %{_sourcedir}/all-pkg.tar.gz

%build

SYSTEM_STACK_ROOT=%{_prefix}/%{_lib}/stackage-dist-@@RESOLVER@@

export PATH=${SYSTEM_STACK_ROOT}/bin:$PATH
export STACK_ROOT=`pwd`/.stack
mkdir ${STACK_ROOT}

cat << EOF > ${STACK_ROOT}/config.yaml
download-cache-paths:
- ${SYSTEM_STACK_ROOT}/download-cache
- ${STACK_ROOT}/download-cache
EOF

mkdir -p ${STACK_ROOT}/indices/Hackage/
ln -s ${SYSTEM_STACK_ROOT}/indices/Hackage/* ${STACK_ROOT}/indices/Hackage/

cd All
stack setup
stack build

%install

export STACK_ROOT=`pwd`/.stack
cd All

%files

%changelog
