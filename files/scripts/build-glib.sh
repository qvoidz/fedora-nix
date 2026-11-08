#!/usr/bin/env bash

set -euox pipefail

# Build a patched glib2 RPM (glib-appinfo-watch.patch from nixpkgs) so that
# GNOME's app grid picks up .desktop files installed via Nix profiles.
# Runs inside the glib2-build stage; output rpms go to /out/rpms.

dnf install -y rpmdevtools rpm-build 'dnf-command(builddep)'
dnf builddep -y glib2

# Fetch the glib2 source rpm
mkdir -p /build && cd /build
dnf download --source glib2
rpm -ivh glib2-*.src.rpm

# Install the patch and inject it into the spec
cp /tmp/patches/glib-appinfo-watch.patch ~/rpmbuild/SOURCES/
SPEC=~/rpmbuild/SPECS/glib2.spec
if ! grep -q "glib-appinfo-watch" "$SPEC"; then
  # insert only once, right after the first Source line
  sed -i '0,/^Source[0-9]*:/s//&\nPatch1000: glib-appinfo-watch.patch/' "$SPEC"
fi

# Build (skip %check to keep build times reasonable)
rpmbuild -ba --nocheck "$SPEC"

# Export rpms for the copy module
mkdir -p /out/rpms
find ~/rpmbuild/RPMS -name 'glib2-*.rpm' -exec cp {} /out/rpms/ \;
ls -la /out/rpms
