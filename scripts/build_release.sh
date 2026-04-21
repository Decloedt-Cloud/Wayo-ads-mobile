#!/usr/bin/env bash
set -euo pipefail

flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define-from-file=dart_defines.prod.json

flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define-from-file=dart_defines.prod.json
