#!/bin/bash
set -e

echo "Installing Flutter..."

git clone --depth 1 --branch stable https://github.com/flutter/flutter.git flutter

export PATH="$PATH:$(pwd)/flutter/bin"

echo "Flutter version"
flutter --version

flutter config --enable-web

flutter pub get

flutter build web --release
