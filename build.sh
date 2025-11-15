#!/usr/bin/env sh
set -eux

# Install Flutter SDK (Linux x64)
FLUTTER_DIR="$PWD/flutter"
# Allow pinning Flutter version via env, default to a recent stable
FLUTTER_VERSION="${FLUTTER_VERSION:-3.35.4}"
FLUTTER_TAR_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

if [ ! -d "$FLUTTER_DIR" ]; then
  if command -v curl >/dev/null 2>&1; then
    curl -L "$FLUTTER_TAR_URL" -o flutter.tar.xz
  elif command -v wget >/dev/null 2>&1; then
    wget -O flutter.tar.xz "$FLUTTER_TAR_URL"
  else
    echo "Error: neither curl nor wget is available" >&2
    exit 127
  fi
  tar -xf flutter.tar.xz
fi

# Ensure flutter binary is on PATH
export PATH="$FLUTTER_DIR/bin:$PATH"
export CI=true
# Silence git's ownership checks inside Vercel's build environment (if git exists)
if command -v git >/dev/null 2>&1; then
  git config --global --add safe.directory "$FLUTTER_DIR" || true
fi
"$FLUTTER_DIR/bin/flutter" --version
"$FLUTTER_DIR/bin/flutter" config --no-analytics
"$FLUTTER_DIR/bin/flutter" config --enable-web
"$FLUTTER_DIR/bin/flutter" precache --web

# Fetch dependencies
"$FLUTTER_DIR/bin/flutter" pub get

# Build release web to build/web
"$FLUTTER_DIR/bin/flutter" build web --release

echo "Build complete: build/web"
