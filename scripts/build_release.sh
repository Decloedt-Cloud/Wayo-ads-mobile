#!/usr/bin/env bash
set -euo pipefail

# Build Android APKs (split per ABI for smaller downloads)
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --tree-shake-icons \
  --split-per-abi \
  --dart-define-from-file=dart_defines.prod.json

# Build iOS IPA
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --tree-shake-icons \
  --dart-define-from-file=dart_defines.prod.json
