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
rm -rf build/web

echo "📥 Fetching dependencies..."
flutter pub get

echo "🌐 Building Flutter web..."
flutter build web --release \
  --dart-define=SUPABASE_URL="https://gvsorguincvinuiqtooo.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2c29yZ3VpbmN2aW51aXF0b29vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjY0ODgxOSwiZXhwIjoyMDY4MjI0ODE5fQ.9fuH7ZPslf9S875L2Q7YZxbvKoScQ-KTgIFQMOdOo9w" \
  --dart-define=SUPABASE_SERVICE_ROLE="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2c29yZ3VpbmN2aW51aXF0b29vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjY0ODgxOSwiZXhwIjoyMDY4MjI0ODE5fQ.9fuH7ZPslf9S875L2Q7YZxbvKoScQ-KTgIFQMOdOo9w"

echo "📄 Adding Netlify redirects..."
# Ensure build/web exists before copying
mkdir -p build/web
cat > build/web/_redirects <<EOL
/*    /index.html   200
EOL

echo "🎉 Flutter web build completed with redirects."



