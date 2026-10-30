#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
mkdir -p .build/pdf-validation
cp Validation/pdf-main.swift .build/pdf-validation/main.swift
swiftc -module-cache-path .build/pdf-validation/cache -I "$BIN_DIR" "$BIN_DIR/BrosylCore.build/Models.swift.o" Sources/BrosylApp/QuotePDF.swift .build/pdf-validation/main.swift -o .build/pdf-validation/check
.build/pdf-validation/check "$PWD/.build/pdf-validation/sample.pdf"
