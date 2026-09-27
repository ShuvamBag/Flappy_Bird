#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.47.5"
CACHE_ROOT="${NETLIFY_CACHE_DIR:-${TMPDIR:-/tmp}/netlify-cache}"
FLUTTER_SDK_DIR="$CACHE_ROOT/flutter-$FLUTTER_VERSION"

mkdir -p "$CACHE_ROOT"

if [[ ! -x "$FLUTTER_SDK_DIR/bin/flutter" ]]; then
  install_dir="$(mktemp -d "$CACHE_ROOT/flutter-install.XXXXXX")"
  trap 'rm -rf "$install_dir"' EXIT

  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$install_dir/flutter"

  export PATH="$install_dir/flutter/bin:$PATH"
  flutter config --no-analytics
  flutter precache --web

  rm -rf "$FLUTTER_SDK_DIR"
  mv "$install_dir/flutter" "$FLUTTER_SDK_DIR"
  rm -rf "$install_dir"
  trap - EXIT
fi

export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
export PUB_CACHE="$CACHE_ROOT/pub-cache"

flutter config --no-analytics
flutter precache --web
flutter pub get --enforce-lockfile
flutter build web --release
