#!/usr/bin/env bash
# Downloads the app's fonts into assets/fonts/. They are git-ignored:
# Satoshi's license (ITF Free Font License) allows embedding it in the app
# but not making the font files available to others, and this repository
# is public. JetBrains Mono (OFL) is fetched the same way for consistency.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p assets/fonts/satoshi assets/fonts/jetbrains_mono

curl -fsSL -o "$tmp/satoshi.zip" \
  "https://api.fontshare.com/v2/fonts/download/satoshi"
for weight in Light Regular Medium Bold; do
  unzip -o -j -q "$tmp/satoshi.zip" \
    "Satoshi_Complete/Fonts/OTF/Satoshi-$weight.otf" -d assets/fonts/satoshi
done
unzip -o -j -q "$tmp/satoshi.zip" \
  "Satoshi_Complete/License/FFL.txt" -d assets/fonts/satoshi

curl -fsSL -o "$tmp/jetbrains_mono.zip" \
  "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"
for weight in Regular Medium; do
  unzip -o -j -q "$tmp/jetbrains_mono.zip" \
    "fonts/ttf/JetBrainsMono-$weight.ttf" -d assets/fonts/jetbrains_mono
done
unzip -o -j -q "$tmp/jetbrains_mono.zip" "OFL.txt" -d assets/fonts/jetbrains_mono

echo "Fonts ready in assets/fonts/"
