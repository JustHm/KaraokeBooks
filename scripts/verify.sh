#!/usr/bin/env bash
#
#  verify.sh
#  KaraokeBooks
#
#  Created by 안정흠 on 2026/08/30.
#

set -euo pipefail

PROJECT="KaraokeBooks.xcodeproj"
SCHEME="KaraokeBooks"
MODE="${1:-all}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17}"

if [[ ! -d "$PROJECT" ]]; then
  echo "error: $PROJECT was not found. Run this script from the repository root." >&2
  exit 1
fi

lint() {
  plutil -lint "$PROJECT/project.pbxproj"
}

build() {
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    build
}

test_app() {
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    test
}

case "$MODE" in
  lint)
    lint
    ;;
  build)
    build
    ;;
  test)
    test_app
    ;;
  all)
    lint
    build
    test_app
    ;;
  *)
    echo "usage: $0 {lint|build|test|all}" >&2
    exit 64
    ;;
esac
