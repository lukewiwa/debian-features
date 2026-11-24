#!/usr/bin/env bash

set -e

PACKAGES="$(echo "${PACKAGES:-}" | tr ',' ' ')"
PREFIX="/home/linuxbrew/.linuxbrew"
BREW="${PREFIX}/bin/brew"

if [ "$(id -u)" -ne 0 ]; then
    echo "Script must be run as root" >&2
    exit 1
fi

# Homebrew refuses to run as root, so the prefix belongs to the container's user
BREW_USER="${_REMOTE_USER:-}"
if [ -z "$BREW_USER" ] || [ "$BREW_USER" = "root" ]; then
    BREW_USER="$(awk -F: '$3 == 1000 { print $1 }' /etc/passwd)"
fi
if [ -z "$BREW_USER" ] || [ "$BREW_USER" = "root" ]; then
    echo "No non-root user to own Homebrew (it can't install as root)" >&2
    exit 1
fi

# Homebrew's requirements on Linux (https://docs.brew.sh/Homebrew-on-Linux#requirements)
missing=()
for pkg in ca-certificates curl file git procps build-essential; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if [ "${#missing[@]}" -gt 0 ]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y --no-install-recommends "${missing[@]}"
    rm -rf /var/lib/apt/lists/*
fi

# Install Homebrew itself. Formulae come from Homebrew's JSON API, so there is
# no homebrew-core clone (several GB of history), and Homebrew/brew is cloned
# shallow at its latest release.
if [ -x "$BREW" ]; then
    echo "Homebrew already installed"
else
    echo "Installing Homebrew for ${BREW_USER}..."
    mkdir -p "$PREFIX"
    tag="$(git ls-remote --tags --refs --sort=-v:refname https://github.com/Homebrew/brew '[0-9]*' \
        | head -1 | sed 's|.*refs/tags/||')"
    # Clone main (so `brew update` has origin/main), then sit on the latest
    # release as `stable`, like Homebrew's own installer
    git clone --quiet --depth 1 https://github.com/Homebrew/brew "${PREFIX}/Homebrew"
    if [ -n "$tag" ]; then
        git -C "${PREFIX}/Homebrew" fetch --quiet --depth 1 origin tag "$tag"
        git -C "${PREFIX}/Homebrew" checkout --quiet -B stable "$tag"
    fi
    mkdir -p "${PREFIX}/bin"
    ln -sf ../Homebrew/bin/brew "$BREW"
    chown -R "${BREW_USER}:" "$PREFIX"
fi

# On Linux hosts the dev container CLI changes the user's UID to match the
# host's after the image is built (updateRemoteUserUID), which leaves the
# prefix owned by the old UID and Homebrew unable to write to it. Hand it back
# at container start.
ENTRYPOINT="/usr/local/share/homebrew-packages/entrypoint.sh"
mkdir -p "$(dirname "$ENTRYPOINT")"
cat > "$ENTRYPOINT" <<EOF
#!/bin/sh
dir="$PREFIX"
user="$BREW_USER"
EOF
cat >> "$ENTRYPOINT" <<'EOF'
if [ "$(stat -c %u "$dir")" != "$(id -u "$user")" ]; then
    if [ "$(id -u)" = 0 ]; then
        chown -R "$user:" "$dir"
    else
        sudo -n chown -R "$user:" "$dir" 2>/dev/null \
            || echo "homebrew-packages: cannot chown $dir to $user (no root or sudo)" >&2
    fi
fi
exec "$@"
EOF
chmod 755 "$ENTRYPOINT"

# Login shells reset PATH from /etc/profile; put Homebrew back on it
cat > /etc/profile.d/homebrew.sh <<EOF
eval "\$(${BREW} shellenv)"
EOF

if [ -z "${PACKAGES// /}" ]; then
    echo "No Homebrew packages requested, nothing more to do"
    exit 0
fi

echo "Installing Homebrew packages as ${BREW_USER}: ${PACKAGES}"
# shellcheck disable=SC2086
su "$BREW_USER" -c "HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ENV_HINTS=1 $BREW install $PACKAGES"

# Keep the image layer small: downloads and caches aren't needed after install
su "$BREW_USER" -c "$BREW cleanup --prune=all -s" || true
rm -rf "/home/${BREW_USER}/.cache/Homebrew" 2>/dev/null || true

echo "Homebrew packages installed!"
