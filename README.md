# fedora-nix

A custom Fedora Atomic desktop image: **GNOME on an NVIDIA driver base, with the Nix package manager built in** — built with [BlueBuild](https://blue-build.org).

Base image: `ghcr.io/blue-build/base-images/fedora-base-nvidia` (minimal atomic base + NVIDIA 580 proprietary drivers).

## What's inside

- **GNOME desktop** (`@gnome-desktop-environment` + GDM, Wayland) on top of the minimal base image
- **Nix** (Fedora official package, `nix-daemon` enabled, flakes + nix-command enabled)
  - `/nix` is a bind mount of the persistent `/var/lib/nix` (composefs makes `/` read-only at runtime)
  - patched **glib2** (`glib-appinfo-watch.patch` from nixpkgs) so apps installed via Nix appear/update in the GNOME app grid automatically
- Flathub enabled (system + user), no bundled flatpaks

## Installation

> [!WARNING]
> [Experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable) — try at your own discretion.

Rebase an existing atomic Fedora installation:

```bash
# first, to get signing keys and policies:
rpm-ostree rebase ostree-unverified-registry:ghcr.io/<user>/fedora-nix:latest
systemctl reboot
# then, to the signed image:
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/<user>/fedora-nix:latest
systemctl reboot
```

## Using Nix

After first boot, add your user to the `nix` group and reboot/re-login:

```bash
sudo usermod -aG nix $USER
```

Verify:

```bash
mount | grep /nix          # bind mount from /var/lib/nix
systemctl status nix-daemon
nix-shell -p hello         # or: nix run nixpkgs#hello
```

### Installing apps system-wide (like a normal package manager)

Install into the shared default profile — available to **all users**:

```bash
sudo nix profile install --profile /nix/var/nix/profiles/default nixpkgs#firefox
```

Or install into your own profile (just for you, no sudo):

```bash
nix profile install nixpkgs#firefox
```

`/etc/profile.d/nix.sh` (baked into the image) puts both profiles' `bin` on `PATH` and their `share` on `XDG_DATA_DIRS`, so GUI apps appear in GNOME. The patched glib2 watches both profile locations, so newly installed apps show up in the app grid without rebooting.

If you hit SELinux denials around `/nix`, try `sudo restorecon -R /var/lib/nix` and check `ausearch -m avc -ts recent`.

## Building

CI (`.github/workflows/build.yml`) builds the image daily and on push via [blue-build/github-action](https://github.com/blue-build/github-action). To build locally:

```bash
bluebuild validate recipes/recipe.yml
bluebuild build recipes/recipe.yml
```

## Verification

Images are signed with [cosign](https://github.com/sigstore/cosign):

```bash
cosign verify --key cosign.pub ghcr.io/<user>/fedora-nix
```
