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
  # append the patch line after the Source tag (sed 'a' keeps it a separate line)
  sed -i '/^Source[0-9]*:/a Patch1000: glib-appinfo-watch.patch' "$SPEC"
fi

# Build without the brp post-processing chain (strip/shebang/pyc optimizations).
# gi-docgen leaves phantom '.#.*' entries in the buildroot docs that make
# several brp scanners die with ENOENT; none of it matters for our runtime lib.
rpmbuild -ba --nocheck \
  --define '__os_install_post %{nil}' \
  --define 'debug_package %{nil}' \
  "$SPEC"

# Export rpms for the copy module
mkdir -p /out/rpms
find ~/rpmbuild/RPMS -name 'glib2-*.rpm' -exec cp {} /out/rpms/ \;
ls -la /out/rpms
