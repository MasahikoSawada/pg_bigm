# SPEC file for pg_bigm
# Copyright(C) 2013-2015 NTTDATA Corporation

%define _pgdir   /usr/pgsql-9.4
%define _bindir  %{_pgdir}/bin
%define _libdir  %{_pgdir}/lib
%define _datadir %{_pgdir}/share
%if "%(echo ${MAKE_ROOT})" != ""
  %define _rpmdir %(echo ${MAKE_ROOT})/RPMS
  %define _sourcedir %(echo ${MAKE_ROOT})
%endif

## Set general information for pg_bigm.
Summary:    2-gram full text search for 9.4
Name:       pg_bigm
Version:    1.1.201509011
Release:    1.pg94.%{?dist}
License:    PostgreSQL License
Group:      Applications/Databases
Source0:    %{name}-%{version}.tar.gz
URL:        http://pgbigm.osdn.jp/index_en.html
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-%(%{__id_u} -n)
Vendor:     NTT DATA CORPORATION

## Requires of pg_bigm
BuildRequires:  postgresql94-devel
Requires:  postgresql94-libs

## Description for pg_bigm
%description
The pg_bigm module provides full text search capability in PostgreSQL.
This module allows a user to create 2-gram (bigram) index for faster full text search.

Note that this package is available for only PostgreSQL 9.4.

## Preparation for building pg_bigm
%prep
PATH=/usr/pgsql-9.4/bin:$PATH
if [ "${MAKE_ROOT}" != "" ]; then
  pushd ${MAKE_ROOT}
  make clean %{name}-%{version}.tar.gz
  popd
fi
if [ ! -d %{_rpmdir} ]; then mkdir -p %{_rpmdir}; fi
%setup -q

## Set variables for build environment
%build
PATH=/usr/pgsql-9.4/bin:$PATH
make USE_PGXS=1 %{?_smp_mflags}

## Set variables for install
%install
rm -rf %{buildroot}
install -d %{buildroot}%{_libdir}
install pg_bigm.so %{buildroot}%{_libdir}/pg_bigm.so
install -d %{buildroot}%{_datadir}/extension
install -m 644 pg_bigm--1.2.sql %{buildroot}%{_datadir}/extension/pg_bigm--1.2.sql
install -m 644 pg_bigm.control %{buildroot}%{_datadir}/extension/pg_bigm.control

%clean
rm -rf %{buildroot}

%files
%defattr(0755,root,root)
%{_libdir}/pg_bigm.so
%defattr(0644,root,root)
%{_datadir}/extension/pg_bigm--1.2.sql
%{_datadir}/extension/pg_bigm.control

# Change log of pg_bigm.
%changelog
* Thu Sep 11 2015 Masahiko Sawada <sawada.mshk@gmail.com>
- Initial cut for 1.2.20150911
