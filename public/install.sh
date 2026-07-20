#!/usr/bin/env sh
set -e

REPO="enbu-net/enbu"
BINARY="enbu"

# Resolve install directory
if [ -n "${ENBU_INSTALL_DIR}" ]; then
    INSTALL_DIR="${ENBU_INSTALL_DIR}"
elif [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
else
    INSTALL_DIR="${HOME}/.local/bin"
    mkdir -p "${INSTALL_DIR}"
fi

# Fetch latest version
VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' \
    | sed 's/.*"tag_name": *"v\([^"]*\)".*/\1/')

if [ -z "${VERSION}" ]; then
    echo "error: failed to fetch latest version" >&2
    exit 1
fi

# Detect OS and ARCH
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "${OS}" in
    darwin) OS="darwin" ;;
    linux)  OS="linux" ;;
    *)
        echo "error: unsupported OS: ${OS}" >&2
        exit 1
        ;;
esac

ARCH=$(uname -m)
case "${ARCH}" in
    arm64|aarch64) ARCH="arm64" ;;
    *) ARCH="amd64" ;;
esac

# Download and extract
TARBALL="enbu_${VERSION}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/${REPO}/releases/download/v${VERSION}/${TARBALL}"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

echo "Downloading enbu v${VERSION} (${OS}/${ARCH})..."
curl -fsSL "${URL}" -o "${TMP}/${TARBALL}"
tar -xzf "${TMP}/${TARBALL}" -C "${TMP}"
cp "${TMP}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
chmod +x "${INSTALL_DIR}/${BINARY}"

# Add to PATH if needed
case ":${PATH}:" in
    *":${INSTALL_DIR}:"*) ;;
    *)
        LINE="export PATH=\"${INSTALL_DIR}:\$PATH\""
        for RC in "${HOME}/.zshrc" "${HOME}/.bashrc" "${HOME}/.profile"; do
            if [ -f "${RC}" ]; then
                if ! grep -qF "${INSTALL_DIR}" "${RC}" 2>/dev/null; then
                    printf '\n%s\n' "${LINE}" >> "${RC}"
                fi
            fi
        done
        export PATH="${INSTALL_DIR}:${PATH}"
        echo "Added ${INSTALL_DIR} to PATH"
        echo "Restart your shell or run: export PATH=\"${INSTALL_DIR}:\$PATH\""
        ;;
esac

echo "enbu v${VERSION} installed to ${INSTALL_DIR}/${BINARY}"
