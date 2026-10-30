#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build/validation
swiftc -module-cache-path .build/validation/cache Sources/BrosylCore/Models.swift Validation/main.swift -o .build/validation/checks
.build/validation/checks
