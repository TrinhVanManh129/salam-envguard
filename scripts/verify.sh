#!/usr/bin/env bash
# Build envguard and its test programs, run the tests, then check the
# command-line behaviour against the example files.
set -euo pipefail

cd "$(dirname "$0")/.."
SALAM="${SALAM_BIN:-salam}"
EXT=""
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*) EXT=".exe" ;;
esac
mkdir -p build

# The compiler logs every phase; keep that out of the way unless a build fails.
build() {
  if ! "$SALAM" build "$1" --output="$2" >build/compile.log 2>&1; then
    cat build/compile.log
    echo "FAIL: could not build $1"
    exit 1
  fi
}

echo "== build"
build main.salam "build/envguard$EXT"
for name in lexer envfile compare options json report; do
  build "tests/${name}_test.salam" "build/${name}_test$EXT"
done

echo "== unit tests"
for name in lexer envfile compare options json report; do
  "./build/${name}_test$EXT"
done

echo "== command line"
APP="./build/envguard$EXT"
expect_exit() {
  local want="$1"
  shift
  local got=0
  "$@" >/dev/null 2>&1 || got=$?
  if [ "$got" != "$want" ]; then
    echo "FAIL: expected exit $want, got $got: $*"
    exit 1
  fi
}
expect_exit 0 "$APP" --example examples/clean/.env.example --env examples/clean/.env
expect_exit 1 "$APP" --example examples/drift/.env.example --env examples/drift/.env
expect_exit 1 "$APP" --example examples/clean/.env.example --env examples/drift/.env --strict
expect_exit 2 "$APP" --example examples/clean/.env.example --env examples/does-not-exist
expect_exit 2 "$APP" --example examples --env examples/clean/.env
expect_exit 64 "$APP" --format xml
expect_exit 0 "$APP" --help

# The report must name keys and never echo what they are set to.
if "$APP" --example examples/drift/.env.example --env examples/drift/.env --format json | grep -q "10.0.0.5"; then
  echo "FAIL: a value leaked into the report"
  exit 1
fi

echo "ALL CHECKS PASSED"
