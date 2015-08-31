# SPEC file for pg_bigm
#
# This is template for pg_bigm SPEC file.
# When building pg_bigm RPM, you need to replace following symbol to version
# you want to build with.
#
# X.Y          : PostgreSQL major and minor version, like 9.4
# x.y.YYYYMMDD : pg_bigm version, like 1.2-20150101.
#
# Building process example:
# 1. Fill this SPEC file up.
# 2. Build RPM file.
#    $ mkdir /tmp/{SOURCES, SPECS}
#    $ cp pg_bigm /tmp/SOURCES
#    $ cp pg_bigm.spec /tmp/SPECS
#    $ cd /tmp/SPECS
#    $ rpm -bb pg_bigm.spec
#
#
# Copyright(C) 2013-2015 NTTDATA Corporation

%define _pgdir   /usr/pgsql-X.Y
%define _bindir  %{_pgdir}/bin
%define _libdir  %{_pgdir}/lib
%define _datadir %{_pgdir}/share
%if "%(echo ${MAKE_ROOT})" != ""
  %define _rpmdir %(echo ${MAKE_ROOT})/RPMS
  %define _sourcedir %(echo ${MAKE_ROOT})
%endif

## Set general information for pg_bigm.
Summary:    2-gram full text search for X.Y
Name:       pg_bigm
Version:    x.y.YYYYMMDD
Release:    1.pgXY.%{?dist}
License:    PostgreSQL License
Group:      Applications/Databases
Source0:    %{name}-%{version}.tar.gz
URL:        http://pgbigm.osdn.jp/index_en.html
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-%(%{__id_u} -n)
Vendor:     NTT DATA CORPORATION

## Requires of pg_bigm
BuildRequires:  postgresqlXY-devel
Requires:  postgresqlXY-libs

## Description for pg_bigm
%description
The pg_bigm module provides full text search capability in PostgreSQL.
This module allows a user to create 2-gram (bigram) index for faster full text search.

Note that this package is available for only PostgreSQL X..

## Preparation for building pg_bigm
%prep
PATH=/usr/pgsql-X,Y/bin:$PATH
if [ "${MAKE_ROOT}" != "" ]; then
  pushd ${MAKE_ROOT}
  make clean %{name}-%{version}.tar.gz
  popd
fi
if [ ! -d %{_rpmdir} ]; then mkdir -p %{_rpmdir}; fi
%setup -q

## Set variables for build environment
%build
PATH=/usr/pgsql-X.Y/bin:$PATH
make USE_PGXS=1 %{?_smp_mflags}

## Set variables for install
%install
rm -rf %{buildroot}
install -d %{buildroot}%{_libdir}
install pg_bigm.so %{buildroot}%{_libdir}/pg_bigm.so
install -d %{buildroot}%{_datadir}/extension
install -m 644 pg_bigm--x.y.sql %{buildroot}%{_datadir}/extension/pg_bigm--x.y.sql
install -m 644 pg_bigm.control %{buildroot}%{_datadir}/extension/pg_bigm.control

%clean
rm -rf %{buildroot}

%files
%defattr(0755,root,root)
%{_libdir}/pg_bigm.so
%defattr(0644,root,root)
%{_datadir}/extension/pg_bigm--x.y.sql
%{_datadir}/extension/pg_bigm.control

# Change log of pg_bigm.
%changelog
* Thu Sep 11 2015 Masahiko Sawada <sawada.mshk@gmail.com>
- Initial cut for 1.2.20150911
