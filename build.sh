#!/usr/bin/env bash
set -euxo pipefail

# Install Flutter SDK (Linux x64)
FLUTTER_DIR="$PWD/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.4-stable.tar.xz -o flutter.tar.xz
  tar -xf flutter.tar.xz
fi

# Ensure flutter binary is on PATH
export PATH="$FLUTTER_DIR/bin:$PATH"
chmod +x "$FLUTTER_DIR/bin/flutter" || true
"$FLUTTER_DIR/bin/flutter" --version
"$FLUTTER_DIR/bin/flutter" config --enable-web

# Fetch dependencies
"$FLUTTER_DIR/bin/flutter" pub get

# Build release web to build/web
"$FLUTTER_DIR/bin/flutter" build web --release

echo "Build complete: build/web"
