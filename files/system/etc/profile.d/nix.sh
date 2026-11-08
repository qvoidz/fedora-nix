# Nix integration for all users (sourced at login via /etc/profile.d)
# System-wide profile (what `sudo nix profile install --profile /nix/var/nix/profiles/default ...` populates)
export PATH="/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:$PATH"
export XDG_DATA_DIRS="/nix/var/nix/profiles/default/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"

# Per-user profile (nix profile install without sudo)
export PATH="$HOME/.local/state/nix/profiles/profile/bin:$PATH"
export XDG_DATA_DIRS="$HOME/.local/state/nix/profiles/profile/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
