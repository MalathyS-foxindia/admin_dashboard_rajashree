#!/bin/bash
set -e

echo "📦 Installing Flutter..."
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
fi

export PATH="$HOME/flutter/bin:$PATH"

echo "✅ Flutter installed. Enabling web..."
flutter config --enable-web

echo "🔍 Checking Flutter setup..."
flutter doctor

echo "Flutter Clean..."
flutter clean

echo "📥 Fetching dependencies..."
flutter pub get

echo "🌐 Building Flutter web..."
flutter build web --release

echo "🎉 Flutter web build completed."
