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

echo "📥 Fetching dependencies..."
flutter pub get

echo "🌐 Building Flutter web..."
flutter build web --release

echo "📄 Adding Netlify redirects..."
# Ensure build/web exists before copying
mkdir -p build/web
cat > build/web/_redirects <<EOL
/*    /index.html   200
EOL

echo "🎉 Flutter web build completed with redirects."



