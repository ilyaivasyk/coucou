#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/coucou-codex-hooks.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
python3 - "$TEST_DIR" <<'PY'
from pathlib import Path
import sys
source = Path('NotchBuddy/Sources/App/HookServer.swift').read_text()
out = Path(sys.argv[1])
parts = ['import Foundation']
for index, name in enumerate(['nbHookPythonGitHub', 'nbHookPythonAppStore'], 1):
    start = source.index('private let ' + name + ' = ') + len('private let ' + name + ' = ')
    end = source.index('\n"""', start) + 4
    parts.append('let ' + name + ' = ' + source[start:end])
    parts.append('try ' + name + '.write(toFile: CommandLine.arguments[' + str(index) + '], atomically: true, encoding: .utf8)')
(out / 'Extract.swift').write_text('\n'.join(parts))
PY
swiftc -module-cache-path "$TEST_DIR/module-cache" "$TEST_DIR/Extract.swift" -o "$TEST_DIR/extract"
"$TEST_DIR/extract" "$TEST_DIR/github.py" "$TEST_DIR/appstore.py"
python3 tests/CodexHookRelayTests.py "$TEST_DIR/github.py" "$TEST_DIR/appstore.py"
