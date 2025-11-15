#!/usr/bin/env bash
set -euxo pipefail

# Install Flutter SDK (Linux x64)
FLUTTER_DIR="$PWD/flutter"
if [ ! -d "$FLUTTER_DIR/flutter" ]; then
  curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.4-stable.tar.xz -o flutter.tar.xz
  tar -xf flutter.tar.xz
fi

export PATH="$PWD/flutter/flutter/bin:$PATH"
flutter --version
flutter config --enable-web

# Fetch dependencies
flutter pub get

# Build release web to build/web
flutter build web --release

echo "Build complete: build/web"
