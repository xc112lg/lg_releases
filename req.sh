#!/usr/bin/env bash
# install_aosp_deps.sh
# Installs host dependencies for building AOSP / LineageOS.
# Supports Ubuntu 22.04/24.04 and Debian 12 (amd64). Run as a normal user with sudo rights.
set -euo pipefail

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------
[[ $EUID -eq 0 ]] && die "Do not run as root. The script calls sudo where needed."
command -v sudo >/dev/null 2>&1 || die "sudo is required."

# shellcheck disable=SC1091
. /etc/os-release
case "${ID}" in
    ubuntu|debian|linuxmint|pop) ;;
    *) die "Unsupported distro '${ID}'. This script supports Ubuntu/Debian." ;;
esac
log "Detected ${PRETTY_NAME}"

ARCH="$(dpkg --print-architecture)"
[[ "${ARCH}" == "amd64" ]] || die "AOSP build host must be amd64 (found ${ARCH})."

RAM_GB="$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)"
if (( RAM_GB < 16 )); then
    warn "Only ${RAM_GB} GB RAM detected. 16 GB minimum, 32 GB+ recommended."
fi

FREE_GB="$(df -BG --output=avail "${HOME}" | tail -1 | tr -dc '0-9')"
if (( FREE_GB < 300 )); then
    warn "Only ${FREE_GB} GB free in ${HOME}. A full AOSP checkout needs ~250-300 GB+."
fi

# ---------------------------------------------------------------------------
# APT packages
# ---------------------------------------------------------------------------
log "Updating package index and upgrading existing packages"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

# Enable 32-bit architecture libs (needed by some host tools and prebuilts)
if ! dpkg --print-foreign-architectures | grep -qx i386; then
    log "Adding i386 architecture"
    sudo dpkg --add-architecture i386
    sudo apt-get update
fi

WANTED_PKGS=(
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib
    git git-lfs gnupg gperf imagemagick lib32ncurses-dev lib32readline-dev
    lib32z1-dev libc6-dev-i386 libelf-dev libgl1-mesa-dev liblz4-tool
    libncurses-dev libncurses5-dev libsdl1.2-dev libssl-dev libx11-dev
    libxml2 libxml2-utils lzop openjdk-17-jdk pngcrush procps python-is-python3
    python3 python3-pip python3-venv rsync schedtool squashfs-tools unzip
    x11proto-core-dev xsltproc zip zlib1g-dev dwarves fontconfig
    libreadline-dev libzstd-dev aria2 jq tmux htop
)

# Only install packages that exist on this release (names differ across versions)
INSTALL_PKGS=()
for pkg in "${WANTED_PKGS[@]}"; do
    if apt-cache show "${pkg}" >/dev/null 2>&1; then
        INSTALL_PKGS+=("${pkg}")
    else
        warn "Package '${pkg}' not available on this release, skipping."
    fi
done

log "Installing ${#INSTALL_PKGS[@]} packages"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${INSTALL_PKGS[@]}"

# ---------------------------------------------------------------------------
# Java: make sure JDK 17 is the default (AOSP/LineageOS builds expect it)
# ---------------------------------------------------------------------------
if [[ -d /usr/lib/jvm/java-17-openjdk-amd64 ]]; then
    log "Setting OpenJDK 17 as default java"
    sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java || \
        warn "Could not switch default java; check 'update-alternatives --config java'."
fi

# ---------------------------------------------------------------------------
# git-repo
# ---------------------------------------------------------------------------
REPO_BIN="${HOME}/bin/repo"
mkdir -p "${HOME}/bin"
if [[ ! -x "${REPO_BIN}" ]]; then
    log "Installing git-repo to ${REPO_BIN}"
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "${REPO_BIN}"
    chmod a+x "${REPO_BIN}"
else
    log "git-repo already present at ${REPO_BIN}, updating"
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "${REPO_BIN}.tmp" \
        && mv "${REPO_BIN}.tmp" "${REPO_BIN}" && chmod a+x "${REPO_BIN}"
fi

# Ensure ~/bin is on PATH for future shells
PATH_LINE='export PATH="$HOME/bin:$PATH"'
if ! grep -qsF "${PATH_LINE}" "${HOME}/.bashrc"; then
    log "Adding ~/bin to PATH in ~/.bashrc"
    printf '\n%s\n' "${PATH_LINE}" >> "${HOME}/.bashrc"
fi
export PATH="${HOME}/bin:${PATH}"

# ---------------------------------------------------------------------------
# Kernel / system tuning recommended for AOSP
# ---------------------------------------------------------------------------
log "Raising inotify watch limit (needed by Soong/Ninja on large trees)"
echo "fs.inotify.max_user_watches=524288" | sudo tee /etc/sysctl.d/99-aosp.conf >/dev/null
sudo sysctl --system >/dev/null

# ---------------------------------------------------------------------------
# ccache setup
# ---------------------------------------------------------------------------
CCACHE_DIR_DEFAULT="${HOME}/.ccache"
if ! grep -qsF "USE_CCACHE=1" "${HOME}/.bashrc"; then
    log "Configuring ccache in ~/.bashrc"
    {
        printf '\n# AOSP build settings\n'
        printf 'export USE_CCACHE=1\n'
        printf 'export CCACHE_EXEC=/usr/bin/ccache\n'
        printf 'export CCACHE_DIR="%s"\n' "${CCACHE_DIR_DEFAULT}"
    } >> "${HOME}/.bashrc"
fi
ccache -M 100G >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# git identity check (repo sync and commits need it)
# ---------------------------------------------------------------------------
if [[ -z "$(git config --global user.name || true)" || -z "$(git config --global user.email || true)" ]]; then
    warn "git user.name / user.email not set. Run:"
    warn "  git config --global user.name \"Your Name\""
    warn "  git config --global user.email \"you@example.com\""
fi
git lfs install >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------
log "Verifying tools"
MISSING=0
for tool in git repo python3 java make gcc g++ bison flex zip unzip xsltproc ccache rsync; do
    if command -v "${tool}" >/dev/null 2>&1; then
        printf '  %-10s OK  (%s)\n' "${tool}" "$(command -v "${tool}")"
    else
        printf '  %-10s MISSING\n' "${tool}"
        MISSING=1
    fi
done

java -version 2>&1 | head -1 || true

if (( MISSING )); then
    die "Some tools are missing. Check the output above."
fi

log "Done. Open a new terminal (or run: source ~/.bashrc) before starting a build."
